$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$projectRoot = Split-Path $PSScriptRoot -Parent
$upstreamRoot = Join-Path $projectRoot 'upstream'
$expectedCommit = 'ca2decae968f2fd37b43b777cca4ba597808ba52'
$dist = Join-Path $projectRoot 'dist-windows'
Set-Location $upstreamRoot
if ((git rev-parse HEAD) -ne $expectedCommit) { throw 'Unexpected upstream commit' }
git diff --exit-code
git apply --check (Join-Path $projectRoot 'patches/windows-frame-sync.patch')
git apply (Join-Path $projectRoot 'patches/windows-frame-sync.patch')
rustup toolchain install 1.97.1 --profile minimal
choco install zip unzip pkgconfiglite -y --no-progress
$env:RUSTFLAGS = "--remap-path-prefix=$env:USERPROFILE=/builder --remap-path-prefix=$projectRoot=/src"
cargo +1.97.1 xtask prepare-deps --platform windows --ci
cargo +1.97.1 build --locked --release -p alvr_server_openvr
New-Item -ItemType Directory -Path $dist -Force | Out-Null
Copy-Item 'target/release/alvr_server_openvr.dll' (Join-Path $dist 'driver_alvr_server.dll')
Copy-Item (Join-Path $projectRoot 'LICENSE') $dist
Copy-Item 'LICENSE' (Join-Path $dist 'ALVR-LICENSE.txt')
$hash = (Get-FileHash (Join-Path $dist 'driver_alvr_server.dll') -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  driver_alvr_server.dll" | Set-Content (Join-Path $dist 'SHA256SUMS.txt')
@"
Project commit: $env:GITHUB_SHA
ALVR commit: $expectedCommit
Patch: windows-frame-sync.patch only
Build: Windows x64 release, Rust 1.97.1
Experimental driver; headset validation required before merge.
"@ | Set-Content (Join-Path $dist 'BUILD-INFO.txt')
