
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name PSDepend -Force 

Import-Module -Name PSDepend -Force

Invoke-PSDepend -Force

Import-Module InvokeBuild, PSScriptAnalyzer, PSDeploy, BuildHelpers, Pester -Force

Get-Item -Path env:BH* | Remove-Item

Set-BuildEnvironment

Invoke-Build $ENV:BHProjectPath\module.build.ps1 -Task Default

