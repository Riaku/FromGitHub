function Test-FileHash {
    <#
        .SYNOPSIS
            Test the hash of a file against one or more checksum files or strings
        .DESCRIPTION
            Checksum files are assumed to have one line per file name, with the hash (or multiple hashes) on the line following the file name.

            In order to support installing yq (which has a checksum file with multiple hashes), this function handles checksum files with an ARRAY of valid checksums for each file name by searching the array for any matching hash.

            This isn't great, but an accidental pass is almost inconceivable, and determining the hash order is too complicated (given only one weird project does this so far).
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        # The path to the file to check the hash of
        [string]$Target,

        # The hash(es) or checksum(s) to compare to (can be one or more files, or one or more hash strings)
        [string[]]$Checksum
    )

    # If Checksum is a file, get the checksum from the file
    if (Test-Path $Checksum) {
        $basename = [Regex]::Escape([IO.Path]::GetFileName($Target))
        Write-Debug "Checksum is a file, getting checksum for $basename from $checksum"
        $Checksum = (Select-String -LiteralPath $Checksum -Pattern $basename).Line -split "\s+|=" -notmatch $basename
    }

    $Actual = (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash
    # Supports checksum files with an ARRAY of valid checksums (for different hash algorithms)
    # ... by searching the array for any matching hash (an accidental pass is almost inconceivable).
    [bool]($Checksum -eq $Actual)
    if ($Checksum -eq $Actual) {
        Write-Verbose "Checksum matches $Actual"
    } else {
        Write-Error "Checksum mismatch!`nValid: $Checksum`nActual: $Actual"
    }
}
