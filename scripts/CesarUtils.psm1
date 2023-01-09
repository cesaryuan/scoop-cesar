#Requires -Version 5.1
Set-StrictMode -Version 3.0
function PersistConfigWithJunction {
    <#
    .SYNOPSIS
        Persist config with junction. Handles the following cases:
        1. If there is no config_dir, create a junction from config_dir to persist_dir
        2. If there is a config_dir, and it's a junction to persist_dir, do nothing
        3. If there is a config_dir, and it's not a junction, move it's contents to persist_dir, and create a junction from config_dir to persist_dir
        4. If there is a config_dir, and it's a junction to a different path, move it's contents to persist_dir, and create a junction from config_dir to persist_dir

    .PARAMETER PersistDir
        The path to persist the config

    .PARAMETER ConfigDir
        The path to the config directory
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $PersistDir,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $ConfigDir
    )
    Write-Host "Persisting config from $ConfigDir to $PersistDir (Create junction)"

    # if ConfigDir is a junction to PersistDir, do nothing
    if ((Test-Path $ConfigDir) -and (isJunction $ConfigDir)) {
        $junction = Get-Item $ConfigDir
        if ($junction.Target -eq $PersistDir) {
            return
        }
    }
    # if we don't have a persist_dir, create one
    if (!(Test-Path $PersistDir)) {
        New-Item -ItemType Directory $PersistDir -Force
    }
    # if there is a config_dir, move it's contents to persist_dir
    # If there is a file with the same name in persist_dir, rename it to .original
    if (Test-Path $ConfigDir) {
        foreach ($item in Get-ChildItem $ConfigDir) {
            if(Test-Path "$PersistDir\$($item.Name)") {
                warn "File $($item.Name) already exists in persist Dir, renaming to $($item.Name).original"
                Move-Item -Force $item.FullName "$PersistDir\$($item.Name).original"
            } else {
                Move-Item -Force $item.FullName $PersistDir
            }
        }
        Remove-Item $ConfigDir
    }
    # create a junction from config_dir to persist_dir
    New-Item -ItemType Junction -Path $ConfigDir -Target $PersistDir -Force | Out-Null
}

function RemoveConfigJunction {
    <#
    .SYNOPSIS
        Remove config junction created by PersistConfigWithJunction. Handles the following cases:
        1. If there is no config_dir, do nothing
        2. If there is a config_dir, and it's a junction to persist_dir, remove the junction
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $PersistDir,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $ConfigDir
    )
    Write-Host "Removing junction from $ConfigDir to $PersistDir"
    if ((Test-Path $ConfigDir) -and (isJunction $ConfigDir)) {
        $junction = Get-Item $ConfigDir
        if ($junction.Target -eq $PersistDir) {
            Remove-Item $ConfigDir
        }
    }
}
function abort($msg, [int] $exit_code=1) { write-host $msg -f red; exit $exit_code }
function error($msg) { write-host "ERROR $msg" -f darkred }
function warn($msg) {  write-host "WARN $msg" -f darkyellow }
function success($msg) { write-host "$msg" -f darkgreen }

function isJunction($path) {
    if ((Get-Item -Path $path).LinkType -eq "Junction") {
        return $true
    }
    return $false
}
