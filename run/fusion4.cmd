@echo off
rem PXA-Fusion4-35B-A3B PXQ2 + vision on the V100 (PXA engine). Fastest model: ~65-75 t/s, 16k context.
rem Open http://127.0.0.1:%PORT% (default 8899). Needs: scripts\download-models.ps1 fusion4
call "%~dp0_common.cmd" || exit /b 1
"%ROOT%\bin\pxa\llama-server.exe" -m "%M%\PXA-Fusion4-35B-PXQ2.gguf" ^
  --mmproj "%M%\mmproj-fusion2-f16.gguf" ^
  --host %HOST% --port %PORT% ^
  -ngl 99 -c 16384 -np 1 -fa on --jinja --reasoning off ^
  --presence-penalty 1.5 --repeat-penalty 1.15 --repeat-last-n 256 --dry-multiplier 0.8 ^
  %*
