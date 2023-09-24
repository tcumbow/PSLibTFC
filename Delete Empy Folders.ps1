# Walks through a folder recursively and persistently deletes all empty folders
# Not the most efficient way to do it, but it should be quite reliable

function DeleteEmptyFolders ($Path) {
	$SomeFoldersDeletedSuccessfully = $true # a little white lie to start things off
	while ($SomeFoldersDeletedSuccessfully) {
		$SomeFoldersDeletedSuccessfully = $false
		$Folders = Get-ChildItem -Path $Path -Recurse -Directory
		foreach ($Folder in $Folders) {
			$FolderPath = $Folder.FullName
			if (-not(Test-Path -Path $FolderPath)) {
				continue
			}
			$Items = Get-ChildItem -Path $FolderPath -Force
			if ($Items.Count -eq 0) {
				try {
					Remove-Item -Path $FolderPath -Force -ErrorAction Stop
					$SomeFoldersDeletedSuccessfully = $true
					Write-Verbose $FolderPath
				}
				catch {
					Write-Verbose "Failed to delete $FolderPath"
				}
			}
		}
	}
}
