﻿
param (
    $Artifacts = '.\artifacts',
    $ModuleName = "ModuleTemplate",
    $ModulePath = '.\ModuleTemplate',
    #$BuildNumber = $env:BUILD_NUMBER,
    $BuildNumber = 1.0.0,
    $PercentCompliance = '50'
)

task . Clean, Analyze, RunTests, ConfirmTestsPassed, Package, Publish

task Clean {

    if ( Test-Path -Path $Artifacts ) {
        Remove-Item "$Artifacts/*" -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $Artifacts -Force
    }

}

task Analyze {

    $scriptAnalyzerParams = @{
        Path = $ModulePath
        ExcludeRule = @('PSPossibleIncorrectComparisonWithNull', 'PSUseToExportFieldsInManifest')
        Severity = @('Error', 'Warning')
        Recurse = $true
        Verbose = $false
    }

    $scriptAnalyzerResults = Invoke-ScriptAnalyzer @scriptAnalyzerParams

    $scriptAnalyzerResultsPath = (Join-Path $Artifacts "ScriptAnalyzerResults.xml")
    
    $webClient = New-Object 'System.Net.WebClient'
    Invoke-Expression -Command $webClient.DownloadString('https://raw.githubusercontent.com/MathieuBuisson/PowerShell-DevOps/master/Export-NUnitXml/Export-NUnitXml.psm1')
    
    Export-NUnitXml -ScriptAnalyzerResult $ScriptAnalyzerResult -Path $scriptAnalyzerResultsPath

}

task RunTests {

    $invokePesterParams = @{
        OutputFile = (Join-Path $Artifacts "TestResults.xml")
        OutputFormat = "NUnitXml"
        Strict = $true
        PassThru = $true
        Verbose = $false
        EnableExit = $false
        CodeCoverage = (Get-ChildItem -Path "$ModulePath\*.ps1" -Exclude "*.Tests.*" -Recurse).FullName
    }

    $testResults = Invoke-Pester @invokePesterParams

    $testResults | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $Artifacts "PesterResults.json")

}

task ConfirmTestsPassed {

    [xml]$testResultsXml = Get-Content (Join-Path $Artifacts "TestResults.xml")
    $numberFails = $testResultsXml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" Pester tests.' -f $numberFails)

    [xml]$scriptAnalyzerXml = Get-Content (Join-Path $Artifacts "ScriptAnalyzerResults.xml")
    $numberFails = $scriptAnalyzerXml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" ScriptAnalyzer rules.' -f $numberFails)

    $pesterJson = Get-Content (Join-Path $Artifacts "PesterResults.json") | ConvertFrom-Json
    $overallCoverage = [Math]::Floor(($pesterJson.CodeCoverage.NumberOfCommandsExecuted / $pesterJson.CodeCoverage.NumberOfCommandsAnalyzed) * 100)
    assert($OverallCoverage -gt $PercentCompliance) ('A Code Coverage of "{0}" does not meet the build requirement of "{1}"' -f $overallCoverage, $PercentCompliance)

}

task Package {

    Register-PSRepository -Name Artifacts -SourceLocation (Resolve-Path $Artifacts).Path -PublishLocation (Resolve-Path $Artifacts).Path -InstallationPolicy Trusted

    Publish-Module -Path (Resolve-Path $ModulePath).Path -Repository Artifacts -NuGetApiKey 'Nothing'

    UnRegister-PSRepository -Name Artifacts

}

task Publish {

    $testResultsPath = (Join-Path $Artifacts "TestResults.xml")
    $webClient = New-Object 'System.Net.WebClient'
    $webClient.UploadFile("https://ci.appveyor.com/api/testresults/xunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsPath | Select-Object -ExpandProperty Path) )

    $scriptAnalyzerResultsPath = (Join-Path $Artifacts "ScriptAnalyzerResults.xml")
    $webClient = New-Object 'System.Net.WebClient'
    $webClient.UploadFile("https://ci.appveyor.com/api/testresults/xunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $scriptAnalyzerResultsPath | Select-Object -ExpandProperty Path) )

}