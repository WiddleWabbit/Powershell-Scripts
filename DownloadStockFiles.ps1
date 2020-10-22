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

# Set download file path and SFTP path (with trailing slash)
$downloadToPath = ""
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
### Download All Spitwater Stock Files ###
# -------------------------------------- #

If ($SFTPSession) {

    If (!(test-path $downloadToPath)) {
        Write-Host ""
        Write-Host "Download Directory Does Not Exist, Creating.."
        New-Item -ItemType Directory -Force -Path $downloadToPath > $null
        Write-Host "Created $($downloadToPath)"
    }

    # lists directory files into variable from the SFTP server
    Set-SFTPLocation -SessionId $SFTPSession.SessionID  $SftpPath
    $SFTPMainPath = Get-SFTPChildItem -sessionID $SFTPSession.SessionID -path $SftpPath -Recursive
    #Get-SFTPChildItem -sessionID $SFTPSession.SessionID -path $SftpPath -Recursive

    ForEach ($file in $SFTPMainPath) {
        If ($file.Name -eq "." -Or $file.Name -eq ".." -Or $file.Name -eq "#recycle") {
            Write-Host "Skipping $($file.Name)"
        } else {

            $filePath = Split-Path -Path $file.FullName
            $pos = $filePath.IndexOf("\")
            $Root = $filePath.Substring($pos+1)
            $pos = $Root.IndexOf("\")
            $Spitwater = $Root.Substring($pos+1)
            $pos = $Spitwater.IndexOf("\")
            $StockFiles = $Spitwater.Substring($pos+1)

            $downloadPath = $downloadToPath+$StockFiles+"\"

            If (-Not $file.IsDirectory) {
                If (!(test-path $downloadPath)) {
                    Write-Host "Creating Directory $($downloadPath)"
                    New-Item -ItemType Directory -Force -Path $downloadPath > $null
                }
                Write-Host "Downloading $($file.Name)"
                #Get-SFTPItem -SessionId $SFTPSession.SessionID -Destination $downloadToPath -Path $file.FullName -Force -Verbose
                Get-SFTPFile -SessionId $SFTPSession.SessionID -LocalPath $downloadPath -RemoteFile $file.Fullname -Overwrite -Verbose
            }
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