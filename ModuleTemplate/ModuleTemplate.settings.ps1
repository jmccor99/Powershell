# Settings for build.
param(
    $Artifacts = './artifacts',
    $ModuleName = 'ModuleTemplate',
    $ModulePath = '.\ModuleTemplate',
    $BuildNumber = $env:BUILD_NUMBER,
    $PercentCompliance = '50'
)