@{
RootModule = 'FromGitHub.psm1'
ModuleVersion = '0.0.1'
GUID = '23addf96-d1d7-4f51-b97f-c4f0189263b6'
Author = "Joel 'Jaykul' Bennett"
CompanyName = 'HuddledMasses.org'
Copyright = '(c) Joel Bennett. All rights reserved.'
Description = 'Cross-platform installer for single-file executables from GitHub releases'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.4'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @()

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# List of all files packaged with this module
# FileList = @()

# HelpInfo URI of this module
# HelpInfoURI = ''

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("Installer","GitHub","Releases","Binaries","Linux","Windows","MacOS")

        # A URL to the license for this module.
        LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '
        '

        # Prerelease string of this module
        Prerelease = ''
    } # End of PSData hashtable
} # End of PrivateData hashtable
}

