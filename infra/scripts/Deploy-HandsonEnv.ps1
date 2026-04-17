<#
.SYNOPSIS
    ハンズオン環境を Azure 上にデプロイする。

.DESCRIPTION
    settings.local.json の設定をもとに、以下を実行する。
    1. 共有インフラのデプロイ（Log Analytics, Container Apps Environment）
    2. 参加者ごとの Container App デプロイ
    3. 参加者情報（URL・パスワード）の出力

    コンテナイメージは GHCR に公開済みの `ghcr.io/<owner>/handson-env:<version>`
    を pull する前提である。イメージの公開は CI (publish-handson-image.yml) が
    Release-v<semver> タグの push を契機に実行するため、本スクリプトではビルド
    しない。ローカルでイメージを差し替えたい場合は先に Build-Image.ps1 -Push
    などでプッシュしておくこと。

.PARAMETER UserCount
    参加者数。この数だけ Container App をデプロイする。

.PARAMETER ImageTag
    コンテナイメージのタグ。省略時は最新の Release-v<semver> タグから抽出した
    バージョン（例: 1.1.1）を使用する。既存タグが無い場合はエラーとなるため、
    明示的に -ImageTag を指定するか事前に pnpm infra:release-tag でタグを発行
    すること。

.EXAMPLE
    .\Deploy-HandsonEnv.ps1 -UserCount 20
    .\Deploy-HandsonEnv.ps1 -UserCount 5 -ImageTag 1.1.1
    .\Deploy-HandsonEnv.ps1 -UserCount 5 -ImageTag latest
#>
param(
    [Parameter(Mandatory)]
    [ValidateRange(1, 50)]
    [int]$UserCount,

    [string]$ImageTag
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outDir = Join-Path $repoRoot 'handson-out'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
Start-Transcript -Path (Join-Path $outDir "deploy-$timestamp.log")

$settingsPath = Join-Path $repoRoot 'settings.local.json'

try {

# ---------- 設定読み込み ----------
if (-not (Test-Path $settingsPath)) {
    Write-Error "設定ファイルが見つかりません: $settingsPath"
}
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# リソースグループ名: settings の値をプレフィックスとしタイムスタンプを付与
$rgName = "$($settings.resourceGroup)-$timestamp"

# ImageTag 省略時は最新の Release-v* タグからバージョンを抽出
if (-not $ImageTag) {
    $latestVersion = git -C $repoRoot tag --list 'Release-v*' |
        ForEach-Object {
            if ($_ -match '^Release-v(\d+)\.(\d+)\.(\d+)$') {
                [PSCustomObject]@{
                    Tag     = $_
                    Version = '{0}.{1}.{2}' -f $matches[1], $matches[2], $matches[3]
                    Major   = [int]$matches[1]
                    Minor   = [int]$matches[2]
                    Patch   = [int]$matches[3]
                }
            }
        } |
        Sort-Object Major, Minor, Patch |
        Select-Object -Last 1

    if (-not $latestVersion) {
        throw "Release-v* タグが見つかりません。-ImageTag を明示指定するか、先に pnpm infra:release-tag でタグを発行してください。"
    }

    $ImageTag = $latestVersion.Version
    Write-Host "ImageTag を最新 Release タグから自動取得: $ImageTag (元タグ: $($latestVersion.Tag))"
}

$ghcrImage = $settings.ghcrImage
$imageRef = "${ghcrImage}:${ImageTag}"

Write-Host ''
Write-Host '========================================='
Write-Host '  ハンズオン環境デプロイ'
Write-Host '========================================='
Write-Host "  サブスクリプション : $($settings.subscriptionId)"
Write-Host "  リソースグループ   : $rgName"
Write-Host "  リージョン         : $($settings.location)"
Write-Host "  参加者数           : $UserCount"
Write-Host "  イメージ           : $imageRef"
Write-Host '========================================='
Write-Host ''

# ---------- サブスクリプション設定 ----------
Write-Host '[1/4] サブスクリプションを設定中...'
az account set --subscription $settings.subscriptionId
if ($LASTEXITCODE -ne 0) { throw "サブスクリプションの設定に失敗しました" }

# ---------- リソースグループ作成 ----------
Write-Host '[2/4] リソースグループを作成中...'
az group create `
    --name $rgName `
    --location $settings.location `
    --output none
if ($LASTEXITCODE -ne 0) { throw "リソースグループの作成に失敗しました" }

# ---------- 共有インフラデプロイ ----------
Write-Host '[3/4] 共有インフラをデプロイ中（Log Analytics, Container Apps Environment）...'
$infraJson = az deployment group create `
    --resource-group $rgName `
    --template-file (Join-Path $repoRoot 'infra/azure/main.bicep') `
    --parameters "location=$($settings.location)" `
    --output json 2>$null
if ($LASTEXITCODE -ne 0) { throw "共有インフラのデプロイに失敗しました" }
$infraOutputs = ($infraJson | ConvertFrom-Json).properties.outputs

$environmentId = $infraOutputs.environmentId.value

Write-Host "  Environment: $environmentId"

# ---------- 参加者ごとの Container App デプロイ ----------
Write-Host "[4/4] Container App を $UserCount 台デプロイ中..."

$credentials = @()
for ($i = 1; $i -le $UserCount; $i++) {
    $userName = 'user-{0:D2}' -f $i
    $password = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 12 | ForEach-Object { [char]$_ })

    Write-Host "  デプロイ中: handson-$userName ($i/$UserCount)"

    $deployParams = @(
        "location=$($settings.location)"
        "environmentId=$environmentId"
        "imageRef=$imageRef"
        "userName=$userName"
        "password=$password"
    )
    $appJson = az deployment group create `
        --resource-group $rgName `
        --template-file (Join-Path $repoRoot 'infra/azure/container-app.bicep') `
        --parameters $deployParams `
        --output json 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Container App '$userName' のデプロイに失敗しました" }
    $appOutputs = ($appJson | ConvertFrom-Json).properties.outputs

    $credentials += [PSCustomObject]@{
        User     = $userName
        URL      = "https://$($appOutputs.fqdn.value)"
        Password = $password
    }
}

# ---------- 結果出力 ----------
Write-Host ''
Write-Host '========================================='
Write-Host '  デプロイ完了 - 参加者情報'
Write-Host '========================================='
$credentials | Format-Table -AutoSize

$credentialsPath = Join-Path $outDir "credentials-$timestamp.json"
$credentials | ConvertTo-Json -Depth 2 | Out-File -FilePath $credentialsPath -Encoding utf8
Write-Host "参加者情報を出力しました: $credentialsPath"

} finally {
    Stop-Transcript
}
