$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace("Tests\Private","ModuleTemplate\Private")
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here\$sut"

# To make test runable from project root, and from test directory itself. Do quick validation.
if ((Get-Location).Path -match "\\Tests\\Private") {
    $psmPath = (Resolve-Path "..\..\ModuleTemplate\ModuleTemplate.psm1").Path    
} else {
    $psmPath = (Resolve-Path ".\ModuleTemplate\ModuleTemplate.psm1").Path
}

Import-Module $psmPath -Force -NoClobber

InModuleScope "ModuleTemplate" {

    Describe "Invoke-PrivateFunction" {
        It 'Should Be Invoke-PrivateFunction' {
            Invoke-PrivateFunction | Should be 'Invoke-PrivateFunction'
        }
    }

}
