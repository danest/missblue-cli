# Install mb, the Miss Blue command line, on Windows.
#
#   irm https://github.com/danest/missblue-cli/releases/latest/download/install.ps1 | iex
#
# The download is checked against the release's SHA256SUMS before anything is
# installed; a mismatch installs nothing. Installs to
# %LOCALAPPDATA%\Programs\missblue\bin and adds that to your PATH.
#
#   $env:MB_VERSION = 'v0.2.38'     install that release instead of the latest
#   $env:MB_INSTALL_DIR = 'C:\dir'  install there instead
#
# Run it again to update.

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Repo = 'danest/missblue-cli'
$Version = if ($env:MB_VERSION) { $env:MB_VERSION } else { 'latest' }
$Base = if ($env:MB_DOWNLOAD_BASE) { $env:MB_DOWNLOAD_BASE }
        elseif ($Version -eq 'latest') { "https://github.com/$Repo/releases/latest/download" }
        else { "https://github.com/$Repo/releases/download/$Version" }

if (-not [Environment]::Is64BitOperatingSystem) { throw 'mb needs 64-bit Windows.' }
# One build: x86_64. Windows on ARM runs it under emulation.
$Asset = 'mb-x86_64-pc-windows-gnu.zip'

$Tmp = Join-Path ([IO.Path]::GetTempPath()) ('mb-' + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $Tmp | Out-Null
try {
    Write-Host "Downloading mb for Windows"
    $Zip = Join-Path $Tmp $Asset
    $Sums = Join-Path $Tmp 'SHA256SUMS'
    Invoke-WebRequest -UseBasicParsing -Uri "$Base/$Asset" -OutFile $Zip
    Invoke-WebRequest -UseBasicParsing -Uri "$Base/SHA256SUMS" -OutFile $Sums

    $Line = Get-Content $Sums | Where-Object { ($_ -split '\s+')[1] -in @($Asset, "*$Asset") } | Select-Object -First 1
    if (-not $Line) { throw "The release lists no checksum for $Asset; nothing installed." }
    $Expected = ($Line -split '\s+')[0].ToLowerInvariant()
    $Actual = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash.ToLowerInvariant()
    if ($Expected -ne $Actual) { throw "Checksum mismatch for $Asset; nothing installed." }

    Expand-Archive -Path $Zip -DestinationPath $Tmp -Force
    $Binary = Join-Path $Tmp 'mb.exe'
    if (-not (Test-Path $Binary)) { throw 'The archive holds no mb.exe.' }

    $Dir = if ($env:MB_INSTALL_DIR) { $env:MB_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA 'Programs\missblue\bin' }
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    Copy-Item -Path $Binary -Destination (Join-Path $Dir 'mb.exe') -Force

    $UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $Entries = if ($UserPath) { $UserPath -split ';' } else { @() }
    if ($Entries -notcontains $Dir) {
        $NewPath = (@($Entries | Where-Object { $_ }) + $Dir) -join ';'
        [Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
        $env:Path = "$env:Path;$Dir"
        Write-Host "Added $Dir to your PATH. Open a new terminal for other windows to see it."
    }

    $Installed = & (Join-Path $Dir 'mb.exe') --version
    Write-Host "Installed $Installed to $Dir\mb.exe"
    Write-Host ''
    Write-Host 'Next: mb login'
}
finally {
    Remove-Item -Recurse -Force -Path $Tmp -ErrorAction SilentlyContinue
}
