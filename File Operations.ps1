function ReplaceFileIfDifferent ( [string]$SourcePath, [string]$DestinationPath ) {
    # The point of this function is to not mess with the modified date of the destination file if it's identical to the source file.
    if ((-not (Test-Path -LiteralPath $DestinationPath)) `
            -or ((Get-FileHash -LiteralPath $SourcePath).hash -ne (Get-FileHash -LiteralPath $DestinationPath).hash)) {
        Move-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    }
}

function DeleteFileIfExists ( [string]$Path ) {
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force
    }
}
