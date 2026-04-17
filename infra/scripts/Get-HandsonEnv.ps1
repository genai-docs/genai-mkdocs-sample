<#
.SYNOPSIS
    ハンズオン環境のリソースグループ一覧と状態を表示する。

.DESCRIPTION
    settings.local.json の resourceGroup をプレフィックスとして前方一致で
    リソースグループを検索し、プロビジョニング状態を表示する。
    Deleting 状態のリソースグループも含めて表示するため、削除中かどうかを
    確認できる。
    -All を指定すると、サブスクリプション上の全リソースグループを表示する。

.PARAMETER All
    プレフィックス絞り込みを行わず、サブスクリプション上の全リソースグループを表示する。

.EXAMPLE
    .\Get-HandsonEnv.ps1
    .\Get-HandsonEnv.ps1 -All
#>
param(
    [switch]$All
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$settingsPath = Join-Path $repoRoot 'settings.local.json'

if (-not (Test-Path $settingsPath)) {
    Write-Error "設定ファイルが見つかりません: $settingsPath"
}
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

az account set --subscription $settings.subscriptionId
if ($LASTEXITCODE -ne 0) { throw "サブスクリプションの設定に失敗しました" }

if ($All) {
    Write-Host 'サブスクリプション上の全リソースグループを取得中...'
    $query = "[].{name:name, location:location, state:properties.provisioningState}"
} else {
    $prefix = $settings.resourceGroup
    Write-Host "プレフィックス '$prefix' でリソースグループを検索中..."
    $query = "[?starts_with(name, '$prefix')].{name:name, location:location, state:properties.provisioningState}"
}

$groupsJson = az group list --query $query --output json 2>$null
if ($LASTEXITCODE -ne 0) { throw "リソースグループの取得に失敗しました" }
$groups = $groupsJson | ConvertFrom-Json

if (-not $groups -or $groups.Count -eq 0) {
    Write-Host '該当するリソースグループがありません。'
    return
}

Write-Host "該当: $($groups.Count) 件"
Write-Host ''
$groups | Sort-Object name | Format-Table -AutoSize @(
    @{ Label = 'Name';     Expression = { $_.name } }
    @{ Label = 'Location'; Expression = { $_.location } }
    @{ Label = 'State';    Expression = { $_.state } }
)
