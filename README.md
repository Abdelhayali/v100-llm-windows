# v100-llm-windows

Run fast local LLMs **natively on Windows** on an **NVIDIA Tesla V100 16 GB**. You don't need WSL, Docker or Linux.
Everything comes prebuilt, including the CUDA and Visual C++ runtimes. Image input (vision) works on every model.

| Model | Engine | Speed on 1× V100-SXM2-16GB | Context | Script |
|---|---|---|---|---|
| **PXA-Fusion4-35B-A3B** (PXQ2) | PXA | **64–76 tok/s** | 16k | `run\fusion4.cmd` |
| **Ornith-1.5-35B-A3B** (PXQ2) | PXA | ~60 tok/s | 16k | `run\ornith.cmd` |
| **Qwen3.8-27B** (PXQ3) | PXA | ~27 tok/s | 8k | `run\qwen27b-pxq3.cmd` |
| **Qwen3.8-27B HauhauCS Aggressive** (IQ3_XS + FastMTP) | FastMTP | **40–53 tok/s** | 24k | `run\hauhau-fast.cmd` |
| same, 80k mode (FastMTP + images on GPU) | FastMTP | ~46 tok/s short / ~22 tok/s at 77k | **80k** | `run\hauhau-80k.cmd` |
| same, long-context mode (images on CPU) | FastMTP | ~46 tok/s short / ~14 tok/s at 118k | **120k** | `run\hauhau-long.cmd` |

Every server provides a **web chat** at `http://127.0.0.1:8899` and an **OpenAI-compatible API** at `http://127.0.0.1:8899/v1`.

> ⚠️ **Content warning:** Fusion4 is "abliterated" and the HauhauCS model is an "uncensored / aggressive" fine-tune, so both have had their safety tuning removed.
> Ornith and Qwen3.8 PXQ3 are regular fine-tunes and quantizations.

---

## Requirements

- Windows 10 or 11, 64-bit
- An NVIDIA **Tesla V100 16 GB** (SXM2 or PCIe). The binaries are compiled for Volta (`sm_70`). A 32 GB V100 also works and has more headroom.
- An NVIDIA driver from the **R576 series or newer** (needed for CUDA 12.9). A V100 in **TCC mode** is fine, and TCC is the default for this card on Windows.
- An x86-64 CPU with **AVX2** (any Intel or AMD CPU from 2015 or later)
- Disk space: about 1.3 GB for the binaries, plus 10–14 GB for each model
- RAM: 32 GB or more recommended

You **don't** need to install CUDA, Visual Studio or Python.

## Quick start on a new PC

```powershell
git clone https://github.com/Abdelhayali/v100-llm-windows
cd v100-llm-windows
powershell -ExecutionPolicy Bypass -File setup.ps1
```

