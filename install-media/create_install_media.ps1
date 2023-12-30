#Requires -Version 5

param(
    # Download files only
    [Parameter(Mandatory = $false)]
    [switch] $DownloadOnly,

    # Skip download
    [Parameter(Mandatory = $false)]
    [switch] $SkipDownload
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

# Originial installer ISO
$ORG_INSTALLER_ISO_URL = 'https://archive.org/download/en_windows_7_enterprise_with_sp1_x86_dvd_u_677710_202006/en_windows_7_enterprise_with_sp1_x86_dvd_u_677710.iso'
$ORG_INSTALLER_ISO_SHA1 = '4e0450ac73ab6f9f755eb422990cd9c7a1f3509c'

# Image index for installer.wim
$INSTALLER_WIM_INDEX = 1

# Files that need to be downloaded
$FILES_TO_DOWNLOAD = @(, # Comma required to force two dimensional array when one element only
    # Original installer ISO
    #($ORG_INSTALLER_ISO_URL, $ORG_INSTALLER_ISO_SHA1),

    # Win 7 service stack update
    @('https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/updt/2015/04/windows6.1-kb3020369-x86_82e168117c23f7c479a97ee96c82af788d07452e.msu', '82e168117c23f7c479a97ee96c82af788d07452e')

)

# Download dir
$DOWNLOAD_DIR = Join-Path $PSScriptRoot 'download'

# Work dir
$WORK_DIR = Join-Path $PSScriptRoot 'work'

# Directory containing files for ISO image
$ISO_FILES_DIR = Join-Path $WORK_DIR 'iso'

# Directory for mounting Windows image
$WIM_MOUNT_DIR = Join-Path $WORK_DIR 'wim'

# Generated installer ISO path
$CUSTOM_INSTALLER_ISO = Join-Path $PSScriptRoot 'en_windows_7_enterprise_custom.iso'


# Indicate whether files were downloaded
$downloadOccurred = $false


# Fail on on native error
function FailOnNativeError() {
    if ($LASTEXITCODE -ne 0) {
        throw
    }
}

# Download file
function DownloadFile($url, $filePath, $sha1) {
    Write-Host "  Downloading $url to $filePath..."

    # Check whether file exists
    if (Test-Path $filePath) {
        Write-Host '    File exists, checking hash...'

        # Check existing file for corruption
        $fileHash = Get-FileHash -Path $filePath -Algorithm 'SHA1'
        if ($fileHash.Hash -eq $sha1) {
            Write-Host "    Hash matches $sha1 => skipping download"
            return
        }
        else {
            Write-Host "    Hash mismatch (required: $sha1, actual: $($fileHash.Hash) => removing file"
            Remove-Item -Force $filePath | Out-Null
        }
    }

    # Dowload file
    Write-Host '    Downloading...'
    & curl.exe -L -o $filePath $url ; FailOnNativeError
    Write-Host "CURL exit: $LASTEXITCODE"
    $script:downloadOccurred = $true
    Write-Host '    Done'
}


# Download installer files
function DownloadInstallerFiles() {
    Write-Host "*** Downloading required installer files to $DOWNLOAD_DIR"

    # Make sure download dir exists
    if (-not (Test-Path $DOWNLOAD_DIR)) {
        mkdir $DOWNLOAD_DIR | Out-Null
    }

    # Download files
    foreach ($downloadData in $FILES_TO_DOWNLOAD) {
        $url = $downloadData[0]
        $sha1 = $downloadData[1]
        $localFilename = Split-Path -Leaf $url
        $localPath = Join-Path $DOWNLOAD_DIR $localFilename
        DownloadFile $url $localPath $sha1
    }
}


# Prepare files for custom install image
function PrepareInstallImageFiles() {
    Write-Host '*** Preparing files for custom install image'

    # Indicate mounted ISO
    $isoIsMounted = $false

    # Indicated mounted WIM
    $wimIsMounted = $false

    try {

        # Create required directories
        if (Test-Path $WORK_DIR) {
            Write-Host "Removing existing work dir $WORK_DIR"
            Remove-Item $WORK_DIR -Recurse -Force
        }
        Write-Host "  Creating required directories in work dir $WORK_DIR"
        mkdir $WORK_DIR | Out-Null
        mkdir $ISO_FILES_DIR | Out-Null
        mkdir $WIM_MOUNT_DIR | Out-Null

        # Mount original installer ISO
        $isoPath = Join-Path $DOWNLOAD_DIR (Split-Path -Leaf $ORG_INSTALLER_ISO_URL)
        $isoPathAbsolute = (Resolve-Path $isoPath).Path
        Write-Host "Mounting $isoPathAbsolute"
        $mountResult = Mount-DiskImage $isoPathAbsolute -PassThru
        [string] $isoRoot = "$(($mountResult | Get-Volume).DriveLetter):"
        $isoIsMounted = $true
        Write-Host "ISO mounted to $isoRoot"

        # Copy files from ISO to ISO_FILES_DIR
        Write-Host "Copying files from ISO to $ISO_FILES_DIR"
        Copy-Item "$isoRoot\*" $ISO_FILES_DIR -Recurse -Force
        Write-Host "Removing readonly flag in $ISO_FILES_DIR"
        attrib -r $ISO_FILES_DIR\*.* /s

        # Mount install WIM
        $install_wim_path = Join-Path $ISO_FILES_DIR 'sources\install.wim'
        Write-Host "Mounting $install_wim_path to $WIM_MOUNT_DIR"
        & Dism.exe /Mount-WIM /WimFile:$install_wim_path /MountDir:$WIM_MOUNT_DIR /Index:$INSTALLER_WIM_INDEX /Quiet ; FailOnNativeError
        $wimIsMounted = $true

        # Todo: Modify WIM
    }
    finally {
        # Unmount installer WIM
        if ($wimIsMounted) {
            Write-Host "Unmounting installer WIM: $WIM_MOUNT_DIR"
            Dism /Unmount-WIM /MountDir:$WIM_MOUNT_DIR /Commit /Quiet
            Dismount-DiskImage -ImagePath $isoPathAbsolute | Out-Null
        }

        # Unmount original installer ISO
        if ($isoIsMounted) {
            Write-Host "Unmounting ISO: $isoPathAbsolute"
            Dismount-DiskImage -ImagePath $isoPathAbsolute | Out-Null
        }
    }
}


# Build install image
function BuildInstallImage {
    Write-Host '*** Create installer image'

    # Check for existing iso file
    if (Test-Path $CUSTOM_INSTALLER_ISO) {
        Write-Host "Removing existing image $CUSTOM_INSTALLER_ISO"
        Remove-Item $CUSTOM_INSTALLER_ISO -Force
    }

    Write-Host 'Create custom ISO image'
    & oscdimg.exe -m -u2 "-b$($ISO_FILES_DIR)\boot\etfsboot.com" $ISO_FILES_DIR $CUSTOM_INSTALLER_ISO ; FailOnNativeError
}

# Main function
function Main() {
    if ($SkipDownload) {
        # Skip downloading files
        Write-Host '*** Skipping downloads'
    }
    else {
        # Download installer files
        DownloadInstallerFiles
    }

    if ($DownloadOnly) {
        # Skip building image
        Write-Host '*** Skip building image'

        if ($downloadOccurred) {
            exit 10
        }
    }
    else {
        # Prepare install image files
        PrepareInstallImageFiles

        # Build install image
        BuildInstallImage
    }
    Write-Host '*** Done'
}


Main
