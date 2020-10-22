# Script to Find Files/Folders listed in Excel from a set directory and then copy them to folders based on the sheet names

# SET TESTMODE TO 1 TO ONLY PRINT TO SCREEN AND NOT ACTUALLY COPY
$TESTMODE = 0

# THIS IS THE DIRECTORY CONTAINING THE EXCEL DOCUMENT
$currentDir = "Z:\Powershell"
# SEARCH THIS DIRECTORY AND ITS SUBFOLDERS
$dirToSearch = "Z:\New folder (18)"
# FOR THE FILES CONTAINED IN THIS EXCEL DOCUMENT (COLUMN A - EVERY SHEET)
$ExcelFile = $currentDir + "\ToBeRendered.xlsx"
# AND COPY THEM HERE UNDER THE SHEET NAME (WITH TRAILING SLASH)
$copyToDir = "Z:\New folder (22)\"

# Open the Excel Object
$excel = New-Object -com Excel.Application
# Don't want it to actually open excel
$excel.Visible = $false
# Open the workbook
$wb = $excel.workbooks.open($ExcelFile)


#$Excel.WorkBooks | Get-Member

# Store Sheet Names
$sheetNames = $wb.sheets | Select-Object -Property Name

Foreach ($sheet in $sheetNames) {

    # Print the Proccessed Sheet Name to Screen
    Write-Host "Processing Sheet - " $sheet.Name

    # Get the Currently Processed Sheet
    $ws = $wb.sheets.item($sheet.Name)

    # Get the Last Row Number
    $endRow = ($ws.UsedRange.Rows).Count

    # For Each Row in This Sheet
    For ($i=1;$i -le $endRow;$i++) {

        # Print to Screen the Lists Text
        # cells.Item(row, col)
        $folder = $ws.cells.Item($i, 1).Text
        
        # Find the file/folder in the search directory
        $found = Get-ChildItem $dirToSearch -Force -Recurse -filter $folder

        If ($found) {
            #Write-Host $found.FullName
            $copyFile = $copyToDir.Trim() + $sheet.Name.Trim() + "\" + $folder.Trim()
            If ($TESTMODE -eq 1) {
                Write-Host "Copy Item" $found.FullName "-Destination " $copyFile "-Recurse -Force"
            } else {
                Copy-Item $found.FullName -Destination $copyFile -Recurse -Force
                Write-Host "Copied " $found.FullName " To " $copyFile
            }
        } else {
            Write-Host "Could Not Find " $folder
        }
    }
}