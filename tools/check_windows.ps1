param([Parameter(Mandatory = $true)][string]$Executable)
$ErrorActionPreference = "Stop"
$program = (Resolve-Path $Executable).Path
$isolated = Join-Path ([IO.Path]::GetTempPath()) ("godot-windows-smoke-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $isolated | Out-Null
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
try {
    $env:APPDATA = Join-Path $isolated "roaming"
    $env:LOCALAPPDATA = Join-Path $isolated "local"
    New-Item -ItemType Directory -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    $stdout = Join-Path $isolated "stdout.log"
    $stderr = Join-Path $isolated "stderr.log"
    $process = Start-Process -FilePath $program -ArgumentList "--headless", "--fixed-fps", "60", "--quit-after", "300" -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    if (-not $process.WaitForExit(45000)) {
        $process.Kill()
        throw "Windows executable did not complete startup within 45 seconds"
    }
    $process.WaitForExit()
    $logs = ((Get-Content $stdout -Raw), (Get-Content $stderr -Raw)) -join [Environment]::NewLine
    Write-Output $logs
    if ($process.ExitCode -ne 0 -or $logs -match "(?m)^(SCRIPT )?ERROR:") {
        throw "Exported Windows startup failed with exit code $($process.ExitCode)"
    }
    Write-Output "Windows executable startup passed."
}
finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
    Remove-Item -Recurse -Force $isolated
}
