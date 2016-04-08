Param(
  [Parameter(Mandatory=$True,Position=0)]
   [string]$PackageDirectory,
  
  [Parameter(Mandatory=$True)]
   [string]$PackageName,
   
   [Parameter(Mandatory=$True)]
   [string]$PackagePassword
   
   )

$pkgDir = $PackageDirectory
$tgt7z = $Packagename
$pwd = $PackagePassword   

##Specify target directory
#$tgtDir = gci $7zfile | % {$_.BaseName}
$irFolder = "c:\IR\"
$workingDir = $irFolder + $pkgDir  
   
##specify the 7z package then decompress...
#$tgt7z = Read-Host "Enter the target package name(201x-MM-YY_HHMM_SYSTEMname.7z)..."
#$pwd = Read-Host "Enter the password for the package..."

$7zfile = $irFolder + $pkgDir + "\$tgt7z"
$un7zip = "7za.exe x -p$pwd -o$workingDir $7zfile *>&1"
Invoke-Expression $un7zip | Out-Null

#mftdump.exe
#MFTwork
InVoke-WmiMethod -class Win32_process -name Create -ArgumentList "cmd /c rename $workingDir\disk\*MFT MFT" | Out-Null
$mftCmd = "c:\tOOls\mftdump\mftdump.exe /o $workingDir\MFT_analysis.txt $workingDir\disk\MFT *>&1"
Write-Host "Starting.. " -ForegroundColor magenta
start-sleep -Seconds 3
Write-Host "Parsing the MFT...."
Invoke-Expression $mftCmd | Out-Null
do {(Write-Host -ForegroundColor Yellow "  parsing the MFT..."),(Start-Sleep -Seconds 2)}
until ((Get-WMIobject -Class Win32_process -Filter "Name='MFTDump.exe'" | where {$_.Name -eq "MFTdump.exe"}).ProcessID -eq $null)
Write-Host "  [done]"

#RegRipper
#RegistryFiles
cd C:\tOOls\RegRipper
Write-Host "Parsing the Registry...."
$regLoc = "$workingDir\reg\"
$regRip = "C:\tOOls\RegRipper\rip.exe -r"
$ripSys = "$regRip $regLoc\SYSTEM -f system > $workingDir\reg_SYSTEM_analysis.txt *>&1"
$ripSoft = "$regRip $regLoc\SOFTWARE -f software > $workingDir\reg_SOFTWARE_analysis.txt *>&1"
$ripSec = "$regRip $regLoc\SECURITY -f security > $workingDir\reg_SECURITY_analysis.txt *>&1"
Invoke-Expression $ripSys | Out-Null
Invoke-Expression $ripSoft | Out-Null
Invoke-Expression $ripSec | Out-Null
Write-Host "  [done]"

#NTUser.Dat Files
Write-Host "Parsing the NTUSER.DAT(s)...."
$regOpt = "-f ntuser"
$userDirs = Get-ChildItem -Path $workingDir\Users\ | foreach-object name
foreach ($userDir in $userDirs){
	$ntDat = "$workingDir\Users\$userDir" + "\ntuser.dat"
	$outName = "$workingDir\$userDir" + "_NTUserDAT_analysis.txt"
	$ripNTuser = "$regRip $ntDat $regOpt > $outName *>&1" 
	Invoke-Expression $ripNTuser | Out-Null
	}
Write-Host "  [done]"

#PECmd
#Prefetch Files
Write-Host "Parsing the Prefetch files...."
$pfFolder = " $workingDir\prefetch"
$PECmd = "C:\tOOls\pecmd\pecmd.exe -d $pfFolder -k appdata -q --csv $workingDir"
Invoke-Expression $PEcmd
Write-Host "  [done]"
