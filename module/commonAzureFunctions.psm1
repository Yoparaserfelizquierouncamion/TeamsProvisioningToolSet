<#PSScriptInfo

. REFERENCIA
=> creación de cuentas AzureAD
https://docs.microsoft.com/en-us/microsoft-365/enterprise/create-user-accounts-with-microsoft-365-powershell?view=o365-worldwide
=> Habilitar direct routing
https://docs.microsoft.com/en-us/microsoftteams/direct-routing-enable-users

#>

################################################################################################################################################################
## Funcion: Check-ADConnection
Function VerifyAADConn ()
{
  ## check if azure AD connection is already established (if not quit function)
        try {
            Write-Host "Checking if Azure AD Connection is established..." -ForegroundColor Yellow
            $azconnect = Get-AzureADTenantDetail -ErrorAction Stop
            $displayname = ($azconnect).DisplayName
            write-host "Azure AD connection established to Tenant: $displayname " -ForegroundColor Green
            }
        catch {
            write-host "No connection to Azure AD was found. Please use Connect-AzureAD command" -ForegroundColor Red
            break
        	}
}

################################################################################################################################################################
## Funcion: Check-AzureADUser
Function VerifyAzureADUser()
{
  param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName
 )

    ## check if user exists in azure ad 
    #check if upn is not empty    
    if($UserPrincipalName){
		$UserPrincipalName = $UserPrincipalName.ToString()
        $azureaduser = Get-AzureADUser -All $true | Where-Object {$_.Userprincipalname -eq "$UserPrincipalName"}
        #check if something found    
        if($azureaduser){
			#Write-Host "User: $UserPrincipalName was found in $displayname AzureAD." -ForegroundColor Green
            return $true
            }
            else{
                #Write-Host "User $UserPrincipalName was not found in $displayname Azure AD " -ForegroundColor Red
                return $false
                             }
            }
}

################################################################################################################################################################
## Funcion: VerifyADUserLicense
Function VerifyADUserLicense()
{
  param(
    [Parameter(Mandatory=$true)][string]$UserPrincipalName
 )

    ## check if user exists in azure ad 
    #check if upn is not empty    
    if($UserPrincipalName){
		$UserPrincipalName = $UserPrincipalName.ToString()
        $azureaduser = Get-AzureADUserLicenseDetail -ObjectId $UserPrincipalName
        #check if something found    
        if($azureaduser){
			#Write-Host "User: $UserPrincipalName was found in $displayname AzureAD." -ForegroundColor Green
            return $true
            }
            else{
                #Write-Host "User $UserPrincipalName was not found in $displayname Azure AD " -ForegroundColor Red
                return $false
                             }
            }
}


