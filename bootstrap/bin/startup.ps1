$ErrorActionPreference = "Stop"

$baseUrl = "https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
$tools = (Invoke-RestMethod "$baseUrl/tools.conf") -split "`n"
$binDir = "D:\program\bin"
$bin = Join-Path $binDir "bin.exe"

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

  if (-not (Test-Path $target)) {
    Write-Host "[INFO] Installing $name..." -ForegroundColor Cyan
    & $bin install $source $target
  }
}
