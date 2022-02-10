<#PSScriptInfo
.AUTHOR Jose Antonio Manzano

.TAGS Microsoft Teams, Teams, 

.EXTERNALMODULEDEPENDENCIES
Install-Module -Name MicrosoftTeams
Install-Module -Name AzureAD

.RELEASENOTES
10/02/2022: configuracion de usuarios para DR


. REFERENCIA
=> creación de cuentas AzureAD
https://docs.microsoft.com/en-us/microsoft-365/enterprise/create-user-accounts-with-microsoft-365-powershell?view=o365-worldwide
=> Habilitar direct routing
https://docs.microsoft.com/en-us/microsoftteams/direct-routing-enable-users

. DESCRIPTION:
Para ejecutar el script:
.\addUser.ps1 <fichero CSV con los usuarios>
1- CSV con los usuarios a configurar, consultar el fichero CSV con los campos a configurar

Nota: una vez creado el usuario puden pasar 1-2 horas hasta que podamos configurar la numeración con Set-CsUser
#>

################################################################################################################################################################
################################################################################################################################################################
## Parametros de entrada al programa principal
Param (
	[Parameter(ParameterSetName = "Inputparameter", Position = 0, HelpMessage="Input CSV file: ", Mandatory = $true)]
	[String] $CSVFileToProcess
)

Import-Module .\module\commonAzureFunctions.psm1
Import-Module .\module\commonTeamsFunctions.psm1


################################################################################
## Leemos el fichero de entrada
$csvUsers = Import-Csv -Delimiter "," -Path $CSVFileToProcess

################################################################################
# Captura de credenciales + Sign IN
#$credential = Get-Credential
#Connect-MicrosoftTeams -Credential $credential
#Connect-AzureAd -Credential $credential

################################################################################
# Comprobamos que tenemos conexión con Azure y Microsoft Teams
VerifyAADConn
VerifyTeamsConnection

################################################################################
# Recorremos la info de los usuarios
foreach ($user in $csvUsers)
{
	## Formateo de parametros:
	# New-AzureADUser -DisplayName "Arana de conferencia" -GivenName "Sala" -SurName "Conferencia99" -UserPrincipalName "sc99@CIE491264.OnMicrosoft.com" -UsageLocation US -MailNickName sc99 -PasswordProfile $PasswordProfile -AccountEnabled $true
	## Nickname
	$mailNickArray=$user.UPN.Split('@')
	$mailNickName=$mailNickArray[0] ## Nos creados con la parte del usuario
	##
	$userUPN=$user.UPN
	$display=$user.display
	$givenName=$user.display
	$surName=$user.SKU
	$usageLocation=$user.location
	$E164number="tel:+"+$user.e164
	$telephoneNumber="+"+$user.e164
	## Password: Creamos el objeto password
	$PasswordProfile=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
	$PasswordProfile.Password=$user.secret

	## Debug info
	#Write-Output "Parametros: $mailNickName, $userUPN, $display, $givenName, $surName, $usageLocation, $telephoneNumber, $E164number"

	## Licencias: creamos el objeto de licencia
	$planName=$user.SKU
	$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
	$License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $planName -EQ).SkuID
	$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
	$LicensesToAssign.AddLicenses = $License

	## BEGIN
	# Info de depuracion
	#Write-Output "Start time: $startTime"
	#Write-Output ">> Construccion de parámetros"
	#Write-Output "Parametros: $mailNickName, $userUPN, $display, $givenName, $surName, $usageLocation"

	$startTime = Get-Date -DisplayHint Date
	Write-Output "Start time: $startTime"
	Write-Output ">> Configuración del usuario"

	## Verificamos si el usuario ya está creado
	if (VerifyAzureADUser $userUPN) {
		Write-Host ">> El usuario ya existe: $userUPN" -ForegroundColor Yellow
	
		## Verificamos si tiene licencia
		if (VerifyADUserLicense $userUPN) {
			Write-Output ">> El usuario ya tiene licencia"
		}
		else {
			## Sino tiene licencia la asignamos
			Write-Output ">> Asignación de licencia:$userUPN : $user.SKU"
			Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $LicensesToAssign
		}
	}
	else {
		## El usuario no existe, lo creamos y le añadimos licencia
		Write-Host ">> Creamos el usuario: $userUPN" -ForegroundColor Green
		New-AzureADUser -DisplayName $display -TelephoneNumber $telephoneNumber -GivenName $givenName -SurName $surName -UserPrincipalName $userUPN -UsageLocation $usageLocation -MailNickName $mailNickName -PasswordProfile $PasswordProfile -AccountEnabled $true
		Write-Host ">> Asignación de licencia" -ForegroundColor Green
g		Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $LicensesToAssign

	}

	if (VerifyTeamsUser $userUPN) {
		## Verificamos si el usuario ya está activo => tarda un rato en activarse
		Write-Output ">> Configuración PSTN (Direct Routing)"
		Set-csuser -Identity $userUPN -EnterpriseVoiceEnabled $true -OnPremLineURI $E164number 

		Write-Output ">> ------------------------------" -ForegroundColor Blue
		Get-CsOnlineUser -Identity $userUPN | Format-List RegistrarPool,OnPremLineUriManuallySet,OnPremLineUri,LineUri
		Write-Output ">> ------------------------------" -ForegroundColor Blue
	}
	else {
		Write-Host "El usuario todavía no esta disponible en Teams, la activacion de usuarios suele tardar" -ForegroundColor Red
		Write-Host "Vuelve a ejecutar el comando mas tarde" -ForegroundColor Red
	}

	$endTime = Get-Date -DisplayHint Date
	Write-Output "End time: $endTime"
	Write-Host "----------------------------" -ForegroundColor Blue
}