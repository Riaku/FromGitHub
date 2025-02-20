function Install-GitHubRelease {
    <#
    .SYNOPSIS
        Install a binary from a github release.
    .DESCRIPTION
        Cross-platform script to download, check file hash, and make sure the binary is on your PATH.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The user or organization that owns the repository
        [Parameter(Mandatory)]
        [Alias("User")]
        [string]$Org,

        # The name of the repository or project to download from
        [Parameter()]
        [string]$Repo,

        # The version of the release to download. Defaults to 'latest'
        [string]$Version = 'latest',

        # The operating system (will be detected, if not specified)
        $OS = (Get-OSPlatform -Pattern),

        # The architecture (will be detected, if not specified)
        $Architecture = (Get-OSArchitecture -Pattern),

        # The location to install to. Defaults to $Env:LocalAppData\Programs on Windows, /usr/local/bin on Linux/MacOS
        [string]$BinDir = $(if ($OS -notmatch "windows") { '/usr/local/bin' } elseif ($Env:LocalAppData) { "$Env:LocalAppData\Programs\Tools" } else { "$HOME/.tools" })
    )
    # A list of extensions in order of preference
    $extension = ".zip", ".tgz", ".tar.gz", ".exe"

    if (!$Repo) {
        $Org, $Repo = $Org.Split('/')
    }

    $release = Get-GitHubRelease -Org $Org -Repo $Repo -Tag $Version
    Write-Verbose "found release $($release.tag_name) for $org/$repo"

    $assets = $release.assets.where{ $_.name -match $OS -and $_.name -match $Architecture } |
        Select-Object *, @{ Name = "Extension"; Expr = { $_.name -replace '^[^.]+$', '' -replace ".*?((?:\.tar)?\.[^.]+$)", '$1' } } |
        Select-Object *, @{ Name = "Priority"; Expr = { if (($index = [array]::IndexOf($extension, $_.Extension)) -lt 0) { $index * -10 } else { $index } } } |
        Sort-Object Priority, Name

    if ($assets.Count -gt 1) {
        if ($asset = $assets.where({ $_.Extension -in $extension }, "First")) {
            Write-Warning "Found multiple available downloands for $OS/$Architecture`n $($assets| Format-Table name, Extension, b*url | Out-String)`nUsing $($asset.name)"
            # If it's not on windows, executables don't need an extesion
        } elseif ($os -notmatch "windows" -and ($asset = $assets.Where({ !$_.Extension }, "First", 0))) {
            Write-Warning "Found multiple available downloands for $OS/$Architecture`n $($assets| Format-Table name, Extension, b*url | Out-String)`nUsing $($asset.name)"
        } else {
            throw "Found multiple available downloands for $OS/$Architecture`n $($assets| Format-Table name, Extension, b*url | Out-String)`nUnable to detect usable release."
        }
    } elseif ($assets.Count -eq 0) {
        throw "No asset found for $OS/$Architecture`n $($release.assets.name -join "`n")"
    } else {
        $asset = $assets[0]
    }

    # Make a folder to unpack in
    $tempdir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    New-Item -Type Directory -Path $tempdir | Out-Null
    Push-Location $tempdir

    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $asset.name -Verbose:$false

    # There might be a checksum file
    $checksum = $release.assets.where{ $_.name -match "checksum|sha256sums" }[0]
    if ($checksum.Count -gt 0) {
        Write-Verbose "Found checksum file $($checksum.name)"
        Invoke-WebRequest -Uri $checksum.browser_download_url -OutFile $checksum.name -Verbose:$false

        if (!(Test-FileHash -Target $asset.name -Checksum $checksum.name)) {
            throw "Checksum mismatch for $($asset.name)"
        }
    } else {
        Write-Warning "No checksum file found for $($asset.name)"
    }

    # If it's an archive, expand it
    if ($asset.Extension -and $asset.Extension -ne ".exe") {
        $File = Get-Item $asset.name
        New-Item -Type Directory -Path $Repo | Convert-Path -OutVariable PackagePath | Set-Location
        Write-Verbose "Extracting $File to $PackagePath"

        if ($asset.Extension -eq ".zip") {
            Microsoft.PowerShell.Archive\Expand-Archive $File.FullName
        } else {
            if ($VerbosePreference -eq "Continue") {
                tar -xzvf $File.FullName
            } else {
                tar -xzf $File.FullName
            }
        }

        Set-Location $tempdir
    } else {
        Remove-Item $checksum.name
        $PackagePath = $tempdir
    }

    $Filter = @{ }
    if ($OS -match "windows") {
        $Filter.Include = @($ENV:PATHEXT -replace '\.', '*.' -split ';') + '*.exe'
    }

    if (!(Test-Path $BinDir)) {
        # First time use of $BinDir
        if ($Force -or $PSCmdlet.ShouldContinue("Create $BinDir and add to Path?", "$BinDir does not exist")) {
            New-Item -Type Directory -Path $BinDir | Out-Null
            if ($Env:PATH -split [IO.Path]::PathSeparator -notcontains $BinDir) {
                $Env:PATH += [IO.Path]::PathSeparator + $BinDir

                # If it's *not* Windows, $BinDir should be /usr/local/bin or something already in your PATH
                # Make the change permanent
                if ($OS -match "windows") {
                    $PATH = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
                    $PATH += [IO.Path]::PathSeparator + $BinDir
                    [Environment]::SetEnvironmentVariable("PATH", $PATH, [EnvironmentVariableTarget]::User)
                }
            }
        } else {
            throw "Cannot install $Repo to $BinDir"
        }
    }

    Write-Verbose "Moving files from $PackagePath"
    foreach ($File in Get-ChildItem $PackagePath -File -Recurse @Filter) {
        # Some teams (e.g. earthly/earthly), name the actual binary with the platform name, which is annoying
        if ($File.BaseName -match $OS -and $File.BaseName -match $Architecture ) {
            # $File = Rename-Item $File.FullName -NewName "$Repo$($_.Extension)" -PassThru
            if (!($NewName = ($File.BaseName -replace "[-_\.]*$OS" -replace "[-_\.]*$Architecture"))) {
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
        Write-Verbose "Moving $File to $BinDir"

        if ($OS -notmatch "windows" -and (Get-Item $BinDir -Force).Attributes -eq "ReadOnly,Directory") {
            sudo mv -f $File.FullName $BinDir
            sudo chmod +x "$BinDir/$($File.Name)"
        } else {
            if (Test-Path $BinDir/$($File.Name)) {
                Remove-Item $BinDir/$($File.Name) -Recurse -Force
            }
            $Executable = Move-Item $File.FullName -Destination $BinDir -Force -ErrorAction Stop -PassThru
            if ($OS -notmatch "windows") {
                chmod +x $Executable.FullName
            }
        }
    }

    Pop-Location

    Remove-Item $tempdir -Recurse
}
