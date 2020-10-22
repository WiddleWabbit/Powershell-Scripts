# ------------------------------------ #
### Check Dependencies Are Installed ###
# ------------------------------------ #

Write-Host ""
if (Get-Module -ListAvailable -Name Posh-SSH) {
    Write-Host "Module Installed Continuing With Script"
} else {
    # Install Module & Package Provider If Required
    Write-Host "Posh-SSH Module Not Installed"
    Write-Host "Installing Posh-SSH"
    $NuGetProvider = Get-PackageProvider -Name "NuGet" -ListAvailable -ErrorAction SilentlyContinue
    Try {
        if (-not $NuGetProvider) {
            Write-Host "Package Provider Not Installed"
            Write-Host "Installing Package Provider NuGet"
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force -Verbose
            Write-Host "Installed NuGet"
            Write-Host "Continuing with Posh-SSH Installation"
            Install-Module -Name Posh-SSH -RequiredVersion 2.2 -Confirm:$False -Force -Verbose
            Write-Host "Installation Complete"
        } else {
            Install-Module -Name Posh-SSH -RequiredVersion 2.2 -Confirm:$False -Force -Verbose
            Write-Host "Installation Complete"
        }
    } catch [Exception]{
        Write-Host ""
        Write-Host "Error"
        Write-Host $_.ToString()
        exit
    }
}

# ----------------------------------- #
### Begin Preparing SFTP Connection ###
# ----------------------------------- #

# Define Server Name
$ComputerName = ""

# Define Port Number
$Port = 9999

# Define UserName
$UserName = ""

#Define the Private Key file path
$KeyFile = "E:\SysAdmin\id_rsa"

#Defines to not popup requesting for a password
$nopasswd = new-object System.Security.SecureString

#Set Credetials to connect to server
$Credential = New-Object System.Management.Automation.PSCredential ($UserName, $nopasswd)

# Set local file path and SFTP path (with trailing slash)
$LocalPath = ""
$SftpPath = '/'

# Establish the SFTP connection
Try {
    $SFTPSession = New-SFTPSession -ComputerName $ComputerName -Port $Port -Credential $Credential -KeyFile $KeyFile -Force
    Write-Host ""
} catch [Exception]{
    Write-Host ""
    Write-Host "Error Connecting"
    Write-Host $_.ToString()
    exit
}

# -------------------------------------- #
### Check SFTP File Structure & Modify ###
# -------------------------------------- #

If ($SFTPSession) {

    # Convert local system time to WAST
    $year = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( (Get-Date), 'W. Australia Standard Time')
    $month = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( (Get-Date), 'W. Australia Standard Time')
    $day = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( (Get-Date), 'W. Australia Standard Time')
    # Get the year, month, day strings from this
    $year = $year.ToString("yyyy")
    $month = $month.ToString("MM")
    $day = $day.ToString("dd")

    # lists directory files into variable from the SFTP server
    $SFTPMainPath = Get-SFTPChildItem -sessionID $SFTPSession.SessionID -path $SftpPath

    $yearExists = 0
    $monthExists = 0
    #$dayExists = 0

    # Look through main file for the folders we need and create if they dont exist
    ForEach ($file in $SFTPMainPath) {
        If ($file.Name -eq $year) {

            Write-Host "Using Year File: " $file.Name
            $yearPath = "$($SftpPath)$($file.Name)"
            $yearExists = 1
            $SFTPYearPath = Get-SFTPChildItem -sessionID $SFTPSession.SessionID -path $yearpath

            ForEach ($monthFile in $SFTPYearPath) {
                If ($monthFile.Name -eq $month) {

                    Write-Host "Using Month File: " $monthFile.Name
                    $monthPath = "$($yearPath)/$($monthFile.Name)"
                    $monthExists = 1
                    $SFTPMonthPath = Get-SFTPChildItem -sessionID $SFTPSession.SessionID -path $monthPath

                }
            }

        }
    }

    If ($yearExists -eq 0) {
        $yearPath = "$($SftpPath)$($year)"
        Write-Host "Year Directory Does Not Exists, Creating.."
        New-SFTPItem -SessionId $SFTPSession.SessionID -Path $yearPath -ItemType Directory
        Write-Host "Created: " $yearPath 
        Write-Host ""
    }
    If ($monthExists -eq 0) {
        $monthPath = "$($yearPath)/$($month)"
        Write-Host "Month Directory Does Not Exists, Creating.."
        New-SFTPItem -SessionId $SFTPSession.SessionID -Path $monthPath -ItemType Directory 
        Write-Host "Created: " $monthPath
        Write-Host ""
    }


    Write-Host ""
    Write-Host "Changing Directory to:"
    #Set-SFTPLocation -SessionId $SFTPSession.SessionID  $dayPath
    Set-SFTPLocation -SessionId $SFTPSession.SessionID  $monthPath
    Get-SFTPLocation -SessionId $SFTPSession.SessionID

    # ------------------------------ #
    ### Upload the Specified Files ###
    # ------------------------------ #

    $localFiles = Get-ChildItem $localPath

    ForEach ($file in $localFiles) {
        Write-Host  ""
        Write-Host "Uploading $($file.Name)..."
        $filePath = "$($localPath)\$($file.Name)"
        Try {
            #Set-SFTPFile -SessionId $SFTPSession.SessionID -LocalFile $filePath -RemotePath $dayPath -Overwrite
            Set-SFTPFile -SessionId $SFTPSession.SessionID -LocalFile $filePath -RemotePath $monthPath -Overwrite
            Write-Host "Uploaded"
        } catch [Exception]{
            Write-Host ""
            Write-Host "Error Uploading File $($file.Name)"
            Write-Host $_.ToString()
        }
    }

    # ------------------------ #
    ### End the SFTP Session ###
    # ------------------------ #

    Write-Host ""
    Write-Host "Closing SFTP Session"
    $endSFTP = Remove-SFTPSession -SessionId $SFTPSession.SessionID
    If ($endSFTP -eq "True") {
        Write-Host "Session Ended"
    } else {
        Write-Host "Error: Session Not Closed"
    }
    Write-Host ""

}