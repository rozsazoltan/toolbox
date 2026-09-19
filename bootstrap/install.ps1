$ErrorActionPreference = "Stop"

$binDir = "D:\program\bin"
$miseDir = "D:\program\mise"
$bin = "$binDir\bin.exe"
$mise = "$binDir\mise.exe"

Write-Host "[INFO] Preparing bootstrap..." -ForegroundColor Cyan

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

  Write-Host "[OK] bin directory added to PATH." -ForegroundColor Green
}

if (($env:Path -split ";") -notcontains $binDir) {
  $env:Path = "$binDir;$env:Path"
}

if (-not (Test-Path $bin)) {
  $arch = switch (
    [Runtime.InteropServices.RuntimeInformation]::OSArchitecture
  ) {
    "X64" {
      "x86_64"
    }

    "Arm64" {
      "arm64"
    }

    default {
      throw "Unsupported architecture: $_"
    }
  }

  $release = Invoke-RestMethod `
    "https://api.github.com/repos/marcosnils/bin/releases/latest"

  $asset = $release.assets |
    Where-Object {
      $_.name -match "(?i)windows" -and
      $_.name -match "(?i)$arch"
    } |
    Select-Object -First 1

  if (-not $asset) {
    throw "Unable to find compatible bin release."
  }

  $tmp = Join-Path $env:TEMP "toolbox-bin.exe"

  try {
    Invoke-WebRequest $asset.browser_download_url -OutFile $tmp
    & $tmp install github.com/marcosnils/bin $bin
  }
  finally {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  }

  Write-Host "[OK] bin installed." -ForegroundColor Green
}

if (-not (Test-Path $mise)) {
  & $bin install github.com/jdx/mise $mise

  Write-Host "[OK] mise installed." -ForegroundColor Green
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

  Write-Host "[OK] mise activation added to PowerShell profile." -ForegroundColor Green
}

Write-Host ""

& $bin --version
& $mise --version

Write-Host ""
Write-Host "[OK] Bootstrap complete." -ForegroundColor Green
Write-Host "[INFO] Open new PowerShell to load environment." -ForegroundColor Cyan

$baseUrl = "https://raw.githubusercontent.com/rozsazoltan/toolbox/master/bootstrap"

Invoke-Expression (Invoke-RestMethod "$baseUrl/bin/startup.ps1")
Invoke-Expression (Invoke-RestMethod "$baseUrl/mise/startup.ps1")
