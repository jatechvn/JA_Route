param(
  [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent),
  [string]$ReleaseDirectory = '',
  [string]$OutputDirectory = ''
)
$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
if (!$ReleaseDirectory) { $ReleaseDirectory = Join-Path $ProjectRoot 'build/windows/x64/runner/Release' }
if (!$OutputDirectory) { $OutputDirectory = Join-Path $ProjectRoot ('dist/package-' + [guid]::NewGuid().ToString('N')) }
$versionLine = Select-String -LiteralPath (Join-Path $ProjectRoot 'pubspec.yaml') -Pattern '^version:\s*(\d+\.\d+\.\d+)'
if (!$versionLine) { throw 'Missing package version' }
$version = $versionLine.Matches[0].Groups[1].Value
if (Test-Path -LiteralPath $OutputDirectory) { throw 'Output must be a new directory; existing packages are preserved.' }
$packageName = "JA_Route_v${version}_Windows_x64"
$payload = Join-Path $OutputDirectory $packageName
New-Item -ItemType Directory -Path $payload -Force | Out-Null
foreach ($required in @('ja_route.exe', 'flutter_windows.dll', 'data')) {
  if (!(Test-Path -LiteralPath (Join-Path $ReleaseDirectory $required))) { throw "Missing runtime: $required" }
}
Copy-Item -LiteralPath (Join-Path $ReleaseDirectory 'ja_route.exe') -Destination $payload
Get-ChildItem -LiteralPath $ReleaseDirectory -Filter '*.dll' -File | Copy-Item -Destination $payload
$dataOutput = Join-Path $payload 'data'
New-Item -ItemType Directory -Path $dataOutput | Out-Null
foreach ($name in @('icudtl.dat', 'app.so', 'flutter_assets')) {
  $source = Join-Path $ReleaseDirectory "data/$name"
  if (!(Test-Path -LiteralPath $source)) { throw "Missing Flutter data: $name" }
  Copy-Item -LiteralPath $source -Destination $dataOutput -Recurse
}
foreach ($name in @('i18n','ABOUT.txt','README.md','CHANGELOG.md','USERGUIDE.md','RELEASE_NOTES.md','LICENSE','install.bat','uninstall.bat','uninstall.ps1','debug.bat')) {
  $source = Join-Path $ProjectRoot $name
  if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination $payload -Recurse }
}
$zipName = "$packageName.zip"
Compress-Archive -LiteralPath $payload -DestinationPath (Join-Path $OutputDirectory $zipName)
$hash = (Get-FileHash -LiteralPath (Join-Path $OutputDirectory $zipName) -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath (Join-Path $OutputDirectory 'SHA256SUMS.txt') -Value "$hash  $zipName" -Encoding ASCII
Write-Output "Package: $OutputDirectory"

