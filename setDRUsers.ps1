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
Import-Module .\module\commonIniFunctions.psm1


################################################################################
## Leemos el fichero de entrada
$csvUsers = Import-Csv -Delimiter "," -Path $CSVFileToProcess

################################################################################
## Leemos el fichero de configuracion
$cfgDR = loadConfig ".\cnf\voiceRoutingDR.ini" "ESP"

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
# Array de salida con la info de usuario
$outUserData = @()

################################################################################
# Recorremos la info de los usuarios
foreach ($user in $csvUsers)
{
	## Formateo de parametros:
	# New-AzureADUser -DisplayName "Arana de conferencia" -GivenName "Sala" -SurName "Conferencia99" -UserPrincipalName "sc99@CIE491264.OnMicrosoft.com" -UsageLocation US -MailNickName sc99 -PasswordProfile $PasswordProfile -AccountEnabled $true
	## Nickname
	#$mailNickArray=$user.UPN.Split('@')
	#$mailNickName=$mailNickArray[0] ## Nos creados con la parte del usuario
	##
	$userUPN=$user.UPN
	#$display=$user.display
	#$givenName=$user.display
	#$surName=$user.SKU
	#$usageLocation=$user.location
	$E164number="tel:+"+$user.e164
	#$telephoneNumber="+"+$user.e164
	## Password: Creamos el objeto password
	#$PasswordProfile=New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
	#$PasswordProfile.Password=$user.secret

	## Debug info
	#Write-Output "Parametros: $mailNickName, $userUPN, $display, $givenName, $surName, $usageLocation, $telephoneNumber, $E164number"

	## Licencias: creamos el objeto de licencia
	#$planName=$user.SKU
	#$License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
	#$License.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $planName -EQ).SkuID
	#$LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
	#$LicensesToAssign.AddLicenses = $License

	## BEGIN
	# Info de depuracion
	#Write-Output "Start time: $startTime"
	#Write-Output ">> Construccion de parámetros"
	#Write-Output "Parametros: $mailNickName, $userUPN, $display, $givenName, $surName, $usageLocation"

	$startTime = Get-Date -DisplayHint Date
	Write-Output "Start time: $startTime"
	Write-Output ">> Configuracion del usuario"

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
	#else {
	#	## El usuario no existe, lo creamos y le añadimos licencia
	#	Write-Host ">> Creamos el usuario: $userUPN" -ForegroundColor Green
	#	New-AzureADUser -DisplayName $display -TelephoneNumber $telephoneNumber -GivenName $givenName -SurName $surName -UserPrincipalName $userUPN -UsageLocation $usageLocation -MailNickName $mailNickName -PasswordProfile $PasswordProfile -AccountEnabled $true
	#	Write-Host ">> Asignación de licencia" -ForegroundColor Green
	#	Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $LicensesToAssign
	#}

	if (VerifyTeamsUser $userUPN) {
		## Verificamos si el usuario ya está activo => tarda un rato en activarse
		Write-Host ">> Configuración PSTN (Direct Routing)" -ForegroundColor Blue
		Set-csuser -Identity $userUPN -EnterpriseVoiceEnabled $true -LineURI $E164number 

		Write-Host ">> Configuración directivas de voz" -ForegroundColor Blue
        #Grant-CsOnlineVoiceRoutingPolicy -Identity $userUPN -PolicyName $cfgDR.CsOnlineVoiceRoutingPolicy_name
        Grant-CsTenantDialPlan -Identity $userUPN -PolicyName $cfgDR.CsTenantDialPlan_name
        Grant-CsTeamsCallingPolicy -Identity $userUPN -PolicyName $cfgDR.CsTeamsCallingPolicy_name
        Grant-CsCallingLineIdentity -Identity $userUPN -PolicyName $cfgDR.CsCallingLineIdentity_name
        Grant-CsTeamsCallParkPolicy -Identity $userUPN -PolicyName $cfgDR.CsTeamsCallParkPolicy_name
    
		Write-Host ">> ------------------------------" -ForegroundColor Blue
		$userReadRegistrarPool = Get-CsOnlineUser -Identity $userUPN | Select-Object -Property RegistrarPool
		$userReadLineUri = Get-CsOnlineUser -Identity $userUPN | Select-Object -Property LineUri
		#Get-CsOnlineUser -Identity $userUPN | Format-List RegistrarPool,OnPremLineUriManuallySet,OnPremLineUri,LineUri
		#Write-Host ">> ------------------------------" -ForegroundColor Blue
		$endTime = Get-Date -DisplayHint Date

		## Guardamos la info en el Array de salida para control
		$outUserData+=[pscustomobject]@{startTime=$startTime;userUPN=$userUPN;e164Number=$E164number;
			CsOnlineVoiceRoutingPolicy=$cfgDR.CsOnlineVoiceRoutingPolicy_name;
			CsTenantDialPlan=$cfgDR.CsTenantDialPlan_name;
			CsTeamsCallingPolicy=$cfgDR.CsTeamsCallingPolicy_name;
			CsCallingLineIdentity=$cfgDR.CsCallingLineIdentity_name;
			CsTeamsCallParkPolicy=$cfgDR.CsTeamsCallParkPolicy_name;
			userRegisterPool=$userReadRegistrarPool;
			configuredLineURI=$userReadLineUri;
			endTime=$endTime}
		#Write-Host $outUserData -ForegroundColor Red
	}
	else {
		Write-Host "El usuario todavía no esta disponible en Teams, la activacion de usuarios suele tardar" -ForegroundColor Red
		Write-Host "Vuelve a ejecutar el comando mas tarde" -ForegroundColor Red
	}

	#Write-Host "----------------------------" -ForegroundColor Blue
}

################################################################################
# Recopilamos la info para control
$outUserData | ForEach-Object{ [pscustomobject]$_ } | Export-CSV -Path "outFile\test.csv"