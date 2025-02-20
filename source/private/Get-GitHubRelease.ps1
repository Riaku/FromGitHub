function Get-GitHubRelease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [Alias("User")]
        [string]$Org,

        [Parameter(Mandatory, Position = 1)]
        [string]$Repo,

        [Parameter(Position = 2)]
        [Alias("Version")]
        [string]$Tag = 'latest'
    )

    Write-Debug "Checking GitHub for tag '$tag'"

    $result = if ($tag -eq 'latest') {
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/releases/$tag" -Headers @{Accept = 'application/json' } -Verbose:$false
    } else {
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/releases/tags/$tag" -Headers @{Accept = 'application/json' } -Verbose:$false
    }

    Write-Debug "Found tag '$($result.tag_name)' for $tag"
    $result
}