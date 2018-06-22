PARAM
(
	[Parameter(Position=0)]
	[ValidateNotNullOrEmpty()]
	[String] $TenantID,

	[Parameter(Position=1)]
	[ValidateNotNullOrEmpty()]
	[String] $Token,

	[Parameter(Position=1)]
	[ValidateNotNullOrEmpty()]
	[String] $PolicyID
)
PROCESS
{
#requires -version 4.0

# PowerShell script that handles forward proxy settings both during
# agent download and agent activation.  Also, select fields have been
# parameterized for convenience sake.


# Required fields
#$TenantID # DSaaS Tenant ID
#$Token    = "" # DSaaS Token
#$PolicyID = "" # designated PolicyId 

# Optional field
# If proxy configured, the DSaaS policy must be configured for the proxy
#$Proxy = "" # Forward proxy IP:Port

# This script detects platform and architecture.  It then downloads and installs the relevant Deep Security Agent 10 package
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You are not running as an Administrator. Please try again with admin privileges."
    exit 1 
    }

$env:LogPath = "$env:appdata\Trend Micro\Deep Security Agent\installer"
New-Item -path $env:LogPath -type directory
Start-Transcript -path "$env:LogPath\dsa_deploy.log" -append
Write-Output "$(Get-Date -format T) - DSA download started"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
$baseUrl="https://app.deepsecurity.trendmicro.com:443/"

if ( [intptr]::Size -eq 8 ) { 
    $sourceUrl=-join($baseurl, "software/agent/Windows/x86_64/") 
    }
else {
    $sourceUrl=-join($baseurl, "software/agent/Windows/i386/") 
    }

Write-Output "$(Get-Date -format T) - Download Deep Security Agent Package" $sourceUrl

Try {
    $WebClient = New-Object System.Net.WebClient

    if ( $Proxy ) {
        $WebProxy = New-Object System.Net.WebProxy ("http://$Proxy", $true)
        # credentials here perhaps
        $WebClient.Proxy = $WebProxy
    }


    $WebClient.DownloadFile($sourceUrl, "$env:temp\agent.msi")
}
Catch [System.Net.WebException] {
    Write-Output "TLS certificate validation for the agent package download has failed. Please check that your Deep Security Manager TLS certificate is signed by a trusted root certificate authority. For more information, search for `"deployment scripts`" in the Deep Security Help Center."
    exit 2;
    }

if ( (Get-Item "$env:temp\agent.msi").length -eq 0 ) {
    Write-Output "Failed to download the Deep Security Agent. Please check if the package is imported into the Deep Security Manager. "
    exit 1 
    }

Write-Output "$(Get-Date -format T) - Downloaded File Size:" (Get-Item "$env:temp\agent.msi").length

Write-Output "$(Get-Date -format T) - DSA install started"

Write-Output "$(Get-Date -format T) - Installer Exit Code:" (Start-Process -FilePath msiexec -ArgumentList "/i $env:temp\agent.msi /qn ADDLOCAL=ALL /l*v `"$env:LogPath\dsa_install.log`"" -Wait -PassThru).ExitCode 

Write-Output "$(Get-Date -format T) - DSA activation started"
Start-Sleep -s 50
& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -r

if ( $Proxy ) {
    & $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -x dsm_proxy://$Proxy/

    & $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -y relay_proxy://$Proxy/
    }

& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a dsm://agents.deepsecurity.trendmicro.com:443/ "tenantID:$TenantID" "token:$Token" "policyid:$PolicyID"

Stop-Transcript
Write-Output "$(Get-Date -format T) - DSA Deployment Finished"
}