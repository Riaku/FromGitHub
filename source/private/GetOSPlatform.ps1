function GetOSPlatform {
    [CmdletBinding()]
    param(
        [switch]$Pattern
    )
    $ri = [System.Runtime.InteropServices.RuntimeInformation]
    $platform = [System.Runtime.InteropServices.OSPlatform]
    # if $ri isn't defined, then we must be running in Powershell 5.1, which only works on Windows.
    $OS = if (-not $ri -or $ri::IsOSPlatform($platform::Windows)) {
        "windows"
    } elseif ($ri::IsOSPlatform($platform::Linux)) {
        "linux"
    } elseif ($ri::IsOSPlatform($platform::OSX)) {
        "darwin"
    } elseif ($ri::IsOSPlatform($platform::FreeBSD)) {
        "freebsd"
    } else {
        throw "unsupported platform"
    }
    if ($Pattern) {
        Write-Information $OS
        switch ($OS) {
            "windows" { "windows|(?<!dar)win" }
            "linux" { "linux|unix" }
            "darwin" { "darwin|osx" }
            "freebsd" { "freebsd" }
        }
    } else {
        $OS
    }
}
