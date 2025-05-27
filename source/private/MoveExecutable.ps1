function MoveExecutable {
    # Some teams (e.g. earthly/earthly), name the actual binary with the platform name
    # We do not want to type earthly_win64.exe every time, so rename to the base name...
    # DO NOT USE `[CmdletBinding()]` or [Parameter()]
    # We splat the parameters from Install-GitHubRelease and we need to ignore the extras
    param(
        [string]$FromDir,

        [Alias("TargetDirectory")]
        [string]$ToDir,

        # A regex pattern to select the right asset for this OS
        [string]$OS,

        # A regex pattern to select the right asset for this architecture
        [string]$Architecture,

        # An explicit user-supplied name for the executable
        [string]$ExecutableName,

        # The name of the repository, as a fallback for the executable name
        [string]$Repo,

        # For testing purposes, override OS detection
        [switch]$IsPosix = $IsLinux -or $IsMacOS
    )
    $AllFiles = Get-ChildItem $FromDir -File -Recurse
    if ($AllFiles.Count -eq 0) {
        Write-Warning "No executables found in $FromDir"
        return
    }

    $Extensions = @(if (!$IsPosix) {
            # On Windows, only rename it if  has an executable extension
            @($ENV:PATHEXT -split ';') + '.EXE'
        })

    foreach ($File in $AllFiles) {
        $NewName = $File.Name
        # When there is a manually specified executable name, we use that
        if ($ExecutableName) {
            # Make sure the executable name has the right extension
            if ($File.Extension) {
                $ExecutableName = [IO.Path]::ChangeExtension($ExecutableName, $File.Extension)
            }
            # If there is only one file, definitely rename it even if it's unique
            if ($AllFiles.Count -eq 1) {
                $NewName = $ExecutableName
            }
        }
        # Normally, we only rename the file if it has the OS and/or Architecture in the name (and is executable)
        if ($File.BaseName -match $OS -or $File.BaseName -match $Architecture -and ($Extensions.Count -eq 0 -or $File.Extension -in $Extensions)) {
            # Try just removing the OS and Architecture from the name
            if (($NewName = ($File.BaseName -replace "[-_. ]*(?:$OS)[-_. ]*" -replace "[-_. ]*(?:$Architecture)[-_. ]*"))) {
                $NewName = $NewName.Trim("-_. ") + $File.Extension
                # Otherwise, fall back to the repo name
            } elseif ($ExecutableName) {
                $NewName = $ExecutableName
            } else {
                $NewName = $Repo.Trim("-_. ") + $File.Extension
            }
        }
        if ($NewName -ne $File.Name) {
            Write-Warning "Renaming $File to $NewName"
            $File = Rename-Item $File.FullName -NewName $NewName -PassThru
        }

        # Some few teams include the docs with their package (e.g. opentofu)
        # And I want the user to know these files were available, but not move them
        if ($File.BaseName -match "README|LICENSE|CHANGELOG" -or $File.Extension -in ".md", ".rst", ".txt", ".asc", ".doc" ) {
            Write-Verbose "Skipping doc $File"
            continue
        }
        Write-Verbose "Moving $File to $ToDir"

        # On non-Windows systems, we might need sudo to copy (if the folder is write protected)
        if ($IsPosix -and (Get-Item $ToDir -Force).Attributes -eq "ReadOnly,Directory") {
            sudo mv -f $File.FullName $ToDir
            sudo chmod +x "$ToDir/$($File.Name)"
        } else {
            if (Test-Path $ToDir/$($File.Name)) {
                Remove-Item $ToDir/$($File.Name) -Recurse -Force
            }
            $Executable = Move-Item $File.FullName -Destination $ToDir -Force -ErrorAction Stop -PassThru
            if ($IsPosix) {
                chmod +x $Executable.FullName
            }
        }
        # Output the moved item, because sometimes our "using someearthly_version_win64.zip" message is confusing
        Get-Item (Join-Path $ToDir $File.Name) -ErrorAction Ignore
    }
}
