#Requires -Version 5.1
Set-StrictMode -Version 3.0
function PersistCustomConfig {
    <#
    .SYNOPSIS
        Persist Custom Config

    .PARAMETER PersistDir
        The source path, which is the persist_dir

    .PARAMETER ConfigDir
        The target path, which is the actual path app uses to store the config
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $PersistDir,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $ConfigDir
    )
    Write-Host "Persisting custom config from $ConfigDir to $PersistDir"
    # if ConfigDir is a junction to PersistDir, do nothing
    if (Test-Path $ConfigDir -PathType Junction) {
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
    New-Item -ItemType Junction -Path $ConfigDir -Target $PersistDir -Force
}

function RemoveConfigJunction {
    <#
    .SYNOPSIS
        Remove Junction
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Junction
    )
    # if it's a junction, remove it
    if (!(Test-Path $Junction)) {
        return
    }
    if (Test-Path $Junction -PathType Junction) {
        Remove-Item $Junction -Force
    }
}
function abort($msg, [int] $exit_code=1) { write-host $msg -f red; exit $exit_code }
function error($msg) { write-host "ERROR $msg" -f darkred }
function warn($msg) {  write-host "WARN  $msg" -f darkyellow }
function success($msg) { write-host "$msg" -f darkgreen }
