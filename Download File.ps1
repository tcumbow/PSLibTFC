function DownloadFile ( [string]$URL, [string]$LocalPath, [switch]$Overwrite, [switch]$AllowEmptyFile ) {
    if ((Test-Path -LiteralPath $LocalPath) -and (-not $Overwrite)) {
        throw "File already exists: $LocalPath"
    }
    # get a temporary file name
    $TempFilePath = [System.IO.Path]::GetTempFileName()
    # download the file to the temporary file
    (New-Object System.Net.WebClient).DownloadFile($URL, $TempFilePath)
    # check if the file is empty
    if (-not $AllowEmptyFile) {
        $FileInfo = Get-Item -LiteralPath $TempFilePath
        if ($FileInfo.Length -eq 0) {
            throw "Downloaded file is empty: $TempFilePath"
        }
    }
    # move the temporary file to the desired location
    Move-Item -LiteralPath $TempFilePath -Destination $LocalPath -Force
}
