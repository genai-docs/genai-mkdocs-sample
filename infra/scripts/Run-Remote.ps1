<#
.SYNOPSIS
    GHCR に公開されているハンズオン環境コンテナイメージ（latest）をプルして起動する。

.DESCRIPTION
    settings.local.json の ghcrImage から対象イメージを解決し、
    docker pull で `latest` タグのリモートイメージを取得してから起動する。
    code-server をホストのポートへ公開する。

.PARAMETER Port
    ホスト側に公開するポート番号（既定: 8080）。

.PARAMETER Password
    code-server のログインパスワード（既定: changeme）。

.PARAMETER ContainerName
    起動するコンテナ名（既定: handson-env-remote）。

.PARAMETER Detach
    コンテナをバックグラウンド（-d）で起動する。

.PARAMETER SkipPull
    docker pull を省略する（取得済みイメージでの起動確認用）。

.EXAMPLE
    .\Run-Remote.ps1
    .\Run-Remote.ps1 -Port 18080 -Password s3cret -Detach
#>
param(
    [int]$Port = 8080,

    [string]$Password = 'changeme',

    [string]$ContainerName = 'handson-env-remote',

    [switch]$Detach,

    [switch]$SkipPull
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
$imageRef = "${ghcrImage}:latest"

Write-Host ''
Write-Host '========================================='
Write-Host '  ハンズオンイメージ起動（GHCR）'
Write-Host '========================================='
Write-Host "  イメージ     : $imageRef"
Write-Host "  コンテナ名   : $ContainerName"
Write-Host "  公開ポート   : ${Port} -> 8080"
Write-Host "  バックグラウンド: $($Detach.IsPresent)"
Write-Host "  Pull 省略    : $($SkipPull.IsPresent)"
Write-Host '========================================='
Write-Host ''

# ---------- イメージ取得 ----------
if (-not $SkipPull) {
    Write-Host "GHCR からイメージを取得中: $imageRef"
    docker pull $imageRef
    if ($LASTEXITCODE -ne 0) {
        throw "イメージの pull に失敗しました: $imageRef`n非公開パッケージの場合は 'docker login ghcr.io' を実施してください。"
    }
}
else {
    docker image inspect $imageRef *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "イメージが見つかりません: $imageRef`n-SkipPull を外して再実行してください。"
    }
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
