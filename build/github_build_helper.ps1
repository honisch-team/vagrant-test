#Requires -Version 7
param(
    # Install Windows ADK Deployment tools
    [Parameter(Mandatory = $true, ParameterSetName = 'InstallAdkDeploymentTools')]
    [switch] $InstallAdkDeploymentTools,

    # Get hash of string
    [Parameter(Mandatory = $true, ParameterSetName = 'GetStrHash')]
    [switch] $GetStrHash,

    # string to hash
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'GetStrHash')]
    [string] $StrToHash
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


# Main function
function Main {
    # Handle installing Windows ADK deployment tools
    if ($InstallAdkDeploymentTools) {
        InstallAdkDeploymentTools
    }

    # Get hash of string
    if ($GetStrHash) {
        $stringAsStream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write($StrToHash)
        $writer.Flush()
        $stringAsStream.Position = 0
        Write-Host (Get-FileHash -Algorithm SHA1 -InputStream $stringAsStream).Hash
    }
}

Main
