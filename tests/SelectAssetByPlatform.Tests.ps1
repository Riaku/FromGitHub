Describe SelectAssetByPlatform {
    BeforeDiscovery {

        $TestCases = @(
            @{ OS = "darwin|osx"; Architecture = "arm64"; Expected = "conftest_0.60.0_Darwin_arm64.tar.gz" }
            @{ OS = "darwin|osx"; Architecture = "amd64|x64|x86_64"; Expected = "conftest_0.60.0_Darwin_x86_64.tar.gz" }
            @{ OS = "linux|unix"; Architecture = "amd64|x64|x86_64"; Expected = "conftest_0.60.0_Linux_x86_64.tar.gz" }
            @{ OS = "windows|(?<!dar)win"; Architecture = "amd64|x64|x86_64"; Expected = "conftest_0.60.0_Windows_x86_64.zip" }
            @{ OS = "windows|(?<!dar)win"; Architecture = "arm64"; Expected = "conftest_0.60.0_Windows_arm64.zip" }
        )
    }
    BeforeAll {
        $CommandUnderTest = InModuleScope -ModuleName 'FromGitHub' { Get-Command 'SelectAssetByPlatform' }
        $ConfTest = @(
            @{ name="conftest_0.60.0_Darwin_arm64.tar.gz" }
            @{ name="conftest_0.60.0_Darwin_x86_64.tar.gz" }
            @{ name="conftest_0.60.0_linux_amd64.deb" }
            @{ name="conftest_0.60.0_linux_amd64.rpm" }
            @{ name="conftest_0.60.0_linux_arm64.deb" }
            @{ name="conftest_0.60.0_linux_arm64.rpm" }
            @{ name="conftest_0.60.0_Linux_arm64.tar.gz" }
            @{ name="conftest_0.60.0_linux_ppc64le.deb" }
            @{ name="conftest_0.60.0_linux_ppc64le.rpm" }
            @{ name="conftest_0.60.0_Linux_ppc64le.tar.gz" }
            @{ name="conftest_0.60.0_linux_s390x.deb" }
            @{ name="conftest_0.60.0_linux_s390x.rpm" }
            @{ name="conftest_0.60.0_Linux_s390x.tar.gz" }
            @{ name="conftest_0.60.0_Linux_x86_64.tar.gz" }
            @{ name="conftest_0.60.0_Windows_arm64.zip" }
            @{ name="conftest_0.60.0_Windows_x86_64.zip" }
        )
    }

    It "Selects the correct asset for <OS> on <Architecture>" -ForEach $TestCases {

        &$CommandUnderTest -assets $ConfTest -OS $OS -Architecture $Architecture -Verbose
        | Assert-All { $_.name -eq $Expected }

    }
}
