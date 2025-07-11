# Use this file to override the default parameter values used by the `Build-Module`
# command when building the module (see `Get-Help Build-Module -Full` for details).
@{
    ModuleManifest           = "./source/FromGitHub.psd1"
    OutputDirectory          = "../Modules"
    VersionedOutputDirectory = $true
    Generators               = @(
        @{ Generator = "ConvertTo-Script"; Function = "Install-FromGitHub"; GUID = '23addf96-d1d7-4f51-b97f-c4f0189263b6' }
    )
}
