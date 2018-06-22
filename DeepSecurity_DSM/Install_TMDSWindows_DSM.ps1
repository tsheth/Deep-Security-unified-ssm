PARAM
(
	[Parameter(Position=0)]
	[ValidateNotNullOrEmpty()]
	[String] $DSMURL,

	[Parameter(Position=1)]
	[ValidateNotNullOrEmpty()]
	[String] $PolicyId
)
PROCESS
{
#requires -version 4.0
# This script detects platform and architecture.  It then downloads and installs the relevant Deep Security Agent 10 package
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
   Write-Warning "You are not running as an Administrator. Please try again with admin privileges."
   exit 1 }
[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$env:LogPath = "$env:appdata\Trend Micro\Deep Security Agent\installer"
New-Item -path $env:LogPath -type directory
Start-Transcript -path "$env:LogPath\dsa_deploy.log" -append
echo "$(Get-Date -format T) - DSA download started"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
$baseUrl1=-join("https://", $DSMURL)
$baseUrl=-join($baseUrl1, ":443/")
echo $baseUrl
if ( [intptr]::Size -eq 8 ) {
   $sourceUrl=-join($baseurl, "software/agent/Windows/x86_64/") }
else {
   $sourceUrl=-join($baseurl, "software/agent/Windows/i386/") }
echo "$(Get-Date -format T) - Download Deep Security Agent Package" $sourceUrl
(New-Object System.Net.WebClient).DownloadFile($sourceUrl,  "$env:temp\agent.msi")
if ( (Get-Item "$env:temp\agent.msi").length -eq 0 ) {
echo "Failed to download the Deep Security Agent. Please check if the package is imported into the Deep Security Manager. "
 exit 1 }
echo "$(Get-Date -format T) - Downloaded File Size:" (Get-Item "$env:temp\agent.msi").length
echo "$(Get-Date -format T) - DSA install started"
echo "$(Get-Date -format T) - Installer Exit Code:" (Start-Process -FilePath msiexec -ArgumentList "/i $env:temp\agent.msi /qn ADDLOCAL=ALL /l*v `"$env:LogPath\dsa_install.log`"" -Wait -PassThru).ExitCode
echo "$(Get-Date -format T) - DSA activation started"
Start-Sleep -s 50
& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -r
$myurl=-join("dsm://", $DSMURL)
$withport=-join($myurl, ":4120/")
$jointpolicy=-join("policyid:", $PolicyId)
& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a $withport $jointpolicy
Stop-Transcript
echo "$(Get-Date -format T) - DSA Deployment Finished"
}