@echo off
rem Qwen3.8-27B HauhauCS IQ3_XS + FastMTP sidecar + vision on GPU, 80k CONTEXT (FastMTP engine).
rem Largest context that keeps both the FastMTP sidecar and the image encoder on a 16 GB V100:
rem a 77k-token prompt passed; 90k ran out of memory at ~87k. Uses a 4-bit KV cache for the main model.
rem Do not quantize the sidecar cache (--spec-draft-type-k/v): its compute buffer grows and it uses MORE memory.
rem Speed: ~46 t/s short prompts, ~22 t/s at 77k; a 77k prompt takes ~5.5 min to read.
rem Open http://127.0.0.1:%PORT% (default 8899). Needs: scripts\download-models.ps1 hauhau
call "%~dp0_common.cmd" || exit /b 1
"%ROOT%\bin\fastmtp\llama-server.exe" ^
  -m "%M%\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-IQ3_XS.gguf" ^
  --spec-type draft-mtp ^
  --spec-draft-model "%M%\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-FastMTP-32K.gguf" ^
  --spec-draft-ngl all --spec-draft-n-max 2 --spec-draft-p-min 0 ^
  --mmproj "%M%\mmproj-Qwen3.8-27B-Q8_0.gguf" ^
  --host %HOST% --port %PORT% ^
  -ngl all -c 81920 -ctk q4_0 -ctv q4_0 -np 1 -fa on --no-mmap -b 2048 -ub 256 ^
  --jinja --reasoning off ^
  --temp 0.7 --top-k 20 --top-p 0.8 --min-p 0 ^
  %*
