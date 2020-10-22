#
# - 	Script Gets all the Files in a Directory($filesToFind) and its subdirectories
# - 	Searches for these Files in another Directory ($searchIn)
# - 	Then as it Finds these files in the $searchIn Directory It Copies the parent directory
#   	at the number of levels specified as $depth
#
#	-	Set test to 1 in order to just print the resulting copies to the screen
#	-	If you want to replicate the file structure that the files you are searching for are stored in then
#		set replicateDir to 1
#
# 	- 	Do not include trailing '\' in absolute paths
#

# Absolute path of directory containing files to search for
$filesToFind = "Z:\power"
# Absolute path of directory to search for the files in
$searchIn = "Z:\Test Powershell"
# Number representing the absolute depth (Number of \'s in path) to copy to destination directory
$depth = 3
# Absolute path to destination directory for found file directories
$destination = "Z:\Destination"
# Replicate directory structure in destination, 1 = replicate
$replicateDir = 1
# If is 0 then it runs normally, copying files and printing to screen, anything else and it only prints to screen
$test = 0

$files = Get-ChildItem $filesToFind -Force -File -Recurse
foreach ($file in $files) {

	$fullbasepath = ""
	$fullDestination = ""

	#### Find any subdirectories this is stored under in case replicateDir is 1 ####
	$filePathArr = $file.FullName.Split("\")
	$filePathArrCount = $filePathArr.Count - 1
	$filesDirArr = $filesToFind.Split("\")
	$filesDirArrCount = $filesDirArr.Count
	
	$filePathSubDir = ""
	
	# Create $filePathSubDir and Populate with Subdirectories The $file being Processed Is Under
	If ($filePathArrCount -gt $filesDirArrCount) {
		$first = 1
		For ($i=$filesDirArrCount;$i -lt $filePathArrCount;$i++) 
		{
			If ($first -eq 1) {
				$first = 0
				$filePathSubDir = $filePathArr[$i]
			} Else {
				$filePathSubDir += '\'
				$filePathSubDir += $filePathArr[$i]
			}
		}
	}
	
	#### Find the file and build a path to it ####
	$directories = Get-ChildItem $searchIn -Force -Recurse -filter $file.Name
	foreach ($dir in $directories) {
		$arr = $dir.FullName.Split("\")
		# Build path to copy for this file and get the folder name
		For($i=0;$i -lt $depth;$i++)
		{
			If ($i -eq 0) {
				$joinArr = $arr[$i]
			} ElseIf ($i -eq $depth -1) {
				# Get name of folder being copied
				$copyFolder = $arr[$i]
			} 
			If ($i -ne 0) {
				$joinArr += '\'
				$joinArr += $arr[$i]
			}
		}
		If ($replicateDir -eq 1) {
			$fullbasepath = -join ($joinArr)
			If ($filePathSubDir -ne "") {
				$fullDestination = -join ($destination, '\', $filePathSubDir, '\', $copyFolder)
			} Else {
				$fullDestination = -join ($destination, '\', $copyFolder)
			}
		} Else {
			$fullbasepath = -join ($joinArr)
			$fullDestination = -join ($destination, '\', $copyFolder)
		}
	}
	
	#### If we found the file then copy it ####
	If ($fullbasepath -ne "" -And $fullDestination -ne "") {
		# Write the copy to screen
		Write-Host "Copying '$($fullbasepath)' to '$($fullDestination)'"
		If ($test -eq 0) {
			Copy-Item $fullbasepath -Destination $fullDestination -recurse -Force
		}
	} else {
		Write-Host "$($file.Name) Not Found"
	}
	
}