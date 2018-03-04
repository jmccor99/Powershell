
param(
    $Artifacts = '.\Artifacts',
    $ModuleName = "ModuleTemplate",
    $ModulePath = '.\ModuleTemplate',
    $BuildNumber = $env:BUILD_NUMBER,
    $PercentCompliance = '50',
    $PSDependencies = @{
        InvokeBuild      = 'latest'
        PSScriptAnalyzer = 'latest'
        PSDeploy         = 'latest'
        BuildHelpers     = 'latest'
        Pester           = 'latest'
    }
)

Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name PSDepend -Force 
Import-Module -Name PSDepend -Force

Invoke-PSDepend -InputObject $PSDependencies -Install -Force

$PSDependencies.Keys | ForEach-Object { 
    [array] $dependenciesArray += ( $_ ) 
}

Import-Module -Name $dependenciesArray -Force

Get-Item -Path env:BH* | Remove-Item
Set-BuildEnvironment

Invoke-Build $ENV:BHProjectPath\module.build.ps1 -Task Default

