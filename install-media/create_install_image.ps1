#Requires -Version 7 -RunAsAdministrator

param(
    # Directory where to find install files
    [Parameter(Mandatory = $true)]
    [string] $InstallFilesDir,

    # Directory where to place intermediate files
    [Parameter(Mandatory = $true)]
    [string] $WorkDir,

    # Path for output ISO file
    [Parameter(Mandatory = $true)]
    [string] $OutputIsoPath,

    # Pause before unmounting WIM
    [Parameter(Mandatory = $false)]
    [switch] $PauseBeforeWimUnmount

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

# Image index for installer.wim
$INSTALLER_WIM_INDEX = 1


# Fail on on native error
function FailOnNativeError() {
    if ($LASTEXITCODE -ne 0) {
        throw
    }
}


# Make empty directory
function MakeEmptyDir($path) {
    if (Test-Path $path) {
        # Remove existing items
        $items = Get-ChildItem $path
        foreach ($item in $items) {
            Remove-Item $item -Force -Recurse | Out-Null
        }
    }

    # Make sure directory exists
    mkdir $path -Force | Out-Null
}

# Get path to original installer iso
function GetOriginalIsoPath($isoDir) {
    [array]$items = Get-ChildItem (Join-Path $isoDir '*.iso')

    # No file found
    if ($null -eq $items) {
        throw "No original installer ISO file found (*.iso) in $isoDir"
    }
    # Too many files found
    if ($items.Count -gt 2) {
        throw "More than one original installer ISO file found (*.iso) in $isoDir"
    }
    return $items[0].FullName
}


# Prepare files for custom install image
function PrepareInstallImageFiles($isoFilesDir, $wimMountDir, $originalIsoPath) {
    Write-Host '** Preparing files for install image'

    # Indicate mounted ISO
    $isoIsMounted = $false

    # Indicate mounted WIM
    $wimIsMounted = $false

    try {
        # Make sure required directories exist and are empty
        Write-Host "Creating empty dir for ISO files: $isoFilesDir"
        MakeEmptyDir $isoFilesDir
        Write-Host "Creating empty dir for mounting installer WIM: $wimMountDir"
        MakeEmptyDir $wimMountDir

        # Mount original installer ISO
        $isoPathAbsolute = (Resolve-Path $originalIsoPath).Path
        Write-Host "Mounting $isoPathAbsolute"
        $mountResult = Mount-DiskImage $isoPathAbsolute -PassThru
        [string] $isoRoot = "$(($mountResult | Get-Volume).DriveLetter):"
        $isoIsMounted = $true
        Write-Host "ISO mounted to $isoRoot"

        # Copy files from ISO to ISO_FILES_DIR
        Write-Host "Copying files from ISO to $isoFilesDir"
        Copy-Item "$isoRoot\*" $isoFilesDir -Recurse -Force
        Write-Host "Removing readonly flag in $isoFilesDir"
        & attrib -r $isoFilesDir\*.* /s ; FailOnNativeError

        # Mount install WIM
        $install_wim_path = Join-Path $isoFilesDir 'sources\install.wim'
        Write-Host "Mounting $install_wim_path to $wimMountDir"
        & Dism.exe /Mount-WIM /WimFile:$install_wim_path /MountDir:$wimMountDir /Index:$INSTALLER_WIM_INDEX /Quiet ; FailOnNativeError
        $wimIsMounted = $true

        # Update image
        UpdateImage $wimMountDir

        # Wait for unmount
        if ($PauseBeforeWimUnmount) {
            Read-Host 'Press ENTER to continue'
        }
    }
    finally {
        # Unmount installer WIM
        $counter = 5
        while ($wimIsMounted) {
            Write-Host "Unmounting installer WIM: $wimMountDir"
            Dism /Unmount-WIM /MountDir:$wimMountDir /Commit /Quiet
            if ($LASTEXITCODE -eq 0) {
                Write-Host 'Unmounting installer WIM succeeded'
                $wimIsMounted = $false
                break
            }
            $counter--
            if ($counter -eq 0) {
                throw 'Too many WIM unmount retries, exiting'
            }
            Write-Host 'WIM unmount failed, retrying...'
            Start-Sleep -Seconds 5
        }

        # Unmount original installer ISO
        if ($isoIsMounted) {
            Write-Host "Unmounting ISO: $isoPathAbsolute"
            Dismount-DiskImage -ImagePath $isoPathAbsolute | Out-Null
            Write-Host 'Unmounting ISO succeeded'
        }
    }
    Write-Host '** Done: Preparing files for install image'
}


# Update image
function UpdateImage($wimMountDir) {

    # Update registry hive SYSTEM
    Write-Host '** Updating registry hive SYSTEM'
    Write-Host '* Loading hive SYSTEM'
    & reg load HKLM\TempHive "$wimMountDir\Windows\System32\config\SYSTEM" ; FailOnNativeError
    try {
        Write-Host '* Setting RealTimeIsUniversal'
        & reg add 'HKLM\TempHive\ControlSet001\Control\TimeZoneInformation' /v RealTimeIsUniversal /t REG_DWORD /d 1 /f ; FailOnNativeError
        & reg add 'HKLM\TempHive\ControlSet002\Control\TimeZoneInformation' /v RealTimeIsUniversal /t REG_DWORD /d 1 /f ; FailOnNativeError
    }
    finally {
        Write-Host '* Unloading hive SYSTEM'
        & reg unload HKLM\TempHive ; FailOnNativeError
    }
    Write-Host '** Done: Updating registry hive SYSTEM'
}


# Create image file
function CreateImageFile($isoFilesDir, $isoPath) {
    Write-Host '** Creating image file'

    # Check for existing iso file
    if (Test-Path $isoPath) {
        Write-Host "Removing existing image $isoPath"
        Remove-Item $isoPath -Force
    }

    Write-Host "Creating custom ISO image: $isoPath"
    & oscdimg.exe -m -u2 "-b$($isoFilesDir)\boot\etfsboot.com" $isoFilesDir $isoPath ; FailOnNativeError
    Write-Host '** Done: Creating image file'
}


# Main function
function Main() {
    Write-Host '*** Creating install image'

    # Directory for ISO files
    $isoFilesDir = Join-Path $WorkDir 'iso'

    # Directory for mounting installer WIM
    $wimMountDir = Join-Path $WorkDir 'wim'

    # Get path to original installer ISO
    $originalIsoPath = GetOriginalIsoPath $InstallFilesDir

    # Prepare install image files
    PrepareInstallImageFiles $isoFilesDir $wimMountDir $originalIsoPath

    # Create image file
    CreateImageFile $isoFilesDir $OutputIsoPath

    Write-Host '*** Done: Creating install image'
}


Main
