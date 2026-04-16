<#
.SYNOPSIS
    ローカルビルド済みのハンズオン環境コンテナイメージを起動する。

.DESCRIPTION
    Build-Image.ps1 でビルドしたイメージをローカル Docker で実行する。
    既定では現在の Git コミットハッシュ（短縮形）のタグを使用し、
    code-server をホストのポートへ公開する。

.PARAMETER ImageTag
    起動するイメージのタグ。省略時は現在の Git コミットハッシュ（短縮形）を使用する。

.PARAMETER Port
    ホスト側に公開するポート番号（既定: 8080）。

.PARAMETER Password
    code-server のログインパスワード（既定: changeme）。

.PARAMETER ContainerName
    起動するコンテナ名（既定: handson-env-local）。

.PARAMETER Detach
    コンテナをバックグラウンド（-d）で起動する。

.EXAMPLE
    .\Run-Image.ps1
    .\Run-Image.ps1 -ImageTag v1.0
    .\Run-Image.ps1 -Port 18080 -Password s3cret
    .\Run-Image.ps1 -Detach
#>
param(
    [string]$ImageTag,

    [int]$Port = 8080,

    [string]$Password = 'changeme',

    [string]$ContainerName = 'handson-env-local',

    [switch]$Detach
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# ---------- 設定読み込み ----------
$settingsPath = Join-Path $repoRoot 'settings.local.json'
if (-not (Test-Path $settingsPath)) {
    Write-Error "設定ファイルが見つかりません: $settingsPath"
}
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

# ---------- ImageTag 解決 ----------
if (-not $ImageTag) {
    $ImageTag = git -C $repoRoot rev-parse --short HEAD
    Write-Host "ImageTag を Git コミットハッシュから自動取得: $ImageTag"
}

$ghcrImage = $settings.ghcrImage
$imageRef = "${ghcrImage}:${ImageTag}"

Write-Host ''
Write-Host '========================================='
Write-Host '  ハンズオンイメージ起動'
Write-Host '========================================='
Write-Host "  イメージ     : $imageRef"
Write-Host "  コンテナ名   : $ContainerName"
Write-Host "  公開ポート   : ${Port} -> 8080"
Write-Host "  バックグラウンド: $($Detach.IsPresent)"
Write-Host '========================================='
Write-Host ''

# ---------- イメージ存在確認 ----------
docker image inspect $imageRef *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "イメージが見つかりません: $imageRef`n`nローカルでビルドするには次を実行してください:`n  pnpm infra:build-image -- -ImageTag $ImageTag"
}

# ---------- 既存コンテナの掃除 ----------
$existing = docker ps -a --filter "name=^/${ContainerName}$" --format '{{.Names}}'
if ($existing) {
    Write-Host "既存コンテナを削除します: $ContainerName"
    docker rm -f $ContainerName *> $null
}

# ---------- 実行 ----------
$runArgs = @(
    'run', '--rm',
    '--name', $ContainerName,
    '-p', "${Port}:8080",
    '-e', "PASSWORD=$Password"
)
if ($Detach) {
    $runArgs += '-d'
}
else {
    $runArgs += '-it'
}
$runArgs += $imageRef

Write-Host "http://localhost:${Port} (password: $Password) でアクセスできます。"
Write-Host ''

docker @runArgs
if ($LASTEXITCODE -ne 0) { throw "コンテナの起動に失敗しました" }

if ($Detach) {
    Write-Host ''
    Write-Host "コンテナをバックグラウンドで起動しました。停止するには:"
    Write-Host "  docker stop $ContainerName"
}
