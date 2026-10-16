@echo off
rem Qwen3.8-27B HauhauCS IQ3_XS + FastMTP sidecar + vision (FastMTP engine). ~40-53 t/s, 24k context.
rem For code-heavy use add: --spec-draft-n-max 4
rem Open http://127.0.0.1:%PORT% (default 8899). Needs: scripts\download-models.ps1 hauhau
call "%~dp0_common.cmd" || exit /b 1
"%ROOT%\bin\fastmtp\llama-server.exe" ^
  -m "%M%\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-IQ3_XS.gguf" ^
  --spec-type draft-mtp ^
  --spec-draft-model "%M%\Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-FastMTP-32K.gguf" ^
  --spec-draft-ngl all --spec-draft-n-max 2 --spec-draft-p-min 0 ^
  --mmproj "%M%\mmproj-Qwen3.8-27B-Q8_0.gguf" ^
  --host %HOST% --port %PORT% ^
  -ngl all -c 24576 -np 1 -fa on --no-mmap -b 2048 -ub 512 ^
  --jinja --reasoning off ^
  --temp 0.7 --top-k 20 --top-p 0.8 --min-p 0 ^
  %*
