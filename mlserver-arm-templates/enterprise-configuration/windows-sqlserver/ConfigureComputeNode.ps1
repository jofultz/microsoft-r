param (
    [string]$poolInitialSize,
    [string]$poolMaxSize
)

$appSettingsJson = Get-Content -Encoding UTF8 -Raw "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.ComputeNode\appsettings.json" | ConvertFrom-Json

$appSettingsJson.Pool.InitialSize = 100 #[int32]::Parse($poolInitialSize)
$appSettingsJson.Pool.MaxSize = 100 #[int32]::Parse($poolMaxSize)

$appSettingsJson | ConvertTo-Json -Depth 100 | Set-Content -Encoding UTF8 "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.ComputeNode\appsettings.json"

#install updated ODBC drivers
$odbcUpdateDownloadJob = Start-Job {Invoke-WebRequest "https://download.microsoft.com/download/D/5/E/D5EEF288-A277-45C8-855B-8E2CB7E25B96/x64/msodbcsql.msi" -OutFile "C:\WindowsAzure\msodbcsql.msi"}
$odbcUpdateDownloadJob | Wait-Job
Start-Process msiexec.exe "/i C:\WindowsAzure\msodbcsql.msi /quiet /passive /n /le c:\WindowsAzure\msi.log IACCEPTMSODBCSQLLICENSETERMS=YES"
#end install updated ODBC drivers

$psi = New-Object System.Diagnostics.ProcessStartInfo;
$psi.FileName = "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin\az.cmd";
$psi.Arguments = "ml admin node setup --computenode";
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
