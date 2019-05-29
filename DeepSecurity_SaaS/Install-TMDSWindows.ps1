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
	# This script detects platform and architecture.  It then downloads and installs the relevant Deep Security Agent 10 package
	if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	   Write-Warning "You are not running as an Administrator. Please try again with admin privileges."
	   exit 1 }
	$env:LogPath = "$env:appdata\Trend Micro\Deep Security Agent\installer"
	New-Item -path $env:LogPath -type directory
	Start-Transcript -path "$env:LogPath\dsa_deploy.log" -append
	$data = "$(Get-Date) - TenantID:$TenantID Token:$Token PolicyID:$PolicyID"
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
	& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a dsm://$ActivationURL:$ActivationPort/ "tenantID:$TenantID" "token:$Token" "policyid:$PolicyID"
	Stop-Transcript
	echo "$(Get-Date -format T) - DSA Deployment Finished"
}


# SIG # Begin signature block
# MIIR2wYJKoZIhvcNAQcCoIIRzDCCEcgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWQkCRtNuoBeH+IoyJriaKch4
# RFCggg8xMIIHXTCCBkWgAwIBAgIKTjN3egACABwQ4TANBgkqhkiG9w0BAQUFADBl
# MRMwEQYKCZImiZPyLGQBGRYDbXNkMRgwFgYKCZImiZPyLGQBGRYIaW50cmFuZXQx
# EjAQBgoJkiaJk/IsZAEZFgJuYTEgMB4GA1UEAxMXQWx0aWNvci1Db3JwLUlzc3Vp
# bmctQ0EwHhcNMTcwMTA2MTQzMzM3WhcNMTkwMTA2MTQzMzM3WjCBpjELMAkGA1UE
# BhMCVVMxETAPBgNVBAgTCE1pY2hpZ2FuMQwwCgYDVQQHEwNBZGExDjAMBgNVBAoT
# BUFtd2F5MR8wHQYDVQQLExZXZWIgVGVjaG5vbG9neSBTdXBwb3J0MSQwIgYDVQQD
# FBtJJk8gRGVzaWduIGFuZCBBcmNoaXRlY3R1cmUxHzAdBgkqhkiG9w0BCQEWEHdl
# Ym9wc0BhbXdheS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDd
# m2qbeObblwEztsZzI6vO37+eD6Nwr+lf8hiS36JlTLzNSX30rUXVSfa84pcQmDnz
# szxbWjmbAl1HZb4db8no1j7qBgboJ4cPL1efj9betRE5bFkkiVYAjAGq6Gh2Ig18
# F2AOarmr0ql7lVfczhw7PYq1/9SQG5bUIvRN8QfWy3vaAGoKaYmRg9R06A4d+ByD
# FCToWty3M/aITwbSHlknBDnoMWFXBiE99cYXbHa03toQeyBhMksLDskcK8nPwYk1
# CNQxjjvA5ySxTg5GWT2WTZ+f/RRnlg8cT5qzRJsu84syyPEIwFvTrKaEVLB/GN1T
# NiqVp4Uaba52W+afkdhXAgMBAAGjggPLMIIDxzAdBgNVHQ4EFgQUFSm69+UyPnWs
# TIlvn01ckhiTk1EwHwYDVR0jBBgwFoAUfL/hveh8cRQPfp3DoqvHHjIK/dcwggFh
# BgNVHR8EggFYMIIBVDCCAVCgggFMoIIBSIaBvmxkYXA6Ly8vQ049QWx0aWNvci1D
# b3JwLUlzc3VpbmctQ0EsQ049VVNQSzAyLENOPUNEUCxDTj1QdWJsaWMlMjBLZXkl
# MjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWludHJh
# bmV0LERDPW1zZD9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0
# Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnSGP2h0dHA6Ly9wa2kubmEuaW50cmFu
# ZXQubXNkL0NlcnREYXRhL0FsdGljb3ItQ29ycC1Jc3N1aW5nLUNBLmNybIZEaHR0
# cDovL3VzcGswMi5uYS5pbnRyYW5ldC5tc2QvQ2VydEVucm9sbC9BbHRpY29yLUNv
# cnAtSXNzdWluZy1DQS5jcmwwggGfBggrBgEFBQcBAQSCAZEwggGNMIG3BggrBgEF
# BQcwAoaBqmxkYXA6Ly8vQ049QWx0aWNvci1Db3JwLUlzc3VpbmctQ0EsQ049QUlB
# LENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZp
# Z3VyYXRpb24sREM9aW50cmFuZXQsREM9bXNkP2NBQ2VydGlmaWNhdGU/YmFzZT9v
# YmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MGUGCCsGAQUFBzAChllo
# dHRwOi8vcGtpLm5hLmludHJhbmV0Lm1zZC9jZXJ0ZGF0YS9VU1BLMDIubmEuaW50
# cmFuZXQubXNkX0FsdGljb3ItQ29ycC1Jc3N1aW5nLUNBKDIpLmNydDBqBggrBgEF
# BQcwAoZeaHR0cDovL3VzcGswMi5uYS5pbnRyYW5ldC5tc2QvQ2VydEVucm9sbC9V
# U1BLMDIubmEuaW50cmFuZXQubXNkX0FsdGljb3ItQ29ycC1Jc3N1aW5nLUNBKDIp
# LmNydDALBgNVHQ8EBAMCB4AwPgYJKwYBBAGCNxUHBDEwLwYnKwYBBAGCNxUIh5GH
# DofiwUKEmYEphJjIY4KHuEyBG4fF/0iH7fEjAgFkAgEQMBMGA1UdJQQMMAoGCCsG
# AQUFBwMDMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwDQYJKoZIhvcNAQEF
# BQADggEBAC9V1j6POTzji5BxawfCKZOsuyss5A0MXKaEk5pI5kNhw4FHW08b7z+8
# X3rfIwlxuADyUixe1TBkmyf2Tpo5mHiMfswjAl2AaQuYcsGsV6o03UrRWtMl1n++
# 0q1h78AY3EHz1Wcp/lwYqQBUnsEDj6E54pawrNTpK4VZWzVp9lHTTtq4ywoXLu08
# eknOiAB2LKlomO56Q3OWf0hvZgphSwfK85FR7K6JrHLJqjnQjCR8eS49l7pHzb8I
# Rgvjb8u7CTVe5zUZvizKGoH9lrN+Acl8YIZWRR1iZi6zMH8RF13uk5ap+3mcH4BN
# wERG4pDifQW24Uh3oXf6hi/LhXjYuIQwggfMMIIFtKADAgECAgoXLjojAAAAAAAF
# MA0GCSqGSIb3DQEBBQUAMEkxEzARBgoJkiaJk/IsZAEZFgNtc2QxGDAWBgoJkiaJ
# k/IsZAEZFghpbnRyYW5ldDEYMBYGA1UEAxMPQWx0aWNvci1Sb290LUNBMB4XDTEz
# MDExNjE4MjUxNVoXDTIzMDExNjE4MzUxNVowZTETMBEGCgmSJomT8ixkARkWA21z
# ZDEYMBYGCgmSJomT8ixkARkWCGludHJhbmV0MRIwEAYKCZImiZPyLGQBGRYCbmEx
# IDAeBgNVBAMTF0FsdGljb3ItQ29ycC1Jc3N1aW5nLUNBMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAplTucso9VAOlhcS4nEVVcbplfoESuXmkRCfvu9A2
# ULBYL2hwsQvdun+mFg3OVnfVCAni/6tsek34v7TcdIQPn+Vswq0qQSUodKGLj4ux
# DiWzHtbVIT2lD1fpPvSFHw2kFcQnfNv0y4KsvJ+QSz89drI0YiVdUUmAwUXXTTBv
# uhwscwfPxtj1j42823YDyG/fUF1+RxbT0RpoJuPtftRVzng1sByX4zaZGHc6zOYU
# yFRxMKfBTh+Yi+RxJ+rEap3OrZcus2VY4CaonUYmEb7x1vLWFyJeM4kBfdP1HxEw
# 5zPt/Z+AmvvVOBngBuu8vIG4tHIa1WzHLNzqur1rS9cSKwIDAQABo4IDmDCCA5Qw
# EAYJKwYBBAGCNxUBBAMCAQIwIwYJKwYBBAGCNxUCBBYEFMK9S5ykgVlTlT0HpVAs
# FXlKA+6XMB0GA1UdDgQWBBR8v+G96HxxFA9+ncOiq8ceMgr91zCBxAYDVR0gBIG8
# MIG5MIG2BgkqAwQFBgcICQ4wgagwbgYIKwYBBQUHAgIwYh5gAEEAbAB0AGkAYwBv
# AHIAIABDAG8AcgBwAG8AcgBhAHQAZQAgAEMAZQByAHQAaQBmAGkAYwBhAHQAZQAg
# AFAAcgBhAGMAdABpAGMAZQAgAFMAdABhAHQAZQBtAGUAbgB0MDYGCCsGAQUFBwIB
# FipodHRwOi8vcGtpLm5hLmludHJhbmV0Lm1zZC9jcHMvcm9vdGNwcy5hc3AwGQYJ
# KwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQF
# MAMBAf8wHwYDVR0jBBgwFoAUjTZzJGd+8oto30PYWcaxodEPYQIwggEGBgNVHR8E
# gf4wgfswgfiggfWggfKGgbZsZGFwOi8vL0NOPUFsdGljb3ItUm9vdC1DQSxDTj1V
# U1BLMDEsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZp
# Y2VzLENOPUNvbmZpZ3VyYXRpb24sREM9SW50cmFuZXQsREM9TVNEP2NlcnRpZmlj
# YXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRp
# b25Qb2ludIY3aHR0cDovL3BraS5uYS5pbnRyYW5ldC5tc2QvQ2VydERhdGEvQWx0
# aWNvci1Sb290LUNBLmNybDCCAQ8GCCsGAQUFBwEBBIIBATCB/jCBrwYIKwYBBQUH
# MAKGgaJsZGFwOi8vL0NOPUFsdGljb3ItUm9vdC1DQSxDTj1BSUEsQ049UHVibGlj
# JTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixE
# Qz1JbnRyYW5ldCxEQz1NU0Q/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNz
# PWNlcnRpZmljYXRpb25BdXRob3JpdHkwSgYIKwYBBQUHMAKGPmh0dHA6Ly9wa2ku
# bmEuaW50cmFuZXQubXNkL0NlcnREYXRhL1VTUEswMV9BbHRpY29yLVJvb3QtQ0Eu
# Y3J0MA0GCSqGSIb3DQEBBQUAA4ICAQAjWwEbAu2AbS+RRWyUPeyWhMx8eN4qgN9c
# JNcSWmftBIhAZTa0n7zZlr27IReCUjudQ9Bnq5SdhGtlqC5ew6fkAjqH9aa7zVIL
# tSQLn2xiuwO99kGn5cwbsHU+VcgJf2i8scX8YXrT+B2RrTgGi8SY3d4TD5ze3BJ+
# RK2ArBoA5YLxrZHGvPjjrxUW6Rr67WyIH/O1W0bTVcH24BRlyDfFiMowBAZ5sTHH
# nz0a4SHJh7Sl3BIrhw3I/LZNHuFMpUrgDuyO+zGTgp7JdqSIGx2GmdyC/NaQ24yP
# TY+NILnu4ytS+FyTfYwdt7RPzaJSWUvjIAAVw6jpxViRwgwiMs0lKe5It2ZMuhOL
# aHfa/i57fVlDVwzcJXsN6kIqAcoyzyGAi2GSMgaHUX4m/hRcDW7ONKz3G0CFsOiE
# o0iBwlIR/houEJAGcVBtP9vrTZM5UkAx4TXQ3ZFQ6dIl2neGo2xf5tomwdDqVJjk
# NszzPeTYPcXSWD6M4M4VBm54QbKTUWjQb5fxK3UkamSH+4lQ7g48QVktUD1rGsSm
# zhBvTR8qA3H9SGqBEIdC6Xl7dqKUr3KCKwu02/1KhjKQTypzfLHac3hPhLK4AxGA
# x+nK7pdRaZrccQy7l07FDytlLEoMBGPW6f4KJoPWTfntInmZNjfjau+7t8K3zF/w
# JuegV7XELTGCAhQwggIQAgEBMHMwZTETMBEGCgmSJomT8ixkARkWA21zZDEYMBYG
# CgmSJomT8ixkARkWCGludHJhbmV0MRIwEAYKCZImiZPyLGQBGRYCbmExIDAeBgNV
# BAMTF0FsdGljb3ItQ29ycC1Jc3N1aW5nLUNBAgpOM3d6AAIAHBDhMAkGBSsOAwIa
# BQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgor
# BgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3
# DQEJBDEWBBSgS6eWAAuAtV2DT1ooazqb8/nOfjANBgkqhkiG9w0BAQEFAASCAQCn
# f8R6l0Oh7okc3FDrI6vU6+E1QxjAxr9rx1dWtIBXmd2gU8FsSwC/J+Fy/4v5h/Uv
# 4P7lSQ0GWCkHcWcY6zEcYBSsnhbl0yyRiJmGEFqih+JUvKIfG7L6Ua1j6m4xugP6
# 9NALhmgY8dbeRxqOjz7R4Dj3iV00x6V+4hCpuTGqvCm3YsZtfPRptNqP3IoagwV3
# qNI9yxoLNlVa3S73Y0JQZsrhsziPDWXZik6pcC/RQDvN1aR/eRV1FFT2C6Gt7i6+
# EgTq/z1JkrzBvcBKhKRXKnMVUPlSIll5C9X4j74G8Vd4kiL4DlGAykHG5sHqAOIJ
# jQmpSwOHyrdl2R+Cj6om
# SIG # End signature block
