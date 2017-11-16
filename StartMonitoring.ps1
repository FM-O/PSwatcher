. .\Modules\Tools\Tools.ps1
try {
### RETRIEVE CONF FROM INI FILE
    $conf = Get-Parsed-IniFile("conf.ini")
    $dir = $conf['PATH'].root
    $dest = 'css'
    $source = 'scss'
    $syntax = $conf['SETTINGS'].syntax
    if ($conf['PATH'].dest) {
        $dest = $conf['PATH'].dest
    }
    if ($conf['PATH'].source) {
        $source = $conf['PATH'].source
    }
    
### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO

    $folder = Read-Host -Prompt "Enter dir"
    if (-Not (Test-Path "$dir$($folder)\$dest")) {
        New-Item $dir$($folder)\$dest -type directory
    }
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = "$dir$($folder)\$source"
    $watcher.Filter = "*.$syntax"
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true

### CREATE THE PSO OBJECT TO STORE OUR VARIBABLES
    $pso = New-Object psobject -Property @{source=$source; dest="$dir$($folder)\$dest"}

### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = {
                $path = $Event.SourceEventArgs.FullPath
                $filename = $Event.SourceEventArgs.Name
                #$truncated_path = $path.Substring(0, $path.LastIndexOf('\'))
                $changeType = $Event.SourceEventArgs.ChangeType
                $logline = "$(Get-Date), $changeType, $path"
                Write-Host $changeType -fore green
                Write-Host "compiling" $path -fore yellow
                Add-content "c:\testfolder\logs\log.txt" -value $logline
                $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                $pinfo.FileName = "C:\Users\Florian\scripts\sass_compiler_copy.bat"
                $pinfo.RedirectStandardError = $true
                $pinfo.RedirectStandardOutput = $true
                $pinfo.UseShellExecute = $false                
                $pinfo.Arguments = $path, $filename.Substring(0, $filename.LastIndexOf('.')), $Event.MessageData.dest
                $p = New-Object System.Diagnostics.Process
                $p.StartInfo = $pinfo
                $p.Start() | Out-Null                
                $stdout = $p.StandardOutput.ReadToEnd()
                $stderr = $p.StandardError.ReadToEnd()
                $p.WaitForExit()
                Write-Host "stdout: $stdout"
                Write-Host "stderr: $stderr" -fore DarkRed -back White
                Write-Host "exit code: " + $p.ExitCode
                #$process = Start-Process C:\Users\Florian\scripts\sass_compiler_copy.bat $path, $filename.Substring(0, $filename.LastIndexOf('.')), $truncated_path -Wait -NoNewWindow
                #Write-Host $process.StandardError
                #Write-Host $process.StandardOutput
              }    
### DECIDE WHICH EVENTS SHOULD BE WATCHED 
    Register-ObjectEvent $watcher Created -SourceIdentifier FileCreated -Action $action -MessageData $pso
    Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action $action -MessageData $pso
    Register-ObjectEvent $watcher Deleted -SourceIdentifier FileDeleted -Action $action -MessageData $pso
    Register-ObjectEvent $watcher Renamed -SourceIdentifier FileRenamed -Action $action -MessageData $pso
    while ($true) {sleep 2}
} finally {
### STOP MONITORING
    Unregister-Event FileChanged
    Unregister-Event FileCreated
    Unregister-Event FileRenamed
    Unregister-Event FileDeleted
    Write-Host "*** END COMPILING ¯\_(ツ)_/¯ ***" -fore yellow
}