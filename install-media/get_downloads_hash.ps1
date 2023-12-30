#Requires -Version 7

param(
    # Downloads CSV file
    [Parameter(Mandatory = $true)]
    [string] $DownloadsCsvFile
)

# Terminate on exception
trap {
    Write-Host "Error: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}

# Always stop on errors
$ErrorActionPreference = 'Stop'

# Strict mode
Set-StrictMode -Version Latest

function Main() {
    Write-Host "Parsing $DownloadsCsvFile"

    # Open CSV file
    $csv = Import-Csv $DownloadsCsvFile -Delimiter ';'
    $lines = [System.Collections.ArrayList]::new()

    # Generate data to hash
    foreach ($row in $csv) {
        # Ignore all rows starting with #
        if ($row.Comment -notmatch '^\s*#') {
            # Ignore "Comment" column when hashing
            [void]$lines.Add("$($row.Url);$($row.Hash)")
        }
    }

    # Combine into single string
    $str = $lines | Join-String -Separator "`r`n"
    $stringAsStream = [System.IO.MemoryStream]::new()

    # Write data to stream (default encoding: UTF8)
    $writer = [System.IO.StreamWriter]::new($stringAsStream)
    $writer.write($str)
    $writer.Flush()
    $stringAsStream.Position = 0

    # Hash stream data
    $hash = (Get-FileHash -Algorithm SHA1 -InputStream $stringAsStream).Hash.ToLowerInvariant()
    Write-Host "File data hash: $hash"

    # Return hash string
    Write-Output $hash
}

Main
