<#
.SYNOPSIS
    ハンズオン環境リリース用の Release-v<semver> タグを作成してプッシュする。

.DESCRIPTION
    既存の Release-v* タグのうち最新のものを探し、パッチバージョンを +1 した
    新しいタグを作成する。-Version を指定した場合はそのバージョンを使用する。
    作成したタグはデフォルトで origin へプッシュする（-SkipPush で抑制可能）。

    このタグの push を契機に .github/workflows/publish-handson-image.yml が
    起動し、GHCR へイメージが公開される。

.PARAMETER Version
    明示的に指定するバージョン (例: 1.2.0)。省略時は最新タグのパッチを +1 する。
    既存タグが無い場合は 0.1.0 を初期値とする。

.PARAMETER SkipPush
    作成したタグをリモートにプッシュしない（ローカルでの検証用）。

.EXAMPLE
    .\New-ReleaseTag.ps1
    # 例: 最新が Release-v1.1.3 → 新規に Release-v1.1.4 を作成して push

.EXAMPLE
    .\New-ReleaseTag.ps1 -Version 1.2.0
    # Release-v1.2.0 を作成して push

.EXAMPLE
    .\New-ReleaseTag.ps1 -SkipPush
    # タグ作成のみ（push はしない）
#>
param(
    [string]$Version,

    [switch]$SkipPush
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# ---------- 事前チェック ----------
$currentBranch = (git -C $repoRoot rev-parse --abbrev-ref HEAD).Trim()
if ($currentBranch -ne 'main') {
    throw "main ブランチで実行してください（現在: $currentBranch）"
}

$dirty = git -C $repoRoot status --porcelain
if ($dirty) {
    throw "作業ツリーがクリーンではありません。コミットまたは stash してから再実行してください。"
}

# リモートの最新タグを取得して既存タグ確認の取りこぼしを防ぐ
git -C $repoRoot fetch --tags --quiet
if ($LASTEXITCODE -ne 0) { throw "git fetch に失敗しました" }

# ---------- バージョン決定 ----------
if (-not $Version) {
    $rawTags = git -C $repoRoot tag --list 'Release-v*'
    $parsed = @()
    foreach ($tag in $rawTags) {
        if ($tag -match '^Release-v(\d+)\.(\d+)\.(\d+)$') {
            $parsed += [PSCustomObject]@{
                Tag   = $tag
                Major = [int]$matches[1]
                Minor = [int]$matches[2]
                Patch = [int]$matches[3]
            }
        }
    }

    if (-not $parsed) {
        $Version = '0.1.0'
        Write-Host "既存の Release-v* タグが見つからなかったため、初期バージョン $Version を使用します。"
    } else {
        $latest = $parsed | Sort-Object Major, Minor, Patch | Select-Object -Last 1
        $Version = '{0}.{1}.{2}' -f $latest.Major, $latest.Minor, ($latest.Patch + 1)
        Write-Host "最新タグ $($latest.Tag) → 新バージョン $Version (パッチを +1)"
    }
} else {
    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        throw "Version は 'major.minor.patch' 形式で指定してください (受領: $Version)"
    }
}

$tagName = "Release-v$Version"

# 同名タグの存在チェック（ローカル / リモート）
if (git -C $repoRoot tag --list $tagName) {
    throw "タグ $tagName はローカルにすでに存在します。"
}
$remoteRef = git -C $repoRoot ls-remote --tags origin "refs/tags/$tagName"
if ($remoteRef) {
    throw "タグ $tagName は origin にすでに存在します。"
}

# ---------- 実行 ----------
Write-Host ''
Write-Host '========================================='
Write-Host '  Release タグ発行'
Write-Host '========================================='
Write-Host "  タグ    : $tagName"
Write-Host "  ブランチ: $currentBranch"
Write-Host "  プッシュ: $(-not $SkipPush.IsPresent)"
Write-Host '========================================='
Write-Host ''

git -C $repoRoot tag -a $tagName -m "Release $Version"
if ($LASTEXITCODE -ne 0) { throw "タグの作成に失敗しました" }
Write-Host "タグを作成しました: $tagName"

if ($SkipPush) {
    Write-Host "(-SkipPush 指定のため push はスキップしました)"
    return
}

git -C $repoRoot push origin $tagName
if ($LASTEXITCODE -ne 0) { throw "タグのプッシュに失敗しました" }
Write-Host "タグを origin へプッシュしました: $tagName"
Write-Host "GitHub Actions の 'Publish Handson Image' ワークフローが起動します。"
