$ErrorActionPreference = "Stop"

$baseUrl = "https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
$tools = (Invoke-RestMethod "$baseUrl/tools.conf") -split "`n"

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

  if ($plugins -notmatch "(?m)^$([regex]::Escape($name))\s") {
    # https://github.com/verzly/mise-php#get-started
    & mise plugin install $name $source
  }
}

# https://github.com/verzly/mise-php#prebuilt-static-php
# Windows uses mise-php default binary installation.

foreach ($line in $tools) {
  $line = $line.Trim()

  if (-not $line -or $line.StartsWith("#")) {
    continue
  }

  $type, $name, $version = $line -split "\|", 3

  if ($type -eq "mise") {
    & mise use --global "$name@$version"
  }
}

# https://mise.jdx.dev/dev-tools/backends/npm/#choosing-an-installer
& mise settings set npm.package_manager=pnpm

if ($LASTEXITCODE -ne 0) {
  throw "Unable to configure pnpm as mise npm package manager."
}
