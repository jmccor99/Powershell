
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Install-Module -Repository PSGallery -Name InvokeBuild, PSScriptAnalyzer, PSDeploy, BuildHelpers -Force -AllowClobber

Install-Module -Repository PSGallery -Name Pester -MinimumVersion 4.1 -Force -AllowClobber -SkipPublisherCheck

Import-Module InvokeBuild, BuildHelpers, PSScriptAnalyzer, PSDeploy, BuildHelpers, Pester

Set-BuildEnvironment

Invoke-Build $ENV:BHProjectPath\module.build.ps1 -Task Default

