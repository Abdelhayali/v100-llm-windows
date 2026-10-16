@echo off
rem Qwen3.8-27B PXQ3 + vision on the V100 (PXA engine). ~27 t/s, 8k context (16 GB limit).
rem Open http://127.0.0.1:%PORT% (default 8899). Needs: scripts\download-models.ps1 qwen27b
call "%~dp0_common.cmd" || exit /b 1
"%ROOT%\bin\pxa\llama-server.exe" -m "%M%\Qwen3.8-27B-PXQ3-GGUF.gguf" ^
  --mmproj "%M%\mmproj-Qwen3.8-27B-Q8_0.gguf" ^
  --host %HOST% --port %PORT% ^
  -ngl 99 -c 8192 -np 1 -fa on --jinja --reasoning off ^
  %*
