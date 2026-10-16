<#
Downloads model files from Hugging Face into .\models and verifies each one against the
SHA-256 that Hugging Face publishes for it. Re-running resumes partial downloads.

Usage (from the repo folder):
  powershell -ExecutionPolicy Bypass -File scripts\download-models.ps1            # interactive menu
  powershell -ExecutionPolicy Bypass -File scripts\download-models.ps1 fusion4 hauhau
#>
param([string[]] $Names)

$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
$models = Join-Path $root 'models'
New-Item -ItemType Directory -Force $models | Out-Null

# name -> files (repo, file). Sizes are approximate.
$catalog = [ordered]@{
    'fusion4' = @{ desc = 'PXA-Fusion4-35B-A3B PXQ2 (PXA engine, MoE, fastest ~65-75 t/s) - 11.2 GB + 0.9 GB vision'
                   files = @(@('poisonxa/PXA-Fusion4-35B-GGUF', 'PXA-Fusion4-35B-PXQ2.gguf'),
                             @('poisonxa/PXA-bench-files-GGUF', 'mmproj-fusion2-f16.gguf')) }
    'ornith'  = @{ desc = 'Ornith-1.5-35B-A3B PXQ2 (PXA engine, MoE, ~60 t/s) - 11.2 GB + 0.9 GB vision'
                   files = @(@('mistrjirka/Ornith-1.5-35B-A3B-PXQ-GGUF', 'Ornith-1.5-35B-A3B-PXQ2-GGUF.gguf'),
                             @('ornith-ai/Ornith-1.5-35B-A3B-GGUF', 'mmproj-Ornith-1.5-35B-BF16.gguf')) }
    'qwen27b' = @{ desc = 'Qwen3.8-27B PXQ3 (PXA engine, dense, ~27 t/s) - 12.4 GB + 0.6 GB vision'
                   files = @(@('mistrjirka/Qwen3.8-27B-PXQ-GGUF', 'Qwen3.8-27B-PXQ3-GGUF.gguf'),
                             @('ggml-org/Qwen3.8-27B-GGUF', 'mmproj-Qwen3.8-27B-Q8_0.gguf')) }
    'hauhau'  = @{ desc = 'Qwen3.8-27B HauhauCS Aggressive IQ3_XS + FastMTP (FastMTP engine, ~40-53 t/s, 120k ctx mode) - 12.2 GB + 0.9 GB + 0.6 GB vision'
                   files = @(@('HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF', 'Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-IQ3_XS.gguf'),
                             @('HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF', 'Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-FastMTP-32K.gguf'),
                             @('ggml-org/Qwen3.8-27B-GGUF', 'mmproj-Qwen3.8-27B-Q8_0.gguf')) }
}

if (-not $Names) {
    Write-Host "Models (download only what you need; each needs a free 16 GB V100 to run):`n"
    $i = 1; $keys = @($catalog.Keys)
    foreach ($k in $keys) { Write-Host ("  {0}. {1,-8} {2}" -f $i, $k, $catalog[$k].desc); $i++ }
    $sel = Read-Host "`nType numbers or names separated by spaces (e.g. '1 4' or 'all')"
    if ($sel -eq 'all') { $Names = $keys }
    else { $Names = $sel -split '[ ,]+' | Where-Object { $_ } | ForEach-Object { if ($_ -match '^\d+$') { $keys[[int]$_ - 1] } else { $_ } } }
}

function Get-HfSha([string] $repo, [string] $file) {
    $tree = Invoke-RestMethod "https://huggingface.co/api/models/$repo/tree/main" -TimeoutSec 60
    ($tree | Where-Object { $_.path -eq $file }).lfs.oid
}

foreach ($n in $Names) {
    if (-not $catalog.Contains($n)) { Write-Warning "Unknown model '$n' (choose from: $($catalog.Keys -join ', '))"; continue }
    foreach ($f in $catalog[$n].files) {
        $repo, $file = $f
        $dest = Join-Path $models $file
        $expected = Get-HfSha $repo $file
        if ((Test-Path $dest) -and (Get-FileHash $dest -Algorithm SHA256).Hash -eq $expected) { Write-Host "OK (already downloaded): $file"; continue }
        Write-Host "Downloading $file from $repo ..."
        & curl.exe -fL --retry 20 --retry-all-errors -C - -o $dest "https://huggingface.co/$repo/resolve/main/$file"
        if ($LASTEXITCODE -ne 0) { throw "Download failed for $file (run the script again to resume)" }
        Write-Host "Verifying checksum ..."
        $got = (Get-FileHash $dest -Algorithm SHA256).Hash
        if ($got -ne $expected) { throw "Checksum mismatch for $file - delete it and run again" }
        Write-Host "OK: $file"
    }
}
Write-Host "`nDone. Start a model with one of the scripts in the run\ folder."
