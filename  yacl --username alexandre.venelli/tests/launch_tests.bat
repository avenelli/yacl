@echo OFF
echo delete .log files
del log\*.log

echo launch test files
for %%i in (Test_*) do (
echo %%i
python %%i
)

PAUSE