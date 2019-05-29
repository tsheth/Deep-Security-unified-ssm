PARAM
(
	[Parameter(Position=0)]
	[ValidateNotNullOrEmpty()]
	[String] $ActivationURL,

	[Parameter(Position=1)]
	[ValidateNotNullOrEmpty()]
	[String] $ActivationPort,

	[Parameter(Position=2)]
	[ValidateNotNullOrEmpty()]
	[String] $ManagerURL,

	[Parameter(Position=3)]
	[ValidateNotNullOrEmpty()]
	[String] $TenantID,

	[Parameter(Position=4)]
	[ValidateNotNullOrEmpty()]
	[String] $Token,

	[Parameter(Position=5)]
	[ValidateNotNullOrEmpty()]
	[String] $PolicyID
)
PROCESS
{
	# This script detects platform and architecture.  It then downloads and installs the relevant Deep Security Agent 10 package
	if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	   Write-Warning "You are not running as an Administrator. Please try again with admin privileges."
	   exit 1 }
	$env:LogPath = "$env:appdata\Trend Micro\Deep Security Agent\installer"
	New-Item -path $env:LogPath -type directory
	Start-Transcript -path "$env:LogPath\dsa_deploy.log" -append
	$data = "$(Get-Date) - ActivationURL:$ActivationURL ActivationPort:$ActivationPort ManagerURL:$ManagerURL TenantID:$TenantID Token:$Token PolicyID:$PolicyID"
	$data

	echo "$(Get-Date -format T) - DSA download started"
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
	$baseUrl="https://$ManagerURL/:443/"
	if ( [intptr]::Size -eq 8 ) { 
	   $sourceUrl=-join($baseurl, "software/agent/Windows/x86_64/") }
	else {
	   $sourceUrl=-join($baseurl, "software/agent/Windows/i386/") }
	echo "$(Get-Date -format T) - Download Deep Security Agent Package" $sourceUrl
	Try
	{
		(New-Object System.Net.WebClient).DownloadFile($sourceUrl,  "$env:temp\agent.msi")
	}
	Catch [System.Net.WebException] {
	echo "TLS certificate validation for the agent package download has failed. Please check that your Deep Security Manager TLS certificate is signed by a trusted root certificate authority. For more information, search for `"deployment scripts`" in the Deep Security Help Center."
	 exit 2;
	}
	if ( (Get-Item "$env:temp\agent.msi").length -eq 0 ) {
	echo "Failed to download the Deep Security Agent. Please check if the package is imported into the Deep Security Manager. "
	 exit 1 }
	echo "$(Get-Date -format T) - Downloaded File Size:" (Get-Item "$env:temp\agent.msi").length
	echo "$(Get-Date -format T) - DSA install started"
	echo "$(Get-Date -format T) - Installer Exit Code:" (Start-Process -FilePath msiexec -ArgumentList "/i $env:temp\agent.msi /qn ADDLOCAL=ALL /l*v `"$env:LogPath\dsa_install.log`"" -Wait -PassThru).ExitCode 
	echo "$(Get-Date -format T) - DSA activation started"
	Start-Sleep -s 50
	& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -r
	& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a "dsm://$ActivationURL/:$ActivationPort/" "tenantID:$TenantID" "token:$Token" "policyid:$WindowsPolicyID"
	Stop-Transcript
	echo "$(Get-Date -format T) - DSA Deployment Finished"
}


