<#

.EXAMPLE
.\SecurityPosture.ps1 -OS -TPM -Bitlocker -UEFISECBOOT -Defender -ATP -LAPS -ApplicationGuard -Sandbox -CredentialGuardPreReq -CredentialGuard -DeviceGuard -AttackSurfaceReduction -ControlledFolderAccess

#>

[cmdletbinding( DefaultParameterSetName = 'Security' )]
param(
[switch]$OS,
[switch]$TPM,
[switch]$Bitlocker,
[switch]$UEFISECBOOT,
[switch]$Defender,
[switch]$ATP,
[switch]$LAPS,
[switch]$ApplicationGuard,
[switch]$Sandbox,
[switch]$CredentialGuardPreReq,
[switch]$CredentialGuard,
[switch]$DeviceGuard,
[switch]$AttackSurfaceReduction,
[switch]$ControlledFolderAccess,
[switch]$ExploitProtection)

#Global Variables
$clientPath = "C:\Temp"
$PC = $env:computername 
$script:logfile = "$clientPath\Client-SecurityPosture.log"

#Check for Elevevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
Write-Warning "This script needs to be run from an elevated PowerShell prompt.`nWould you kindly restart Powershell and launch it as Administrator before running the script again."
Write-Warning "Aborting Security Posture..."
Break
}

