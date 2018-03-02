
$parentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

$paramsModulePSDepend = @{
    Name = "PSDepend"
    Force  = $true
}

Install-Module @paramsModulePSDepend

Import-Module $paramsModulePSDepend.Name

$paramsPathModuleDepends = @{
    Path      =  $parentPath
    ChildPath = "module.depends.psd1"
}

$paramsPSDepend = @{
    Path  = Join-Path @paramsPathModuleDepends
    Force = $true
}

Invoke-PSDepend @paramsPSDepend

$paramsPathModuleBuild = @{
    Path      =  $parentPath
    ChildPath = "module.build.ps1"
}

$paramsBuild = @{
    File = Join-Path @paramsPathModuleBuild
}

Invoke-Build @paramsBuild