# Templates


# ModuleTemplate

ModuleTemplate generated from PSScaffold  

Install-Module PSScaffold  
Install-Module InvokeBuild  
Install-Module PSScriptAnalyzer  

New-PSModule -Name ModuleTemplate -Author 'Template' -Description 'Module Template' -BuildPipeline  

New-PSFunction -Name Invoke-ModuleTemplatePublic -Scope Public -PesterTest  
New-PSFunction -Name Invoke-ModuleTemplatePrivate -Scope Private -PesterTest  

Added basic code to functions and a Pester assertion in Private and Public tests  

Removed Publish task from ModuleTemplate.settings.ps1 and ModuleTemplate.build.ps1  

Usage:  

cd c:\temp\  

git clone https://github.com/jmccor99/Templates.git  

cd c:\temp\Templates\ModuleTemplate\  

Ensure the following modules are installed (local + build agent)  

Install-Module InvokeBuild  
Install-Module PSScriptAnalyzer  
Install-Module Pester  

Execute:  

Invoke-Build -Task Clean  
Invoke-Build -Task Test  
Invoke-Build  