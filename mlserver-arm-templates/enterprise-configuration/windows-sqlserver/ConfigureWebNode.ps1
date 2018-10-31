param (
	[string]$password,
    [string]$sqlServerConnectionString
)

function AllowRead-Certificate
{
    param($cert)

	$rsaFileName = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName

	$keyPath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\"
	$fullPath = $keyPath+$rsaFileName

	$acl = Get-Acl -Path $fullPath
	$networkService = New-Object System.Security.Principal.SecurityIdentifier([System.Security.Principal.WellKnownSidType]::NetworkServiceSid, $null)
	$permission=$networkService,"Read","Allow"
	$accessRule=new-object System.Security.AccessControl.FileSystemAccessRule $permission
	$acl.AddAccessRule($accessRule)

	Set-Acl $fullPath $acl
}

Push-Location Cert:\LocalMachine\My\
Get-ChildItem | where { $_.Subject -eq 'DC=Windows Azure CRP Certificate Generator' -And $_.HasPrivateKey -And ($_.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName -eq $Null) } | Remove-Item
$cert = (Get-ChildItem | where { $_.Subject -eq 'DC=Windows Azure CRP Certificate Generator' })[0]
Pop-Location

AllowRead-Certificate($cert)

$computeNodeAppSettingsJson = Get-Content -Encoding UTF8 -Raw "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.ComputeNode\appsettings.json" | ConvertFrom-Json
$computeNodeAppSettingsJson | add-member -Name "configured" -value "configured" -MemberType NoteProperty
$computeNodeAppSettingsJson | ConvertTo-Json -Depth 100 | Set-Content -Encoding UTF8 "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.ComputeNode\appsettings.json"

$appSettingsJson = Get-Content -Encoding UTF8 -Raw "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.WebNode\appsettings.json" | ConvertFrom-Json
$appSettingsJson.Logging.LogLevel.Default = "Information"
$appSettingsJson.Logging.LogLevel.System = "Information"
$appSettingsJson.Logging.LogLevel.Microsoft = "Information"
$appSettingsJson.ConnectionStrings.sqlserver.Enabled = $True
$appSettingsJson.ConnectionStrings.sqlserver.Connection = $sqlServerConnectionString
$appSettingsJson.ConnectionStrings.defaultDb.Enabled = $False
$appSettingsJson.Authentication.JWTSigningCertificate.Enabled = $True
$appSettingsJson.Authentication.JWTSigningCertificate.SubjectName = "DC=Windows Azure CRP Certificate Generator"
$appSettingsJson.ComputeNodesConfiguration.Uris.Ranges = @("http://10.164.118.176-191:12805")

$appSettingsJson | ConvertTo-Json -Depth 100 | Set-Content -Encoding UTF8 "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.WebNode\appsettings.json"

$psi = New-Object System.Diagnostics.ProcessStartInfo;
$psi.FileName = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd";
$psi.Arguments = "ml admin node setup --webnode --admin-password ""$password"" --confirm-password ""$password""";
$psi.WorkingDirectory = "C:\Program Files\Microsoft\ML Server";
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi);
$poutput = $p.StandardOutput.ReadToEnd();
$perror = $p.StandardError.ReadToEnd();
$p.WaitForExit();
Write-Output $poutput
Write-Output $perror

taskkill /f /im dotnet.exe
Disable-ScheduledTask -TaskName "autostartwebnode"

echo "<configuration><system.webServer><security><requestFiltering><requestLimits maxAllowedContentLength=""4294967295""/></requestFiltering></security><handlers><add name=""aspNetCore"" path=""*"" verb=""*"" modules=""AspNetCoreModule"" resourceType=""Unspecified"" /></handlers><aspNetCore requestTimeout=""01:00:00"" processPath=""C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\dotnet\dotnet.exe"" arguments=""./Microsoft.MLServer.WebNode.dll"" stdoutLogEnabled=""true"" stdoutLogFile="".\logs\stdout"" forwardWindowsAuthToken=""false""><environmentVariables><environmentVariable name=""COMPlus_ReadyToRunExcludeList"" value=""System.Security.Cryptography.X509Certificates"" /></environmentVariables></aspNetCore></system.webServer></configuration>" > "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.WebNode\web.config"

