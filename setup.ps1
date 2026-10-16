<#
One-time setup on a new Windows PC:
  1. checks the NVIDIA GPU and driver,
  2. downloads the prebuilt Windows binaries from this repo's GitHub release into .\bin,
  3. optionally downloads models.

Run from the repo folder:
  powershell -ExecutionPolicy Bypass -File setup.ps1
#>
$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$release = 'https://github.com/Abdelhayali/v100-llm-windows/releases/latest/download/v100-llm-windows-bin.zip'

Write-Host "== 1/3 Checking GPU and driver"
$smi = Get-Command nvidia-smi -EA SilentlyContinue
if (-not $smi) { throw "nvidia-smi not found. Install the NVIDIA data-center driver for your Tesla GPU first (R576 or newer)." }
$gpu = (nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap --format=csv,noheader) -split "`n" | Select-Object -First 1
Write-Host "   $gpu"
$name, $mem, $drv, $cc = ($gpu -split ',') | ForEach-Object { $_.Trim() }
if ([double]$drv -lt 576) { Write-Warning "Driver $drv is older than 576; CUDA 12.9 needs R576 or newer. Update the driver." }
if ($cc -ne '7.0') { Write-Warning "These binaries are tuned for Volta (sm_70, Tesla V100). Your GPU reports compute capability $cc; it may still run via PTX JIT, but speeds will differ." }
if ([int]($mem -replace '[^\d]', '') -lt 15000) { Write-Warning "The run scripts assume 16 GB of VRAM; smaller cards will run out of memory." }

Write-Host "== 2/3 Prebuilt binaries"
if (Test-Path "$root\bin\pxa\llama-server.exe") {
    Write-Host "   already present in bin\ (delete bin\ to re-download)"
} else {
    $zip = Join-Path $env:TEMP 'v100-llm-windows-bin.zip'
    Write-Host "   downloading $release (~0.8 GB) ..."
    & curl.exe -fL --retry 10 --retry-all-errors -C - -o $zip $release
    if ($LASTEXITCODE -ne 0) { throw "Download failed; run setup.ps1 again to resume." }
    Write-Host "   extracting ..."
    $tmp = Join-Path $env:TEMP 'v100-llm-windows-bin'
    if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
    Expand-Archive $zip -DestinationPath $tmp
    Copy-Item -Recurse -Force (Join-Path $tmp 'v100-llm-windows\bin') $root
    Remove-Item -Recurse -Force $tmp; Remove-Item -Force $zip
    Write-Host "   installed to bin\"
}
$env:PATH = "$root\bin\runtime;$env:PATH"
& "$root\bin\pxa\llama-cli.exe" --version 2>&1 | Select-Object -First 1 | ForEach-Object { Write-Host "   PXA build: $_" }

Write-Host "== 3/3 Models"
$ans = Read-Host "Download models now? (y/n)"
if ($ans -match '^[yY]') { & "$root\scripts\download-models.ps1" }

Write-Host "`nSetup complete. Start a model, e.g.:  run\fusion4.cmd   then open http://127.0.0.1:8899"
