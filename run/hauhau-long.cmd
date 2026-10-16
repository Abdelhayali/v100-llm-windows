@echo off
rem Qwen3.8-27B HauhauCS IQ3_XS, 120k CONTEXT + vision (FastMTP engine, built-in MTP head).
rem Fits 16 GB with: 4-bit KV cache, vision encoder on CPU, built-in MTP instead of the sidecar.
rem Do not lower -ub below 256 (cuBLAS crash) or raise it above 256 (out of memory at 118k).
rem Speed: ~46 t/s short prompts, ~14 t/s at 118k; a 118k prompt takes ~10 min to read.
rem Open http://127.0.0.1:%PORT% (default 8899). Needs: scripts\download-models.ps1 hauhau
call "%~dp0_common.cmd" || exit /b 1
"%ROOT%\bin\fastmtp\llama-server.exe" ^
  -m "%M%\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-IQ3_XS.gguf" ^
  --mmproj "%M%\mmproj-Qwen3.8-27B-Q8_0.gguf" --no-mmproj-offload ^
  --spec-type draft-mtp --spec-draft-n-max 2 --spec-draft-p-min 0 ^
  --spec-draft-type-k q4_0 --spec-draft-type-v q4_0 ^
  --host %HOST% --port %PORT% ^
  -ngl all -c 122880 -ctk q4_0 -ctv q4_0 -np 1 -fa on --no-mmap -b 2048 -ub 256 ^
  --jinja --reasoning off ^
  --temp 0.7 --top-k 20 --top-p 0.8 --min-p 0 ^
  %*
