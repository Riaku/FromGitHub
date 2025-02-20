function Get-OSArchitecture {
    [CmdletBinding()]
    param(
        [switch]$Pattern
    )

    # PowerShell Core
    $Architecture = if (($arch = "$([Runtime.InteropServices.RuntimeInformation]::OSArchitecture)")) {
        $arch
        # Legacy Windows PowerShell
    } elseif ([Environment]::Is64BitOperatingSystem) {
        "X64";
    } else {
        "X86";
    }
    # Optionally, turn this into a regex pattern that usually works
    if ($Pattern) {
        Write-Information $arch
        switch ($arch) {
            "Arm" { "arm(?!64)" }
            "Arm64" { "arm64" }
            "X86" { "x86|386" }
            "X64" { "amd64|x64|x86_64" }
        }
    } else {
        $arch
    }
}
