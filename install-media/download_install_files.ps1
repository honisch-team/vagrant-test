#Requires -Version 7

param(
    # CSV file containing downloads
    [Parameter(Mandatory = $true)]
    [string] $DownloadsCsvFile,

    # Directory for downloads
    [Parameter(Mandatory = $true)]
    [string] $OutputDir,

    # Delete extra files/folders from downloads dir
    [Parameter(Mandatory = $false)]
    [switch] $CleanupDownloads,

    # Ignore hash mismatch
    [Parameter(Mandatory = $false)]
    [switch] $IgnoreHashMismatch,

    # Only verify that files exist
    [Parameter(Mandatory = $false)]
    [switch] $VerifyOnly
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


# Fail on on native error
function FailOnNativeError() {
    if ($LASTEXITCODE -ne 0) {
        throw
    }
}


# Check file hash
function CheckFileHash($filePath, $sha1) {
    Write-Host -NoNewline "Checking hash for $filePath ..."
    $fileHash = (Get-FileHash -Path $filePath -Algorithm 'SHA1').Hash.ToLowerInvariant()
    if ($fileHash -eq $sha1) {
        Write-Host "OK ($sha1)"
        return $true
    }
    else {
        Write-Host "failed (expected: $sha1, got:$fileHash)"
        return $false
    }
}


# Download file
function DownloadFile($comment, $url, $filePath, $sha1, $ignoreHashMismatch) {
    Write-Host "** Downloading `"$comment`": $url to $filePath..."

    $doDownload = $true
    $result = $true

    # Check whether file exists
    if (Test-Path $filePath) {
        # Checking file hash
        Write-Host 'File exists, checking hash...'
        if (CheckFileHash $filePath $sha1) {
            Write-Host "Hash matches $sha1 => skipping download"
            $doDownload = $false
        }
        else {
            Write-Host -NoNewline 'Hash mismatch ...'
            if (-not $ignoreHashMismatch) {
                Write-Host '=> removing file'
                Remove-Item -Force $filePath | Out-Null
            }
            else {
                Write-Host 'ignoring'
                $doDownload = $false
            }
        }
    }

    # Dowload file
    if ($doDownload) {
        Write-Host 'Downloading...'
        & curl.exe -L -o $filePath --retry 5 --retry-all-errors $url ; FailOnNativeError
        if (-not (CheckFileHash $filePath $sha1)) {
            Write-Host -NoNewline 'Hash mismatch ...'
            if (-not $ignoreHashMismatch) {
                Write-Host '=> Error'
                $result = $false
            }
            else {
                Write-Host 'ignoring'
            }
        }
    }

    Write-Host "** Done: Downloading `"$comment`": $url to $filePath"
    return $result
}


# Verify file
function VerifyFile($comment, $filePath, $sha1) {
    Write-Host "** Verifying `"$comment`": $filePath..."

    $result = $true

    # Check whether file exists
    if (Test-Path $filePath) {
        if (CheckFileHash $filePath $sha1) {
            Write-Host 'success'
        }
        else {
            Write-Host -NoNewline 'Hash mismatch => Error'
            $result = $false
        }
    }
    else {
        Write-Host 'File missing => Error'
        $result = $false
    }

    Write-Host "** Done: Verifying `"$comment`": $filePath..."
    return $result
}


# Download install files
function DownloadInstallFiles($csvPath, $outputDir, $cleanup, $ignoreHashMismatch, $verifyOnly) {
    Write-Host "*** Downloading required install files to $outputDir"

    # Make sure output dir exists
    mkdir $outputDir -Force | Out-Null

    Write-Host "Parsing $csvPath"

    # Open CSV file
    $csv = Import-Csv $csvPath -Delimiter ';'

    # Track required downloads
    $requiredDownloads = @{}

    # Generate data to hash
    $errorsOccurred = $false
    foreach ($row in $csv) {
        # Ignore all rows starting with #
        if ($row.Comment -match '^\s*#') {
            continue
        }

        # Process entry
        $localFilename = Split-Path -Leaf $row.Url
        $requiredDownloads[$localFilename] = $true
        $localPath = Join-Path $outputDir $localFilename
        if ($verifyOnly) {
            if (-not (VerifyFile $row.Comment $localPath $row.Sha1)) {
                $errorsOccurred = $true
            }
        }
        else {
            if (-not (DownloadFile $row.Comment $row.Url $localPath $row.Sha1 $ignoreHashMismatch $verifyOnly)) {
                $errorsOccurred = $true
            }
        }
    }

    if ($errorsOccurred) {
        throw 'Errors occurred, aborting'
    }

    # Cleanup
    if ($cleanup) {
        Write-Host '** Cleaning up downloads dir'
        $downloadItems = Get-ChildItem $outputDir
        foreach ($item in $downloadItems) {
            if ($requiredDownloads[$item.Name] -ne $true) {
                Write-Host "Removing: $($item.Name)"
                Remove-Item $item -Recurse -Force
            }

        }
        Write-Host '** Done: Cleaning up downloads dir'
    }

    Write-Host "** Done: Downloading required install files to $outputDir"
}




# Main function
function Main() {
    # Download install files
    DownloadInstallFiles $DownloadsCsvFile $OutputDir $CleanupDownloads $IgnoreHashMismatch $VerifyOnly

    # Finished
    Write-Host '*** Done'
}


Main
