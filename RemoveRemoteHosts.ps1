If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}
# Now running elevated so launch the script:
$File = Get-Content c:\windows\system32\drivers\etc\hosts
$Result = $File -replace "99.99.99.99 test.com.au",""
$Result = $Result -join "`r`n"
$Result = $Result.trim()
$Result >  c:\windows\system32\drivers\etc\hosts