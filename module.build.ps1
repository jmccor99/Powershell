
$projectRoot = $ENV:BHProjectPath

task Default Clean, Analyze, RunTests, ConfirmTestsPassed, Publish

task Clean {

    if ( Test-Path -Path $Artifacts ) {
        Remove-Item -Path "$Artifacts\*" -Recurse -Force
    } else {
        New-Item -ItemType Directory -Path $Artifacts -Force | Out-Null
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

    $scriptAnalyzerResultsPath = (Join-Path -Path $Artifacts -ChildPath "ScriptAnalyzerResults.xml")
    
    Invoke-Expression -Command (New-Object -TypeName 'System.Net.WebClient').DownloadString('https://raw.githubusercontent.com/MathieuBuisson/PowerShell-DevOps/master/Export-NUnitXml/Export-NUnitXml.psm1')
    
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

    $testResults | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path -Path $Artifacts -ChildPath "PesterResults.json")

}

task ConfirmTestsPassed {

    [xml] $testResultsXml = Get-Content -Path (Join-Path -Path $Artifacts -ChildPath "TestResults.xml")
    $numberFails = $testResultsXml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" Pester tests.' -f $numberFails)

    [xml] $scriptAnalyzerXml = Get-Content -Path (Join-Path -Path $Artifacts -ChildPath "ScriptAnalyzerResults.xml")
    $numberFails = $scriptAnalyzerXml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" ScriptAnalyzer rules.' -f $numberFails)

    $pesterJson = Get-Content -Path (Join-Path -Path $Artifacts -ChildPath "PesterResults.json") | ConvertFrom-Json
    $overallCoverage = [Math]::Floor(($pesterJson.CodeCoverage.NumberOfCommandsExecuted / $pesterJson.CodeCoverage.NumberOfCommandsAnalyzed) * 100)
    assert($OverallCoverage -gt $PercentCompliance) ('A Code Coverage of "{0}" does not meet the build requirement of "{1}"' -f $overallCoverage, $PercentCompliance)

}

task Publish {

    if (
        $ENV:BHBuildSystem -eq "AppVeyor" -and
        $ENV:BHBranchName -eq "master"   -and
        $ENV:BHCommitMessage -match "!deploy"
    ) {
        $Version = Get-NextNugetPackageVersion -Name $env:BHProjectName
        Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $Version

        Get-ChildItem -Path $Artifacts -Filter '*Results*.xml' -File | ForEach-Object {
            (New-Object -TypeName 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", "$($_.FullName)")
        }

        $psdeployParams = @{
            Path = $ProjectRoot
            Force = $true
        }

        Invoke-PSDeploy @psdeployParams

    } else {
        "Skipping deployment: To deploy, ensure that...`n" +
        "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
        "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
        "`t* Your commit message includes !deploy (Current: $ENV:BHCommitMessage)"
    }

}