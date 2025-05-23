function SelectAssetByPlatform {
    # DO NOT USE `[CmdletBinding()]` or [Parameter()]
    # We splat the parameters from Install-GitHubRelease and we need to ignore the extras
    param(
        $Assets,

        # A regex pattern to selecting the right asset for this OS
        [string]$OS,

        # A regex patter to select the right asset for this architecture
        [string]$Architecture
    )
    # Order the list of available asses in this order of preference (basically, choose an archive over an installer)
    $extension = ".zip", ".tgz", ".tar.gz", ".exe"
    $MatchedAssets = $assets.where{ $_.name -match $OS -and $_.name -match $Architecture } |
        # I need both the Extension and the Priority on the final object for the logic below
        # I'll put the extension on, and then use that to calculate the priority
        # It would be faster (but ugly) to use a single Select-Object, but compared to downloading and unzipping, that's irrelevant
        Select-Object *, @{ Name = "Extension"; Expr = { $_.name -replace '^[^.]+$', '' -replace ".*?((?:\.tar)?\.[^.]+$)", '$1' } } |
        Select-Object *, @{ Name = "Priority"; Expr = { if (($index = [array]::IndexOf($extension, $_.Extension)) -lt 0) { $index * -10 } else { $index } } } |
        Sort-Object Priority, Name

    if ($MatchedAssets.Count -gt 1) {
        if ($asset = $MatchedAssets.where({ $_.Extension -in $extension }, "First")) {
            Write-Warning "Found multiple available downloads for $OS/$Architecture`n $($MatchedAssets| Format-Table name, Extension, b*url | Out-String)`nUsing $($asset.name)"
            # If it's not windows, executables don't need an extesion
        } elseif ($os -notmatch "windows" -and ($asset = $MatchedAssets.Where({ !$_.Extension }, "First", 0))) {
            Write-Warning "Found multiple available downloads for $OS/$Architecture`n $($MatchedAssets| Format-Table name, Extension, b*url | Out-String)`nUsing $($asset.name)"
        } else {
            throw "Found multiple available downloads for $OS/$Architecture`n $($MatchedAssets| Format-Table name, Extension, b*url | Out-String)`nUnable to detect usable release."
        }
    } elseif ($MatchedAssets.Count -eq 0) {
        throw "No asset found for $OS/$Architecture`n $($Assets.name -join "`n")"
    } else {
        $asset = $MatchedAssets[0]
    }
    # Check for a match-specific checksum file
    if( ($sha = $MatchedAssets.Where({$_.name -match "checksum|sha256sums|sha"}, "First")) -or
        # or a single checksum file for all assets
        ($sha = $assets.Where({$_.name -match "checksum|sha256sums|sha"}, "First"))) {
        Write-Verbose "Found checksum file $($sha.browser_download_url) for $($asset.name)"
        # Add that url to the asset object
        $asset | Add-Member -NotePropertyMember @{ ChecksumUrl = $sha.browser_download_url }
    }
    $asset
}
