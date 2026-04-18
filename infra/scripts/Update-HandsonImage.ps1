<#
.SYNOPSIS
    既存ハンズオン環境の Container App を ghcr の :latest イメージで更新する。

.DESCRIPTION
    settings.local.json の resourceGroup をプレフィックスとして前方一致で
    リソースグループを検索し、該当 RG 内の全 Container App に対して
    ghcr.io/<owner>/handson-env:latest を再デプロイする。Log Analytics /
    Container Apps Environment / Container App 自体は削除せず、新しい
    リビジョンを発行して :latest を pull しなおすだけである。
    該当 RG が1つならそのまま更新、複数なら選択式で更新する。
    -All を指定すると、該当する全リソースグループをまとめて更新する。

    イメージタグは :latest に固定されている。別タグへ切り替えたい場合は
    Deploy-HandsonEnv.ps1 の再実行を検討すること。

.PARAMETER All
    前方一致する全リソースグループを一括更新する。

.EXAMPLE
    .\Update-HandsonImage.ps1
    .\Update-HandsonImage.ps1 -All
#>
param(
    [switch]$All
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$outDir = Join-Path $repoRoot 'handson-out'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
Start-Transcript -Path (Join-Path $outDir "update-image-$timestamp.log")

$settingsPath = Join-Path $repoRoot 'settings.local.json'

try {

if (-not (Test-Path $settingsPath)) {
    Write-Error "設定ファイルが見つかりません: $settingsPath"
}
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

$imageRef = "$($settings.ghcrImage):latest"

az account set --subscription $settings.subscriptionId
if ($LASTEXITCODE -ne 0) { throw "サブスクリプションの設定に失敗しました" }

# ---------- 前方一致でリソースグループを検索 ----------
$prefix = $settings.resourceGroup
Write-Host "プレフィックス '$prefix' でリソースグループを検索中..."

$groups = az group list `
    --query "[?starts_with(name, '$prefix')].{name:name, location:location}" `
    --output json 2>$null | ConvertFrom-Json

if ($groups.Count -eq 0) {
    Write-Host '該当するリソースグループがありません。'
    return
}

Write-Host "該当: $($groups.Count) 件"
Write-Host ''

# ---------- 更新対象の決定 ----------
if ($All) {
    $targets = $groups
} elseif ($groups.Count -eq 1) {
    $targets = $groups
} else {
    for ($i = 0; $i -lt $groups.Count; $i++) {
        Write-Host "  [$($i + 1)] $($groups[$i].name)"
    }
    Write-Host ''
    $selection = Read-Host '更新するリソースグループの番号を入力してください'
    $index = [int]$selection - 1
    if ($index -lt 0 -or $index -ge $groups.Count) {
        Write-Error "無効な番号です: $selection"
    }
    $targets = @($groups[$index])
}

# ---------- 各 RG の Container App を :latest で更新 ----------
# 同一タグのまま更新しても revision-suffix を変えれば新規リビジョンが作成され、:latest が再 pull される
$revisionSuffix = "u$timestamp"

foreach ($target in $targets) {
    Write-Host ''
    Write-Host "リソースグループ '$($target.name)' の Container App を更新中..."

    $appsJson = az containerapp list `
        --resource-group $target.name `
        --query "[].name" `
        --output json 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Container App の列挙に失敗しました: $($target.name)" }
    $appNames = $appsJson | ConvertFrom-Json

    if (-not $appNames -or $appNames.Count -eq 0) {
        Write-Host '  Container App が見つかりませんでした。スキップします。'
        continue
    }

    Write-Host "  対象: $($appNames.Count) 台"
    Write-Host "  イメージ: $imageRef"

    foreach ($appName in $appNames) {
        Write-Host "  更新中: $appName"
        az containerapp update `
            --name $appName `
            --resource-group $target.name `
            --image $imageRef `
            --revision-suffix $revisionSuffix `
            --output none
        if ($LASTEXITCODE -ne 0) { throw "Container App '$appName' の更新に失敗しました" }
    }
}

Write-Host ''
Write-Host '更新処理が完了しました。Container App は新しいリビジョンで :latest を pull しています。'

} finally {
    Stop-Transcript
}
