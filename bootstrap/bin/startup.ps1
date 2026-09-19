$ErrorActionPreference = "Stop"

$baseUrl = "https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
$toolsUrl = "$baseUrl/tools.conf"

$binDir = "D:\program\bin"
$bin = Join-Path $binDir "bin.exe"

Write-Host "[INFO] Installing binary tools..." -ForegroundColor Cyan

$tools = (Invoke-RestMethod $toolsUrl) -split "`n"

foreach ($line in $tools) {
  $line = $line.Trim()

  if (-not $line -or $line.StartsWith("#")) {
    continue
  }

  $type, $name, $source = $line -split "\|", 3

  if ($type -ne "bin") {
    continue
  }

  $target = Join-Path $binDir "$name.exe"

  if (Test-Path $target) {
    Write-Host "[SKIP] $name already installed." -ForegroundColor DarkGray
    continue
  }

  & $bin install $source $target

  if ($LASTEXITCODE -ne 0) {
    throw "$name installation failed."
  }

  Write-Host "[OK]   $name installed." -ForegroundColor Green
}
