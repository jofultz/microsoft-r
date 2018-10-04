param (
    [string]$poolInitialSize,
    [string]$poolMaxSize
)

$appSettingsJson = Get-Content -Encoding UTF8 -Raw "C:\Program Files\Microsoft\ML Server\R_SERVER\o16n\Microsoft.MLServer.ComputeNode\appsettings.json" | ConvertFrom-Json
$appSettingsJson.Pool.InitialSize = [int32]::Parse($poolInitialSize)
$appSettingsJson.Pool.MaxSize = [int32]::Parse($poolMaxSize)
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

#copy pem file for certificate verification
#rename current
Write-Output "Beginng PEM replacement"
#rename current
Rename-Item -Path "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\lib\site-packages\certifi\cacert.pem" -NewName "cacert-original.pem"
#copy replacement
$pathToNewPem = $PSScriptRoot + "\dell-root-ca.pem"
Write-Output "New pem path: " + $PSScriptRoot
Copy-Item $pathToNewPem -Destination "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\lib\site-packages\certifi\cacert.pem"
Write-Output $perror
Write-Output "End PEM replacement"
#end copy pem filef for certificate verifcation

