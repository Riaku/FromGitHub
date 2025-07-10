Describe RealWorldFailureAzureBicep {
    BeforeDiscovery {

        $TestCases = @(
            @{ OS = "darwin|osx"; Architecture = "arm64"; Expected = "bicep-osx-arm64" }
            @{ OS = "darwin|osx"; Architecture = "amd64|x64|x86_64"; Expected = "bicep-osx-x64" }
            @{ OS = "linux|unix"; Architecture = "amd64|x64|x86_64"; Expected = "bicep-linux-x64" }
            @{ OS = "windows|(?<!dar)win"; Architecture = "amd64|x64|x86_64"; Expected = "bicep-win-x64.exe" }
            @{ OS = "windows|(?<!dar)win"; Architecture = "arm64"; Expected = "bicep-win-arm64.exe" }
        )
    }

    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'SelectAssetByPlatform' }
        $ConfTest = @(
            @{ name="Azure.Bicep.CommandLine.linux-arm64.0.36.177.nupkg" }
            @{ name="Azure.Bicep.CommandLine.linux-x64.0.36.177.nupkg" }
            @{ name="Azure.Bicep.CommandLine.osx-arm64.0.36.177.nupkg" }
            @{ name="Azure.Bicep.CommandLine.osx-x64.0.36.177.nupkg" }
            @{ name="Azure.Bicep.CommandLine.win-arm64.0.36.177.nupkg" }
            @{ name="Azure.Bicep.CommandLine.win-x64.0.36.177.nupkg" }
            @{ name="Azure.Bicep.Core.0.36.177.nupkg" }
            @{ name="Azure.Bicep.Core.0.36.177.snupkg" }
            @{ name="Azure.Bicep.Decompiler.0.36.177.nupkg" }
            @{ name="Azure.Bicep.Decompiler.0.36.177.snupkg" }
            @{ name="Azure.Bicep.IO.0.36.177.nupkg" }
            @{ name="Azure.Bicep.IO.0.36.177.snupkg" }
            @{ name="Azure.Bicep.Local.Extension.0.36.177.nupkg" }
            @{ name="Azure.Bicep.Local.Extension.0.36.177.snupkg" }
            @{ name="Azure.Bicep.MSBuild.0.36.177.nupkg" }
            @{ name="Azure.Bicep.MSBuild.0.36.177.snupkg" }
            @{ name="Azure.Bicep.RegistryModuleTool.0.36.177.nupkg" }
            @{ name="Azure.Bicep.RegistryModuleTool.0.36.177.snupkg" }
            @{ name="bicep-langserver.zip" }
            @{ name="bicep-linux-arm64" }
            @{ name="bicep-linux-musl-x64" }
            @{ name="bicep-linux-x64" }
            @{ name="bicep-osx-arm64" }
            @{ name="bicep-osx-x64" }
            @{ name="bicep-setup-win-x64.exe" }
            @{ name="bicep-win-arm64.exe" }
            @{ name="bicep-win-x64.exe" }
            @{ name="vs-bicep.vsix" }
            @{ name="vscode-bicep.vsix" }
        )
    }

    It "Selects the correct asset for <OS> on <Architecture>" -ForEach $TestCases {

        &$CommandUnderTest -assets $ConfTest -OS $OS -Architecture $Architecture -Verbose
        | Assert-All { $_.name -eq $Expected }

    }
}
