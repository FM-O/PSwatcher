##FIRST METHOD -need to get approved verbs

#Import-Module .\Modules\Tools -Verbose

##Barbarian's method
. .\Modules\Tools\Tools.ps1

#result
$conf = Get-Parsed-IniFile("test.ini")

Write-Host $conf['PATH'].root