`setup.ps1` does three things:
1. Checks your GPU and driver.
2. Downloads the prebuilt binaries (`v100-llm-windows-bin.zip` from the [latest release](https://github.com/Abdelhayali/v100-llm-windows/releases/latest)) into `bin\`.
3. Offers to download models, verifying each file's SHA-256 checksum.

No git? Click **Code → Download ZIP** on GitHub, extract it, and run `setup.ps1` from that folder.

Then start a model:

```bat
run\fusion4.cmd
```

When the window shows `server is listening`, open **http://127.0.0.1:8899** in a browser.
Only one model can run at a time, because each one needs the whole 16 GB card. Close the window (or press Ctrl+C) before starting another.

### Download more models later

```powershell
powershell -ExecutionPolicy Bypass -File scripts\download-models.ps1            # menu
powershell -ExecutionPolicy Bypass -File scripts\download-models.ps1 fusion4 hauhau
```

If a download stops partway, run the same command again and it will resume.

### Options (environment variables)

```bat
set PORT=8080
set HOST=0.0.0.0
set MODELS_DIR=E:\llm-models
run\fusion4.cmd
```

- `PORT` changes the port.
- `HOST=0.0.0.0` lets other PCs on your LAN connect. Only do this on a trusted network, because the server has no login.
- `MODELS_DIR` points at models kept on another drive.

Any extra arguments you add after the script name are passed straight to `llama-server`, for example `run\hauhau-fast.cmd --spec-draft-n-max 4`.

## Using the API

```powershell
$body = @{ messages = @(@{ role = 'user'; content = 'Hello!' }); max_tokens = 200 } | ConvertTo-Json -Depth 5
Invoke-RestMethod http://127.0.0.1:8899/v1/chat/completions -Method Post -ContentType 'application/json' -Body $body
```

Any OpenAI-compatible client works. Point it at base URL `http://127.0.0.1:8899/v1`; the API key can be anything.
For images, send OpenAI-style `image_url` content parts; `scripts\vision-test.ps1` shows how.

## Which model should I use?

- **Fastest replies:** `fusion4` or `ornith`. These are 35B mixture-of-experts models that use only about 3B parameters per token.
- **Best quality from a dense 27B model at a good speed:** `hauhau-fast`. This model ships a small "FastMTP" draft model that guesses ahead, and the main model checks the guesses. That makes it about 1.5–1.9× faster than running without one.
- **Long documents together with fast image input (up to 80k tokens):** `hauhau-80k`. It keeps the FastMTP sidecar and the image encoder on the GPU, so an image takes about 3.5 s instead of about 10 s.
- **The longest documents or codebases (up to 120k tokens):** `hauhau-long`. Reading the prompt runs at about 200–470 tok/s, so a 100k-token prompt takes several minutes before the first reply token. Later messages in the same chat reuse the cache.

### Benchmarks (Tesla V100-SXM2-16GB, temperature 0)

| Setup | chat | code | long doc |
|---|---|---|---|
| HauhauCS IQ3_XS, no speculation | 30.5 | 28.1 | 24.7 |
| + built-in MTP, draft depth 2 | 40.2 | 45.8 | 38.9 |
| + **FastMTP sidecar, depth 2** (`hauhau-fast`) | **40.8** | 47.4 | **40.2** |
| + FastMTP sidecar, depth 4 | 36.6 | **53.1** | 40.7 |
| Fusion4 PXQ2 (`fusion4`) | 75.8 | 68.8 | 66.8 |
| Qwen3.8-27B PXQ3 (`qwen27b-pxq3`) | 29.8 | 26.8 | 25.2 |

**120k context test:** a 117,955-token prompt with a secret code hidden in the middle. The model returned the right code.
It took 595 s to read the prompt (198 tok/s) and then generated at 14.5 tok/s. Peak VRAM was 16.1 GB.

**80k context test (`hauhau-80k`):** a 77,299-token prompt, which returned the right code. It took 332 s to read (234 tok/s) and then generated at 22.0 tok/s.
An image sent afterwards was still read correctly on the GPU (4.5 s). Peak VRAM was 16.2 GB.
The same setup at 90k (`-c 92160`) **ran out of memory** after reading an 87k-token prompt, just as generation started, so 80k is the practical limit with this setup.

### Checking speed and vision on your machine

```powershell
powershell -ExecutionPolicy Bypass -File scripts\vision-test.ps1        # image test against the running server
powershell -ExecutionPolicy Bypass -File scripts\longctx-test.ps1 -Paragraphs 300   # ~13k-token needle test
```

## How the 120k context fits in 16 GB

`run\hauhau-long.cmd` uses four settings to fit:
- **4-bit KV cache** (`-ctk q4_0 -ctv q4_0`). The cache is 2.1 GB instead of about 8 GB.
- **Vision encoder on the CPU** (`--no-mmproj-offload`). This adds a few seconds per image.
- **The model's built-in MTP head instead of the FastMTP sidecar.** Benchmarks show a 2–3% speed difference, and it saves 1.1 GB.
- **`-ub 256`.** In testing, `-ub 128` triggered a cuBLAS error in this llama.cpp version, and `-ub 512` ran out of memory on a 118k-token prompt.

`run\hauhau-80k.cmd` keeps the FastMTP sidecar and the image encoder on the GPU. It uses the same 4-bit main-model cache and `-ub 256`, but a smaller context.
Don't add `--spec-draft-type-k/v q4_0` there. Quantizing the sidecar's cache shrinks the cache from 360 MB to 101 MB, but its compute buffer grows from 80 MB to 446 MB, so total memory goes *up*.

---

## What's inside

```
setup.ps1                 first-time setup (GPU check, binaries, models)
run\*.cmd                 one script per model / mode
scripts\                  model downloader, vision and long-context tests
bin\                      (from the release) pxa\, fastmtp\, runtime\ (CUDA 12.9 + MSVC DLLs)
patches\                  source patches the binaries were built from
build\                    scripts to rebuild everything from source
LICENSES\                 upstream licences
```

The release contains two engines:

- **PXA** ([poisonxa16/pxa](https://github.com/poisonxa16/pxa)) is a Pascal/Volta-tuned llama.cpp fork that runs PXQ-format models.
  PXA only ships Linux builds; this repo adds a **Windows port**, `patches/pxa-windows.patch`. That patch:
  - replaces Linux-only code (GCC `weak` symbols and builtins/atomics, POSIX `setenv`/`mkdir`/`access`/`fsync`) with MSVC equivalents
  - works around an nvcc front-end bug in the PXQ GEMV templates
  - fixes a filename clash with the root `VERSION` file on case-insensitive filesystems
  - makes atomic file replacement work on Windows

  PXA's closed-source **PXQN** library is Linux-only, so PXQN models are **not** supported. PXQ models and standard GGUF files are.
- **FastMTP llama.cpp** is upstream [llama.cpp](https://github.com/ggml-org/llama.cpp) at commit `4df29be`, plus the
  [HauhauCS FastMTP patch](https://huggingface.co/HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF).
  It's needed for the FastMTP draft sidecar and the `draft-mtp` speculative mode.

Both are built with CUDA 12.9 for `sm_70`. CUDA 13 dropped Volta support, so CUDA 12.x is required.

## Build from source (optional)

Requirements: Visual Studio 2022 Build Tools with the "Desktop development with C++" workload, CMake, and git.

```powershell
powershell -ExecutionPolicy Bypass -File build\get-cuda-12.9.ps1   # local CUDA 12.9 from NVIDIA's redist archives, checksum-verified
build\build-pxa.cmd                                                # PXA + Windows patch   -> build\pxa\build\bin
build\build-fastmtp.cmd                                            # llama.cpp + FastMTP   -> build\llama.cpp\build\bin
```

Then copy the `llama-*.exe` files into `bin\pxa` and `bin\fastmtp`. Each build takes about 20–40 minutes, most of it compiling CUDA kernels.

## Troubleshooting

- **`cudaMalloc failed: out of memory`:** something else is using the GPU. Check with `nvidia-smi` and close other model servers, or reduce `-c` (the context size).
- **The window closes immediately:** run the script from a `cmd` window so you can read the error. Most often the model files are missing; run `scripts\download-models.ps1`.
- **WSL or Docker can't see the V100:** that's expected. A V100 in TCC mode isn't visible to WSL2, which is why this repo uses native Windows builds.
- **Only some layers are offloaded, or it runs on the CPU:** update the NVIDIA driver to R576 or newer.

## Licences and credits

- PXA: MIT, © PXA Network and the llama.cpp, ggml and ik_llama.cpp authors. See `LICENSES/PXA-LICENSE.txt` and `PXA-NOTICE.txt`.
- llama.cpp / ggml: MIT. See `LICENSES/llama.cpp-LICENSE.txt`.
- HauhauCS FastMTP patch: from the HauhauCS model release.
- CUDA runtime DLLs (`cudart`, `cuBLAS`, `cuBLASLt`): redistributed under the NVIDIA CUDA EULA. See `LICENSES/NVIDIA-CUDA-EULA.txt`.
- Microsoft Visual C++ runtime DLLs: redistributed under the Visual Studio redistributable terms.
- Models are **not** included. They download from their authors' Hugging Face repos under those repos' licences.

The scripts and patches in this repo are MIT licensed.
