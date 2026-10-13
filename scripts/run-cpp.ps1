[CmdletBinding()]
param(
  [Parameter(Mandatory, Position = 0)]
  [string]$Source,

  [string]$InputPath,

  [string]$OutputPath,

  [string]$Standard = "gnu++20"
)

$ErrorActionPreference = "Stop"

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
if ([IO.Path]::GetExtension($sourcePath) -notin @(".cc", ".cpp", ".cxx")) {
  throw "C++ source file required: $sourcePath"
}

$compilerName = $env:NVIM_CXX
if (-not $compilerName) {
  $compilerName = "g++"
}

$compiler = Get-Command $compilerName -ErrorAction SilentlyContinue
if (-not $compiler) {
  throw "C++ compiler not found: $compilerName. Add g++ to PATH or set NVIM_CXX."
}

$binaryPath = [IO.Path]::ChangeExtension($sourcePath, ".exe")
$compileArgs = @(
  "-std=$Standard",
  "-O2",
  "-Wall",
  "-Wextra",
  $sourcePath,
  "-o",
  $binaryPath
)

Write-Host "Compile: $sourcePath"
& $compiler.Source @compileArgs
if ($LASTEXITCODE -ne 0) {
  throw "Compilation failed with exit code $LASTEXITCODE"
}

$startArgs = @{
  FilePath = $binaryPath
  NoNewWindow = $true
  PassThru = $true
  Wait = $true
}

$resolvedInput = $null
if ($InputPath) {
  $resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
  $startArgs.RedirectStandardInput = $resolvedInput
}

$resolvedOutput = $null
if ($OutputPath) {
  if ([IO.Path]::IsPathRooted($OutputPath)) {
    $resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
  } else {
    $resolvedOutput = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
  }

  $outputDirectory = Split-Path -Parent $resolvedOutput
  if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    throw "Output directory does not exist: $outputDirectory"
  }
  if ($resolvedInput -and $resolvedInput -eq $resolvedOutput) {
    throw "InputPath and OutputPath must be different files."
  }

  $startArgs.RedirectStandardOutput = $resolvedOutput
}

Write-Host "Run: $binaryPath"
$process = Start-Process @startArgs
if ($process.ExitCode -ne 0) {
  throw "Program exited with code $($process.ExitCode)"
}

if ($resolvedOutput) {
  Write-Host "Output: $resolvedOutput"
}
