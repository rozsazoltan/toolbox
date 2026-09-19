$ErrorActionPreference = "Stop"

$baseUrl = "https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"
$binDir = "D:\program\bin"
$miseDir = "D:\program\mise"
$bin = Join-Path $binDir "bin.exe"
$mise = Join-Path $binDir "mise.exe"

New-Item -ItemType Directory -Force $binDir, $miseDir | Out-Null

[Environment]::SetEnvironmentVariable(
  "MISE_DATA_DIR",
  $miseDir,
  "User"
)

$env:MISE_DATA_DIR = $miseDir

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$paths = @($userPath -split ";" | Where-Object { $_ })

if ($paths -notcontains $binDir) {
  $newPath = (@($userPath, $binDir) | Where-Object { $_ }) -join ";"

  [Environment]::SetEnvironmentVariable(
    "Path",
    $newPath,
    "User"
  )
}

if (($env:Path -split ";") -notcontains $binDir) {
  $env:Path = "$binDir;$env:Path"
}

if (-not (Test-Path $bin)) {
  Write-Host "[INFO] Installing bin..." -ForegroundColor Cyan

  $release = Invoke-RestMethod `
    "https://api.github.com/repos/marcosnils/bin/releases/latest"

  $asset = $release.assets |
    Where-Object {
      $_.name -match "(?i)windows" -and
      $_.name -match "(?i)(amd64|x86_64|x64)"
    } |
    Select-Object -First 1

  if (-not $asset) {
    throw "Unable to find compatible bin release."
  }

  $tmp = Join-Path $env:TEMP "toolbox-bin-bootstrap.exe"

  try {
    Invoke-WebRequest $asset.browser_download_url -OutFile $tmp
    & $tmp install github.com/marcosnils/bin $bin
  }
  finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  }
}

if (-not (Test-Path $mise)) {
  Write-Host "[INFO] Installing mise..." -ForegroundColor Cyan
  & $bin install github.com/jdx/mise $mise
}

$profile = $PROFILE.CurrentUserAllHosts

New-Item `
  -ItemType Directory `
  -Force `
  (Split-Path $profile) |
  Out-Null

if (-not (Test-Path $profile)) {
  New-Item -ItemType File $profile | Out-Null
}

$activation = "(& '$mise' activate pwsh) | Out-String | Invoke-Expression"

if (-not (Select-String $profile -SimpleMatch $activation -Quiet)) {
  Add-Content $profile "`n# mise`n$activation"
}

Invoke-Expression (Invoke-RestMethod "$baseUrl/bin/startup.ps1")
Invoke-Expression (Invoke-RestMethod "$baseUrl/mise/startup.ps1")

Write-Host "[INFO] Installing Toolbox CLI..." -ForegroundColor Cyan

& $mise exec -- npm install -g `
  "github:rozsazoltan/toolbox#master"

if ($LASTEXITCODE -ne 0) {
  throw "Toolbox CLI installation failed."
}

Write-Host "[OK] Bootstrap complete." -ForegroundColor Green
Write-Host "[INFO] Open a new PowerShell to load environment." -ForegroundColor Cyan
