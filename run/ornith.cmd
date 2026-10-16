@echo off
rem Ornith-1.5-35B-A3B PXQ2 + vision on the V100 (PXA engine). ~60 t/s, 16k context.
rem Open http://127.0.0.1:%PORT% (default 8899). Needs: scripts\download-models.ps1 ornith
call "%~dp0_common.cmd" || exit /b 1
"%ROOT%\bin\pxa\llama-server.exe" -m "%M%\Ornith-1.5-35B-A3B-PXQ2-GGUF.gguf" ^
  --mmproj "%M%\mmproj-Ornith-1.5-35B-BF16.gguf" ^
  --host %HOST% --port %PORT% ^
  -ngl 99 -c 16384 -np 1 -fa on --jinja --reasoning off ^
  --presence-penalty 1.5 --repeat-penalty 1.15 --repeat-last-n 256 --dry-multiplier 0.8 ^
  %*
