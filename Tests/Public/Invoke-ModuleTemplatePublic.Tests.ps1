$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace("Tests\Public","ModuleTemplate\Public")
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here\$sut"

# To make test runable from project root, and from test directory itself. Do quick validation.
if ((Get-Location).Path -match "\\Tests\\Public") {
    $psmPath = (Resolve-Path "..\..\ModuleTemplate\ModuleTemplate.psm1").Path    
} else {
    $psmPath = (Resolve-Path ".\ModuleTemplate\ModuleTemplate.psm1").Path
}

Import-Module $psmPath -Force -NoClobber

InModuleScope "ModuleTemplate" {

    Describe "Invoke-ModuleTemplatePublic" {
        It 'Invoke-ModuleTemplatePublic Should Be Invoke-ModuleTemplatePublic' {
            Invoke-ModuleTemplatePublic | Should be 'Invoke-ModuleTemplatePublic'
        }
    }

}
