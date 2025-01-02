#Requires -Version 7
param(
    # Install Windows ADK Deployment tools
    [Parameter(Mandatory = $true, ParameterSetName = 'InstallAdkDeploymentTools')]
    [switch] $InstallAdkDeploymentTools,

    # Get install files cache keys
    [Parameter(Mandatory = $true, ParameterSetName = 'GetInstallFilesCacheKeys')]
    [switch] $GetInstallFilesCacheKeys,

    # Download list for install image
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'GetInstallFilesCacheKeys')]
    [string] $DownloadsInstallImage,

    # Download list for updates
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'GetInstallFilesCacheKeys')]
    [string] $DownloadsUpdate,

    # Build install image script file
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'GetInstallFilesCacheKeys')]
    [string] $BuildInstallImage
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


# Install Windows ADK deployment tools
function InstallAdkDeploymentTools() {
    Write-Host '*** Installing Windows ADK deployment tools'
    $ADK_SETUP_URL = 'https://go.microsoft.com/fwlink/?linkid=2120254'
    $adkSetupExe = Join-Path $env:TEMP 'AdkSetup.exe'

    # Download setup exe
    Write-Host "Downloading AdkSetup.exe from $ADK_SETUP_URL to $adkSetupExe"
    Invoke-WebRequest -Uri $ADK_SETUP_URL -UseBasicParsing -OutFile $adkSetupExe

    # Execute setup
    Start-Process $adkSetupExe -Wait -ArgumentList '/features OptionId.DeploymentTools /q /norestart /ceip off'
    Write-Host 'Done'
}


# Get cache keys for install files
function GetInstallFilesCacheKeys($csvInstallImageFiles, $csvUpdateFiles, $scriptFile) {
    Write-Host '*** Calculating install media cache keys'

    # Get install media script data as string
    $scriptStr = Get-Content -Raw $scriptFile

    # Get install imagefiles hash
    $installImageFilesHash = GetDownloadsListHash $csvInstallImageFiles

    # Get update files hash
    $updateFilesHash = GetDownloadsListHash $csvUpdateFiles

    # Get script data hash
    $scriptHash = GetHashOfString $scriptStr

    # Install image hash is combined hash of downloads hash and script hash
    $installImageHash = GetHashOfString "$installImageFilesHash`r`n$scriptHash"

    # Return cache keys
    return @{
        installImageFilesKey  = $installImageFilesHash
        customInstallImageKey = $installImageHash
        updateFilesKey        = $updateFilesHash
    }
}


# Get hash of downloads list
function GetDownloadsListHash($csvFile) {

    Write-Host "Parsing $csvFile"

    # Open downloads file
    $csv = Import-Csv $csvFile -Delimiter ';'
    $lines = [System.Collections.ArrayList]::new()

    # Generate data to hash
    foreach ($row in $csv) {
        # Ignore commented rows
        if ($row.Comment -match '^\s*#') {
            continue
        }
        # Ignore "Comment" column
        [void]$lines.Add("$($row.Url);$($row.Sha1)")
    }

    # Combine into single string
    $str = $lines | Join-String -Separator "`r`n"

    return (GetHashOfString $str)
}


# Get hash value of given string
function GetHashOfString($stringToHash) {

    $stringStream = $null
    $writer = $null
    try {
        $stringAsStream = [System.IO.MemoryStream]::new()
        # Write data to stream (default encoding: UTF8)
        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write($stringToHash)
        $writer.Flush()
        $stringAsStream.Position = 0

        # Hash stream data
        $hash = (Get-FileHash -Algorithm SHA1 -InputStream $stringAsStream).Hash.ToLowerInvariant()
        return $hash
    }
    finally {
        if ($null -ne $writer) {
            $writer.Close()
        }
        if ($null -ne $stringStream) {
            $stringStream.Close()
        }
    }

    # Return hash string
    Write-Output $hash
}


# Main function
function Main {
    # Handle installing Windows ADK deployment tools
    if ($InstallAdkDeploymentTools) {
        InstallAdkDeploymentTools
    }

    # Get install files cache keys
    if ($GetInstallFilesCacheKeys) {
        return GetInstallFilesCacheKeys $DownloadsInstallImage $DownloadsUpdate $BuildInstallImage
    }
}

Main
