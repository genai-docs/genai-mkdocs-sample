<#
.SYNOPSIS
    プロジェクト実行環境のコンテナイメージを `latest` タグでビルドする。

.DESCRIPTION
    infra/docker/Dockerfile を使用してプロジェクト実行環境のコンテナイメージを
    常に `latest` タグでビルドする。リビルドにより置き換わって dangling になった
    旧 `latest` イメージは自動で削除する。
    -Push スイッチを指定すると ghcr.io へプッシュも行う。

.PARAMETER Push
    ビルド後に ghcr.io へプッシュする。

.EXAMPLE
    .\Build-Image.ps1
    .\Build-Image.ps1 -Push
#>
param(
    [switch]$Push
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# ---------- 設定読み込み ----------
$settingsPath = Join-Path $repoRoot 'settings.local.json'
if (-not (Test-Path $settingsPath)) {
    Write-Error "設定ファイルが見つかりません: $settingsPath"
}
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

$ghcrImage = $settings.ghcrImage
$ImageTag = 'latest'
$imageRef = "${ghcrImage}:${ImageTag}"

Write-Host ''
Write-Host '========================================='
Write-Host '  ハンズオンイメージビルド'
Write-Host '========================================='
Write-Host "  イメージ : $imageRef"
Write-Host "  プッシュ : $($Push.IsPresent)"
Write-Host '========================================='
Write-Host ''

# ---------- 旧 latest イメージ ID を記録（後始末用） ----------
$previousImageId = (docker images --quiet $imageRef 2>$null | Select-Object -First 1)

# ---------- ビルド ----------
Write-Host "イメージをビルド中 ($imageRef)..."
docker build -t $imageRef -f (Join-Path $repoRoot 'infra/docker/Dockerfile') $repoRoot
if ($LASTEXITCODE -ne 0) { throw "イメージのビルドに失敗しました" }
Write-Host "ビルド完了: $imageRef"

# ---------- 旧イメージの掃除 ----------
$currentImageId = (docker images --quiet $imageRef | Select-Object -First 1)
if ($previousImageId -and $previousImageId -ne $currentImageId) {
    Write-Host "古いイメージを削除します: $previousImageId"
    docker rmi $previousImageId *> $null
}

# ---------- プッシュ（オプション） ----------
if ($Push) {
    Write-Host "イメージをプッシュ中 ($imageRef)..."
    docker push $imageRef
    if ($LASTEXITCODE -ne 0) { throw "イメージのプッシュに失敗しました" }
    Write-Host "プッシュ完了: $imageRef"
}