#install updated ODBC drivers
$odbcUpdateDownloadJob = Start-Job {Invoke-WebRequest "https://download.microsoft.com/download/D/5/E/D5EEF288-A277-45C8-855B-8E2CB7E25B96/x64/msodbcsql.msi" -OutFile "C:\WindowsAzure\msodbcsql.msi"}
$odbcUpdateDownloadJob | Wait-Job
Start-Process msiexec.exe "/i C:\WindowsAzure\msodbcsql.msi /quiet /passive /n /le c:\WindowsAzure\msi.log IACCEPTMSODBCSQLLICENSETERMS=YES"
#end install updated ODBC drivers

$hostingBundleDownloadJob = Start-Job {Invoke-WebRequest "https://go.microsoft.com/fwlink/?linkid=844461" -OutFile "C:\WindowsAzure\HostingBundle.exe"}
Install-WindowsFeature -name Web-Server -IncludeManagementTools
$hostingBundleDownloadJob | Wait-Job
Start-Process "C:\WindowsAzure\HostingBundle.exe" "/quiet /install OPT_INSTALL_LTS_REDIST=0 OPT_INSTALL_FTS_REDIST=0" -Wait

Import-Module WebAdministration

$iisAppPoolName = "netcore"
$iisAppName = "MLS-WebNode"
$directoryPath = "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.WebNode"

Push-Location IIS:\AppPools\
$appPool = New-Item $iisAppPoolName
$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value ""
$appPool | Set-ItemProperty -Name "startMode" -Value "alwaysrunning"
$appPool | Set-ItemProperty -Name "processModel.idleTimeout" -Value "0"
$appPool | Set-ItemProperty -Name "processModel.identityType" -Value "NetworkService"
Pop-Location

Push-Location IIS:\Sites\
Get-ChildItem | Remove-Item -Recurse -Confirm:$false
$iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation=":80:"} -physicalPath $directoryPath
$iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName

Pop-Location
iisreset

#/////////////////// install additional python packages befor changing cert

#add python to path
$env:Path += ";c:\Program Files\Microsoft\ML Server\PYTHON_SERVER"

#update pip
python -m pip install --upgrade pip

#install packages
python -m pip install flashtext

#/////////////////// end install python packages

#/////////////////// copy pem file for certificate verification
#rename current
$timestamp = "[{0:MM/dd/yy} {0:HH:mm:ss.ff}]" -f (Get-Date)
Write-Output "Beginng PEM replacement: " + $timestamp
#rename current
Rename-Item -Path "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\lib\site-packages\certifi\cacert.pem" -NewName "cacert-original.pem"
#download replacement
$downloadPath = "c:\temp-download"
$url = "https://raw.githubusercontent.com/jofultz/microsoft-r/master/mlserver-arm-templates/enterprise-configuration/windows-sqlserver/cert/dell-root-ca.pem"
$output = $downloadPath + "\new-cacert.pem"

New-Item -ItemType Directory -Force -Path $downloadPath
Invoke-WebRequest -Uri $url -OutFile $output

$timestamp = "[{0:MM/dd/yy} {0:HH:mm:ss.ff}]" -f (Get-Date)
Write-Output "cert download finished: " + $timestamp 
#copy replacement
Copy-Item $output -Destination "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\lib\site-packages\certifi\cacert.pem"

$timestamp = "[{0:MM/dd/yy} {0:HH:mm:ss.ff}]" -f (Get-Date)
Write-Output "End PEM replacement: " + $timestamp
#/////////////////// end copy pem filef for certificate verifcation
 
#////////////////// set cors settings for webnodes
 
$mlserver_pyappsettings = 'C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\o16n\Microsoft.MLServer.WebNode\appsettings.json'
$pyjson = (Get-Content $mlserver-pyappsettings) | ConvertFrom-Json
$pyjson.CORS.Enabled = "True"
$pyjson.CORS.Origins = "sdsapps.dell.com", "*.sdsapps.dell.com"
($rjson | ConvertTo-Json -Depth 50 | % { [System.Text.RegularExpressions.Regex]::Unescape($_) }) | Set-Content $mlserver_pyappsettings
 
$mlserver_rappsettings = 'C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.WebNode\appsettings.json'
$rjson = (Get-Content $mlserver_rappsettings ) | ConvertFrom-Json
$rjson.CORS.Enabled = "True"
$rjson.CORS.Origins = "sdsapps.dell.com", "*.sdsapps.dell.com"
($rjson | ConvertTo-Json -Depth 50 | % { [System.Text.RegularExpressions.Regex]::Unescape($_) }) | Set-Content $mlserver_rappsettings 
 
#////////////////// end cors settings for webnodes
