
$parentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

$paramsPathBuildSettings = @{
    Path      =  $parentPath
    ChildPath = "build.settings.ps1"
}

$pathBuildSettings = Join-Path @paramsPathBuildSettings

. $pathBuildSettings

#Synopsis: Run Tests and Fail Build on Error.
task . Clean, Analyze, RunTests, ConfirmTestsPassed

#Synopsis: Clean Artifact directory.
task Clean {
    
    if (Test-Path -Path $Artifacts) {
        Remove-Item "$Artifacts/*" -Recurse -Force
    }

    New-Item -ItemType Directory -Path $Artifacts -Force
    
}

#Synopsis: Analyze code.
task Analyze {
    $scriptAnalyzerParams = @{
        Path = $ModulePath
        ExcludeRule = @('PSPossibleIncorrectComparisonWithNull', 'PSUseToExportFieldsInManifest')
        Severity = @('Error', 'Warning')
        Recurse = $true
        Verbose = $false
    }

    $ScriptAnalyzerResult = Invoke-ScriptAnalyzer @scriptAnalyzerParams

    If ( $ScriptAnalyzerResult ) {  
        $ScriptAnalyzerResultString = $ScriptAnalyzerResult | Out-String
        Write-Warning $ScriptAnalyzerResultString
    }

    $scriptAnalyzerResultPath = (Join-Path $Artifacts "ScriptAnalyzerResult.xml")

    iex (new-object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/MathieuBuisson/PowerShell-DevOps/master/Export-NUnitXml/Export-NUnitXml.psm1')
    Export-NUnitXml -ScriptAnalyzerResult $ScriptAnalyzerResult -Path $scriptAnalyzerResultPath
   
    # upload results to AppVeyor
    $wc = New-Object 'System.Net.WebClient'
    $wc.UploadFile("https://ci.appveyor.com/api/testresults/xunit/$($env:APPVEYOR_JOB_ID)", $scriptAnalyzerResultPath"
    
    If ( $ScriptAnalyzerResult ) {        
        # Failing the build
        Throw 'There was PSScriptAnalyzer violation(s). See test results for more information.'
    }
}

#Synopsis: Run tests.
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

#Synopsis: Confirm that tests passed.
task ConfirmTestsPassed {
    # Fail Build after reports are created, this allows CI to publish test results before failing
    [xml]$xml = Get-Content (Join-Path $Artifacts "TestResults.xml")
    $numberFails = $xml."test-results".failures
    assert($numberFails -eq 0) ('Failed "{0}" unit tests.' -f $numberFails)

    # Fail Build if Coverage is under requirement
    $json = Get-Content (Join-Path $Artifacts "PesterResults.json") | ConvertFrom-Json
    $overallCoverage = [Math]::Floor(($json.CodeCoverage.NumberOfCommandsExecuted / $json.CodeCoverage.NumberOfCommandsAnalyzed) * 100)
    assert($OverallCoverage -gt $PercentCompliance) ('A Code Coverage of "{0}" does not meet the build requirement of "{1}"' -f $overallCoverage, $PercentCompliance)
}