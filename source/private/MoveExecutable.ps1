function MoveExecutable {
    # DO NOT USE `[CmdletBinding()]` or [Parameter()]
    # We splat the parameters from Install-GitHubRelease and we need to ignore the extras
    param(
        [string]$FromDir,

        [Alias("TargetDirectory")]
        [string]$ToDir,

        # A regex pattern to selecting the right asset for this OS
        [string]$OS,

        # A regex patter to select the right asset for this architecture
        [string]$Architecture
    )
    $Filter = @{ }
    if (!$IsLinux -and !$IsMacOS) {
        # On Windows, it must have an executable extension
        # PATHEXT are all the executable extensions, but we redundantly add EXE just in case
        $Filter.Include = @($ENV:PATHEXT -replace '\.', '*.' -split ';') + '*.exe'
    }
    foreach ($File in Get-ChildItem $FromDir -File -Recurse @Filter) {
        # Some teams (e.g. earthly/earthly), don't use a zip, so they name the actual binary with the platform name
        # We do not want to type earthly_win64.exe every time, so rename to the base name...
        if ($File.BaseName -match $OS -or $File.BaseName -match $Architecture ) {
            # $File = Rename-Item $File.FullName -NewName "$Repo$($_.Extension)" -PassThru
            if (!($NewName = ($File.BaseName -replace "[-_\.]*(?:$OS)" -replace "[-_\.]*(?:$Architecture)"))) {
                $NewName = $Repo
            }
            $NewName += $File.Extension
            Write-Warning "Renaming $File to $NewName"
            $File = Rename-Item $File.FullName -NewName $NewName -PassThru
        }
        # Some few teams include the docs with their package (e.g. opentofu)
        if ($File.BaseName -match "README|LICENSE|CHANGELOG" -or $File.Extension -in ".md", ".rst", ".txt", ".asc", ".doc" ) {
            Write-Verbose "Skipping doc $File"
            continue
        }
        Write-Verbose "Moving $File to $ToDir"

        # On non-Windows systems, we might need sudo to copy (if the folder is write protected)
        if ($OS -notmatch "windows" -and (Get-Item $ToDir -Force).Attributes -eq "ReadOnly,Directory") {
            sudo mv -f $File.FullName $ToDir
            sudo chmod +x "$ToDir/$($File.Name)"
        } else {
            if (Test-Path $ToDir/$($File.Name)) {
                Remove-Item $ToDir/$($File.Name) -Recurse -Force
            }
            $Executable = Move-Item $File.FullName -Destination $ToDir -Force -ErrorAction Stop -PassThru
            if ($OS -notmatch "windows") {
                chmod +x $Executable.FullName
            }
        }
        # Output the moved item, because sometimes our "using someearthl_version_win64.zip" message is confusing
        Get-Item (Join-Path $ToDir $File.Name) -ErrorAction Ignore
    }
}
