Function Get-TPM(){
    <#
    .DESCRIPTION
    Checks if the TPM is enabled and configured correctly in the device.
    
    .EXAMPLE
    Get-TPM
    #>

    #Variable
    $TPMStatus = (Get-CIMClass -Namespace ROOT\CIMV2\Security\MicrosoftTpm -Class Win32_Tpm -ErrorAction silentlycontinue)
        try {
           
            try {
                Write-LogEntry -Message "***[TPM]***"
                if ($TPMStatus.isenabled -eq "True")
                {                
                Write-LogEntry -Type Success -Message "TPM-chip is enabled and configured correctly in $PC"
                }
                    else  
                    {
                        Write-LogEntry -Message "TPM is not enabled and not configured correctly in $PC"
                    }
                }
                catch [System.Exception] 
                    {
                        Write-LogEntry -Message "Failed to check status of $TPM"
                    }
                }
            
        catch {
            Write-Error $_.Exception 
            break
        }
}