#Write Log-Entry
function Write-LogEntry {
    [cmdletBinding()]
    param (
        [ValidateSet("Information", "Warning", "Error", "Success")]
        $Type = "Information",
        [parameter(Mandatory = $true)]
        $Message
    )
    switch ($Type) {
        'Error' {
            $severity = 1
            $fgColor = "Red"
            break;
        }
        'Warning' {
            $severity = 3
            $fgColor = "Yellow"
            break;
        }
        'Information' {
            $severity = 6
            $fgColor = "White"
            break;
        }
        'Success' {
            $severity = 6
            $fgColor = "Green"
            break;
        }
    }
    $dateTime = New-Object -ComObject WbemScripting.SWbemDateTime
    $dateTime.SetVarDate($(Get-Date))
    $utcValue = $dateTime.Value
    $utcOffset = $utcValue.Substring(21, $utcValue.Length - 21)
    $scriptName = (Get-PSCallStack)[1]
    $logLine = `
        "<![LOG[$message]LOG]!>" + `
        "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($utcOffset)`" " + `
        "date=`"$(Get-Date -Format M-d-yyyy)`" " + `
        "component=`"$($scriptName.Command)`" " + `
        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " + `
        "type=`"$severity`" " + `
        "thread=`"$PID`" " + `
        "file=`"$($scriptName.ScriptName)`">";
        
    $logLine | Out-File -Append -Encoding utf8 -FilePath $logFile -Force
    Write-Host $Message -ForegroundColor $fgColor
}

if($OS){
    Write-LogEntry -Message "[Operating System]"
    $win32os = Get-WmiObject Win32_OperatingSystem -computer $PC -ErrorAction silentlycontinue
    $WindowsEdition = $win32os.Caption 
    $OSArchitecture = $win32os.OSArchitecture 
    $WindowsBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"-ErrorAction silentlycontinue).ReleaseId 
    $BuildNumber = $win32os.BuildNumber
    Write-LogEntry -Message "Clients OS-Edition is: $WindowsEdition"
    Write-LogEntry -Message "Clients OS-Architecture is: $OSArchitecture"
    Write-LogEntry -Message "Clients OS-Version is: $WindowsBuild"
    Write-LogEntry -Message "Clients OS-Buildnumber is: $BuildNumber"
}

if ($TPM) {
    $TPMStatus = (Get-WmiObject win32_tpm -Namespace root\cimv2\Security\MicrosoftTPM -ErrorAction silentlycontinue).isenabled()
    try {
        Write-LogEntry -Message "***[TPM]***"
        if ($TPMStatus.isenabled -eq "True")
        {                
        Write-LogEntry -Type Success -Message "TPM-chip is enabled and configured correctly in $PC"
        }
            else  
            {
                Write-LogEntry -Message "TPM is not enabled and or configured correctly in $PC"
            }
        }
        catch [System.Exception] 
            {
                Write-LogEntry -Message "Failed to check status of $TPM"
            }
        }

if ($Bitlocker) {
        Write-LogEntry -Message "[Bitlocker]" 
        $BitlockerStatus = Get-BitLockerVolume | select volumestatus,encryptionmethod,encryptionpercentage,mountpoint,VolumeType,ProtectionStatus,Keyprotector |? { $_.VolumeType -eq "OperatingSystem" -and $_.ProtectionStatus -eq "On" } -erroraction silentlycontinue
        switch ($BitlockerStatus.encryptionmethod) {
        Aes128 { $true }
        Aes256 { $true }
        Aes128Diffuser { $true }
        Aes256Diffuser { $true }
        XtsAes128 { $true }
        XtsAes256 { $true }
        Default { $false }
        }
            try {
                if ($BitlockerStatus.ProtectionStatus -eq "On")
                {                
                Write-LogEntry -Message "Bitlocker is enabled and configured correctly in $PC"
                Write-LogEntry -Message "Volumestatus: $($BitlockerStatus.Volumestatus)"
                Write-LogEntry -Message "Encryption Method: $($BitlockerStatus.Encryptionmethod)"
                Write-LogEntry -Message "Encryption Percentage: $($BitlockerStatus.EncryptionPercentage)"
                Write-LogEntry -Message "Mountpoint: $($BitlockerStatus.MountPoint)"
                Write-LogEntry -Message "Volumetype: $($BitlockerStatus.VolumeType)"
                Write-LogEntry -Message "Protectionstatus: $($BitlockerStatus.ProtectionStatus)"
                Write-LogEntry -Message "KeyProtector: $($BitlockerStatus.Keyprotector)"
                }
                    else  
                    {
                        Write-LogEntry -Message "Bitlocker is not enabled and or configured correctly in $PC"
                    }
                }
                catch [System.Exception] 
                    {
                        Write-LogEntry -Message "Failed to check status of $Bitlocker"
                    }
        }

if ($UEFISECBOOT) {
    $UEFISECBOOTStatus = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
    try {
        Write-LogEntry -Message "[SecureBoot & UEFI]"
        if ($UEFISECBOOTStatus -eq "True")
        {                
        Write-LogEntry -Message "UEFI & Secureboot enabled and configured correctly."
        }
            else  
            {
                Write-LogEntry -Message "UEFI and Secure Boot is not enabled correctly, please check the BIOS configuration."
            }
        }
        catch [System.Exception] 
            {
                Write-LogEntry -Message "Failed to check status of $UEFISECBOOT"
            }
        }

if ($Defender) {
    Write-LogEntry -Message "[Defender]"
    $p = Get-MpPreference
    $c = Get-MpComputerStatus
    $p = @($p)
    $Defenderstatus = ($p += $c)
    try {
        $Service = get-service -DisplayName "Windows Defender Antivirus Service" -ErrorAction SilentlyContinue
        if ($Service.Status -eq "Running")
        {
        Write-LogEntry -Message "Windows Defender seems to be active and running in $PC" 
        }
        else 
        {
            Write-LogEntry -Message "Defender Service is not running..."
        }
        if ($Defenderstatus.AntivirusEnabled -eq "True") 
        {                
        Write-LogEntry -Message "Antivirus is Enabled"
        }
        else  
            {
                Write-LogEntry -Message "Antivirus is Disabled"
            }
        if ($Defenderstatus.AntispywareEnabled -eq "True") 
            {
                Write-LogEntry -Message "Antispyware is Enabled"
            }
        else 
            {
                Write-LogEntry -Message "Antispyware is Disabled"
            }
        if ($Defenderstatus.RealTimeProtectionEnabled -eq "True") 
            {
                Write-LogEntry -Message "Real Time Protection is Enabled"
            }
        else 
            {
                Write-LogEntry -Message "Real Time Protection is Disabled"
            }    
        if ($Defenderstatus.IsTamperProtected -eq "True") 
            {
                Write-LogEntry -Message "Tamper Protection is Enabled"
            }
        else 
            {
                Write-LogEntry -Message "Tamper Protection is Disabled"
            }   
        if ($Defenderstatus.IoavProtectionEnabled -eq "True") 
            {
            Write-LogEntry -Message "IOAV Protection is Enabled"
            }
        else 
            {
                Write-LogEntry -Message "IOAV Protection is Disabled"
            }
        if ($Defenderstatus.EnableNetworkProtection -eq "1") 
            {
            Write-LogEntry -Message "Network Protection is Enabled"
            }
        else 
            {
                Write-LogEntry -Message "Network Protection is Disabled"
            }    
        }
        catch [System.Exception] 
            {
                Write-LogEntry -Message "Failed to check status of $Defender"
            }
        }

if ($ATP) {
    $ATPStatus = get-service -displayname "Windows Defender Advanced Threat Protection Service" -ErrorAction SilentlyContinue
    try {
        Write-LogEntry -Message "[Defender ATP]"
    if ($ATPStatus.Status -eq "Running") 
    {
        Write-Logentry -Message "Defender ATP Service running."
    }
    else 
            {
                Write-LogEntry -Message "Defender ATP Service not running."
            }
}
catch [System.Exception] 
            {
                Write-LogEntry -Message "Failed to check status of $ATP"
            }
        }

if($LAPS){
#Get-ADcomputer $PC -prop ms-Mcs-AdmPwd,ms-Mcs-AdmPwdExpirationTime
}

if($ApplicationGuard){
    try {
    Write-LogEntry -Message "[Application Guard]"
    Write-LogEntry -Message "Checking if Windows Defender Application Guard is installed and enabled..." 
    $ApplicationGuardStatus = Get-WindowsOptionalFeature -Online -Featurename Windows-Defender-ApplicationGuard -ErrorAction SilentlyContinue
    if ($ApplicationGuardStatus.State = "Enabled") 
    {
    Write-Logentry -Message "Windows Defender Application Guard is installed and enabled."
    }
    else 
            {
                Write-LogEntry -Message "Windows Defender Application Guard is not enabled..."
            }
    }
            catch [System.Exception] 
            {
                Write-LogEntry -Message "Failed to check status of $ApplicationGuard"
            }
        }

if($Sandbox){
        try {
        Write-LogEntry -Message "[Sandbox]"
        Write-LogEntry -Message "Checking if Windows Sandbox is installed and enabled..." 
        $Sandboxstatus = Get-WindowsOptionalFeature -Online -Featurename Containers-DisposableClientVM -ErrorAction SilentlyContinue
        if ($Sandboxstatus.State = "Enabled") 
        {
        Write-Logentry -Message "Windows Sandbox is installed and enabled."
        }
        else 
                    {
                        Write-LogEntry -Message "Windows Sandbox is not enabled."
                    }
            }
                    catch [System.Exception] 
                    {
                        Write-LogEntry -Message "Failed to check status of $Sandbox"
                    }
                }

if($CredentialGuardPreReq){
try {
    Write-LogEntry -Message "[Credential Guard Pre-requisite]"
    $CGPrereq = Get-WindowsOptionalFeature -Online -Featurename Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
    if ($CGPrereq.state = "Enabled") 
    {
    Write-LogEntry -Message "Credential Guard prerequisite Hyper V is installed and enabled."
    }
    else 
    {
        Write-LogEntry -Message "Hyper-V All is not enabled/installed."
    }
}
    catch [System.Exception] 
    {
        Write-LogEntry -Message "Failed to check status of $CredentialGuardPreReq"
    }
}

if ($CredentialGuard) {
    $CredentialguardStatus = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue
    try {
        Write-LogEntry -Message "[Credential Guard]" 
        if ($CredentialGuardStatus.SecurityServicesRunning -like 1)
    {
        Write-Logentry -Message "Credential Guard Services are running."
    }
    else 
            {
                Write-LogEntry -Message "CredentialGuard Service are not running."
            }
            if ($CredentialGuardStatus.SecurityServicesConfigured -like 1)
            {
                Write-Logentry -Message "Credential Guard is configured."
            }
            else 
                    {
                        Write-LogEntry -Message "Credential Guard is not configured."
                    }
}
catch [System.Exception] 
            {
                Write-LogEntry -Message "Failed to check status of $CredentialGuard"
            }
        }

if ($DeviceGuard) {
    $DevGuardStatus = Get-CimInstance -classname Win32_DeviceGuard -namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue
    try {
        Write-LogEntry -Message "[Device Guard]" 
        if ($DevGuardStatus.CodeIntegrityPolicyEnforcementStatus -like 1)
    {
        Write-Logentry -Message "Device Guard Code Integrity Policy is activated and enforced."
    }
    else 
            {
                Write-LogEntry -Message "Device Guard Code Integrity Policy is not activated."
            }
            if ($DevGuardStatus.SecurityServicesRunning -like 1)
            {
                Write-Logentry -Message "Device Guard services are running."
            }
            else 
                    {
                        Write-LogEntry -Message "Device Guard services are not running."
                    }
}
catch [System.Exception] 
            {
                Write-LogEntry -Message "Failed to check status of $DeviceGuard"
            }
        }       

if ($AttackSurfaceReduction) {
            $p = Get-MpPreference -ErrorAction SilentlyContinue
            $c = Get-MpComputerStatus -ErrorAction SilentlyContinue
            $p = @($p)
            $ASRstatus = ($p += $c)
            try {
                Write-LogEntry -Message "[Attack Surface Reduction]"
                if ($Defenderstatus.EnableNetworkProtection -eq "1") 
            {
            Write-LogEntry -Message "Network Protection is Enabled"
            }
        else 
            {
                Write-LogEntry -Message "Network Protection is Disabled"
            }    
                if ($ASRstatus.AttackSurfaceReductionRules_Actions -eq "2") 
                {
                    Write-LogEntry -Message "Attack Surface Reduction is configured and in audit mode."
                }
                elseif ($ASRstatus.AttackSurfaceReductionRules_Actions -eq "1")
                {
                    Write-LogEntry -Message "Attack Surface Reduction is configured and enforced."
                }
                else 
                {
                    Write-LogEntry -Message "Attack Surface Reduction is not configured."
                }
        }
        catch [System.Exception] 
            {
                Write-LogEntry -Message "Failed to check status of $AttackSurfaceReduction"
            }
        }
        
if ($ControlledFolderAccess) {
    $p = Get-MpPreference -ErrorAction SilentlyContinue
    $c = Get-MpComputerStatus -ErrorAction SilentlyContinue
    $p = @($p)
    $CFAstatus = ($p += $c)
    try {
        Write-LogEntry -Message "Checking status and configuration for Attack Surface Reduction..."
        if ($CFAstatus.EnableControlledFolderAccess -eq "2") 
    {
    Write-LogEntry -Message "Controlled Folder Access is enabled and in audit mode."
    }
    elseif ($CFAstatus.EnableControlledFolderAccess -eq "1") 
    {
        Write-LogEntry -Message "Controlled Folder Access is configured and enforced."
    }
        else 
        {
            Write-LogEntry -Message "Controlled Folder Access is not configured."
        }
}
catch [System.Exception] 
    {
        Write-LogEntry -Message "Failed to check status of $ControlledFolderAccess"
    }
}

if ($ApplicationControl) {
    $APCStatus = "GET LOG FILES Event Viewer under Applications and Services Logs > Microsoft > Windows > Code Integrity > Operational."
    if ($APCStatus.xxxx -eq "??") {
        Write-LogEntry -Message "Checking status and configuration of Application Control..."
    }
    try {
        if (...) 
    {
    Write-LogEntry -Message "..."
    }
        else 
        {
            Write-LogEntry -Message "..."
        }
}
catch [System.Exception] 
    {
        Write-LogEntry -Message "Failed to check status of $ApplicationControl"
    }
}