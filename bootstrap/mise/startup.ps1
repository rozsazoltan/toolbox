$ErrorActionPreference = "Stop"

$baseUrl = "https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
$toolsUrl = "$baseUrl/tools.conf"

Write-Host "[INFO] Configuring mise..." -ForegroundColor Cyan

$tools = (Invoke-RestMethod $toolsUrl) -split "`n"

foreach ($line in $tools) {
  $line = $line.Trim()

  if (-not $line -or $line.StartsWith("#")) {
    continue
  }

  $type, $name, $source = $line -split "\|", 3

  if ($type -ne "mise-plugin") {
    continue
  }

  $plugins = & mise plugins ls

  if ($plugins -match "(?m)^$([regex]::Escape($name))\s") {
    Write-Host "[SKIP] mise plugin $name already installed." -ForegroundColor DarkGray
    continue
  }

  # https://github.com/verzly/mise-php#get-started
  & mise plugin install $name $source

  if ($LASTEXITCODE -ne 0) {
    throw "mise plugin $name installation failed."
  }

  Write-Host "[OK]   mise plugin $name installed." -ForegroundColor Green
}

# Windows uses mise-php's default windows.php.net binary installer.
# https://github.com/verzly/mise-php#prebuilt-static-php

foreach ($line in $tools) {
  $line = $line.Trim()

  if (-not $line -or $line.StartsWith("#")) {
    continue
  }

  $type, $name, $version = $line -split "\|", 3

  if ($type -ne "mise") {
    continue
  }

  $tool = "$name@$version"

  Write-Host "[INFO] Installing $tool..." -ForegroundColor Cyan

  & mise use --global $tool

  if ($LASTEXITCODE -ne 0) {
    throw "$tool installation failed."
  }

  Write-Host "[OK]   $tool installed." -ForegroundColor Green
}

Write-Host ""
Write-Host "[OK] mise tools ready." -ForegroundColor Green
