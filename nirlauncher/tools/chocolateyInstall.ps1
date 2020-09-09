$ErrorActionPreference = 'Stop'

$toolsDir = Split-Path $MyInvocation.MyCommand.Definition
$is64 = (Get-ProcessorBits 64) -and $env:chocolateyForceX86 -ne 'true'
$install_path  = "$(Get-ToolsLocation)\NirLauncher"

$packageArgs = @{
    PackageName    = 'nirlauncher'
    FileFullPath   = gi $toolsDir\*.zip
    FileFullPath64 = gi $toolsDir\*.zip
    Destination    = $install_path
}
Get-ChocolateyUnzip @packageArgs
rm $toolsDir\*.zip -ea 0

# NirLauncher already runs the 64-bit versions of tools when possible, no need to overwrite anything.
Install-ChocolateyPath $install_path\Nirsoft "Machine"

$launcher_path = "$install_path\$packageName.exe"
Register-Application $launcher_path
Write-Host "$packageName registered as $packageName"

Install-BinFile $packageName $launcher_path

$pp = Get-PackageParameters
if ($pp.SysInternals) {
    Write-Host 'SysInternals utilities will be added'

    $sysinternals_dir = gcm autoruns.exe -ea 0 | select -Expand Source | Split-Path
    if (!$sysinternals_dir) { Write-Warning 'Sysinternals tools are not on the PATH'; return }

    mv $toolsDir\sysinternals2.nlp $sysinternals_dir -Force

    #Configure nirlauncher
    $nircfg = gc $install_path\NirLauncher.cfg -Raw
    if ($nircfg -notmatch '\[Package1\]') {
        $nircfg = $nircfg.Replace("PackageCount=1", "PackageCount=2")
        $nircfg += "[Package1]`nfilename=$sysinternals_dir\sysinternals2.nlp"
        $nircfg | Out-File $install_path\NirLauncher.cfg -Encoding ascii
    }
}
