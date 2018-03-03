
param(
    $Artifacts = '.\artifacts',
    $ModuleName = "ModuleTemplate",
    $ModulePath = '.\ModuleTemplate',
    $BuildNumber = $env:BUILD_NUMBER,
    $PercentCompliance = '50'
)

$ProjectRoot = $ENV:BHProjectPath

if (-not $ProjectRoot) {
    $ProjectRoot = $PSScriptRoot
}

task Default Clean, Analyze, RunTests, ConfirmTestsPassed, Publish

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
    
    Invoke-Expression -Command (New-Object 'System.Net.WebClient').DownloadString('https://raw.githubusercontent.com/MathieuBuisson/PowerShell-DevOps/master/Export-NUnitXml/Export-NUnitXml.psm1')
    
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

    [xml] $testResultsXml = Get-Content (Join-Path $Artifacts "TestResults.xml")
    $numberFails = $testResultsXml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" Pester tests.' -f $numberFails)

    [xml] $scriptAnalyzerXml = Get-Content (Join-Path $Artifacts "ScriptAnalyzerResults.xml")
    $numberFails = $scriptAnalyzerXml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" ScriptAnalyzer rules.' -f $numberFails)

    $pesterJson = Get-Content (Join-Path $Artifacts "PesterResults.json") | ConvertFrom-Json
    $overallCoverage = [Math]::Floor(($pesterJson.CodeCoverage.NumberOfCommandsExecuted / $pesterJson.CodeCoverage.NumberOfCommandsAnalyzed) * 100)
    assert($OverallCoverage -gt $PercentCompliance) ('A Code Coverage of "{0}" does not meet the build requirement of "{1}"' -f $overallCoverage, $PercentCompliance)

}

task Publish {

    Set-ModuleFunctions

    $Version = Get-NextNugetPackageVersion -Name $env:BHProjectName

    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $Version

    $psdeployParams = @{
        Path = $ProjectRoot
        Force = $true
    }

   if ( $ENV:BHBuildSystem -eq 'AppVeyor' ) {
        Get-ChildItem -Path $Artifacts -Filter '*Results*.xml' -File | ForEach-Object {
            (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", "$($_.FullName)")
        }

        Invoke-PSDeploy @psdeployParams
    }

}