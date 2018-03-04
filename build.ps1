
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Install-Module -Repository PSGallery -Name PSDepend 

Import-Module -Name PSDepend

Invoke-PSDepend -Force

Import-Module InvokeBuild, PSScriptAnalyzer, PSDeploy, BuildHelpers, Pester

Get-Item -Path env:BH* | Remove-Item

Set-BuildEnvironment

Invoke-Build $ENV:BHProjectPath\module.build.ps1 -Task Default

