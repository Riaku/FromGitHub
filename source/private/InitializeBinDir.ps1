function InitializeBinDir {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$BinDir,
        [switch]$Force
    )

    if (!$BinDir) {
        $BinDir = $(if ($IsLinux -or $IsMacOS) { '/usr/local/bin' }
                    elseif ($Env:LocalAppData) { "$Env:LocalAppData\Programs\Tools" }
                    else { "$HOME/.tools" })
    }

    if (!(Test-Path $BinDir)) {
        # First time use of $BinDir
        if ($Force -or $PSCmdlet.ShouldContinue("Create $BinDir and add to Path?", "$BinDir does not exist")) {
            New-Item -Type Directory -Path $BinDir | Out-Null
            if ($Env:PATH -split [IO.Path]::PathSeparator -notcontains $BinDir) {
                $Env:PATH += [IO.Path]::PathSeparator + $BinDir

                # If it's *not* Windows, $BinDir would be /usr/local/bin or something already in your PATH
                if (!$IsLinux -and !$IsMacOS) {
                    # But if it is Windows, we need to make the PATH change permanent
                    $PATH = [Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
                    $PATH += [IO.Path]::PathSeparator + $BinDir
                    [Environment]::SetEnvironmentVariable("PATH", $PATH, [EnvironmentVariableTarget]::User)
                }
            }
        } else {
            throw "Cannot install $Repo to $BinDir"
        }
    }
    $BinDir
}
