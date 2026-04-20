Write-Host "Cleaning previous build..." -ForegroundColor Cyan
Remove-Item test.o, ZSOC.vcd, output.txt -ErrorAction SilentlyContinue

Write-Host "Compiling..." -ForegroundColor Cyan
iverilog -g2012 -Winfloop -DTESTBENCH -o test.o -s test -I../include ./soktb.v ../CPU/*.v ../Memories/*.v ../*.v ../CPU/*.sv

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed! Bailing out." -ForegroundColor Red
    exit 1
}

Write-Host "Running simulation (Press Ctrl+C to halt and view waves)..." -ForegroundColor Yellow

try {
    # If the simulation hangs, press Ctrl+C here...
    "finish" | vvp test.o | Out-File output.txt
}
finally {
    # ...and PowerShell will immediately jump to this block instead of dying.
    Write-Host "Opening GTKWave..." -ForegroundColor Green
    Start-Process gtkwave -ArgumentList "gtkw.gtkw" -ErrorAction SilentlyContinue
    
    Write-Host "Done." -ForegroundColor Cyan
}