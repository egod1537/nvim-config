[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [ValidateSet("Junction", "Copy")]
  [string]$Mode = "Junction",

  [string]$Destination,

  [switch]$SkipPluginSync
)

$ErrorActionPreference = "Stop"

if ($env:OS -ne "Windows_NT") {
  throw "이 설치 스크립트는 Windows 전용입니다."
}

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
if (-not $Destination) {
  $Destination = Join-Path $env:LOCALAPPDATA "nvim"
}
$destinationPath = [System.IO.Path]::GetFullPath($Destination)

if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "init.lua"))) {
  throw "저장소 루트에서 init.lua를 찾지 못했습니다: $repoRoot"
}

$separator = [System.IO.Path]::DirectorySeparatorChar
$repoPrefix = $repoRoot.TrimEnd($separator) + $separator
$destinationPrefix = $destinationPath.TrimEnd($separator) + $separator

if ($destinationPath -ne $repoRoot -and (
    $destinationPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
    $repoRoot.StartsWith($destinationPrefix, [System.StringComparison]::OrdinalIgnoreCase)
  )) {
  throw "저장소와 설치 경로는 서로의 하위 디렉터리일 수 없습니다."
}

$backupPath = $null
$installed = $false
$alreadyLinked = $false

if (Test-Path -LiteralPath $destinationPath) {
  $destinationItem = Get-Item -LiteralPath $destinationPath -Force
  if ($destinationItem.LinkType -in @("Junction", "SymbolicLink")) {
    $linkTarget = [string]$destinationItem.Target
    if (-not [System.IO.Path]::IsPathRooted($linkTarget)) {
      $linkTarget = Join-Path (Split-Path -Parent $destinationPath) $linkTarget
    }
    $alreadyLinked = [System.IO.Path]::GetFullPath($linkTarget) -eq $repoRoot
  }
}

if ($destinationPath -eq $repoRoot -or $alreadyLinked) {
  Write-Host "저장소가 이미 Neovim 설정 경로에 있습니다: $destinationPath"
  $installed = $true
} elseif ($PSCmdlet.ShouldProcess($destinationPath, "$Mode 방식으로 Neovim 설정 설치")) {
  if (Test-Path -LiteralPath $destinationPath) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$destinationPath.backup-$timestamp"
    $suffix = 1
    while (Test-Path -LiteralPath $backupPath) {
      $backupPath = "$destinationPath.backup-$timestamp-$suffix"
      $suffix++
    }

    Move-Item -LiteralPath $destinationPath -Destination $backupPath
    Write-Host "기존 설정 백업: $backupPath"
  }

  $destinationParent = Split-Path -Parent $destinationPath
  if (-not (Test-Path -LiteralPath $destinationParent)) {
    New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
  }

  try {
    if ($Mode -eq "Junction") {
      New-Item -ItemType Junction -Path $destinationPath -Target $repoRoot | Out-Null
    } else {
      New-Item -ItemType Directory -Path $destinationPath | Out-Null
      Get-ChildItem -LiteralPath $repoRoot -Force |
        Where-Object { $_.Name -ne ".git" } |
        Copy-Item -Destination $destinationPath -Recurse -Force
    }
    $installed = $true
  } catch {
    if (Test-Path -LiteralPath $destinationPath) {
      if ($Mode -eq "Junction") {
        Remove-Item -LiteralPath $destinationPath -Force
      } else {
        Remove-Item -LiteralPath $destinationPath -Force -Recurse
      }
    }
    if ($backupPath -and (Test-Path -LiteralPath $backupPath)) {
      Move-Item -LiteralPath $backupPath -Destination $destinationPath
      Write-Warning "설치에 실패하여 기존 설정을 복구했습니다."
    }
    throw
  }

  Write-Host "Neovim 설정 설치 완료: $destinationPath"
}

if (-not $installed -or $SkipPluginSync) {
  exit 0
}

$nvim = Get-Command nvim -ErrorAction SilentlyContinue
if (-not $nvim) {
  Write-Warning "nvim 명령을 찾지 못해 플러그인 설치를 건너뜁니다. Neovim 설치 후 :Lazy sync를 실행하세요."
  exit 0
}

Write-Host "플러그인을 동기화합니다..."
& $nvim.Source --headless "+Lazy! sync" "+qa"
if ($LASTEXITCODE -ne 0) {
  throw "플러그인 동기화에 실패했습니다. Neovim에서 :Lazy sync를 다시 실행하세요."
}

Write-Host "적용이 끝났습니다. nvim을 실행한 뒤 :checkhealth로 상태를 확인하세요."
