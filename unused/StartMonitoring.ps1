try {
### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO

    $folder = Read-Host -Prompt "Enter dir"
    if (-Not (Test-Path "C:\wamp64\www\adways\content-hosting\public\content\Adways\$($folder)\css")) {
        New-Item C:\wamp64\www\adways\content-hosting\public\content\Adways\$($folder)\css -type directory
    }
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = "C:\wamp64\www\adways\content-hosting\public\content\Adways\$($folder)"
    $watcher.Filter = "*.sass"
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true  

### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = {
                $path = $Event.SourceEventArgs.FullPath
                $filename = $Event.SourceEventArgs.Name
                $truncated_path = $path.Substring(0, $path.LastIndexOf('\'))
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
                $pinfo.Arguments = $path, $filename.Substring(0, $filename.LastIndexOf('.')), $truncated_path
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
    Register-ObjectEvent $watcher Created -SourceIdentifier FileCreated -Action $action
    Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action $action
    Register-ObjectEvent $watcher Deleted -SourceIdentifier FileDeleted -Action $action
    Register-ObjectEvent $watcher Renamed -SourceIdentifier FileRenamed -Action $action
    while ($true) {sleep 5}
} finally {
### STOP MONITORING
    Unregister-Event FileChanged
    Unregister-Event FileCreated
    Unregister-Event FileRenamed
    Unregister-Event FileDeleted
    Write-Host "*** END COMPILING ¯\_(ツ)_/¯ ***" -fore yellow
}