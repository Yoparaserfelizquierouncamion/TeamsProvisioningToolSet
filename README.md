# TeamsProvisioningToolSet
Scripts de provisión para Microsoft Teams

## ########################################################################
## setDRUsers.ps1: Set Direct Routing Users
##
## Descripción: Ejecuta los siguientes comandos para un usuario
#	Set-CsUser -Identity user@dominio.es -EnterpriseVoiceEnabled $true -HostedVoiceMail $true -OnPremLineURI tel:+34876247689
#	Grant-CsOnlineVoiceRoutingPolicy -Identity user@dominio.es -PolicyName "VoiceRoutingPolicy1"
#	Grant-CsTenantDialPlan -Identity user@dominio.es -PolicyName DP.STA-INTL-NOPREMIUM
#	Grant-CsTeamsCallingPolicy -PolicyName "CP-1" -Identity user@dominio.es
#	Grant-CsCallingLineIdentity -Identity "user@dominio.es" -PolicyName "CI-1"
#	Grant-CsTeamsCallParkPolicy -Identity "user@dominio.es" -PolicyName "CPARK-1"
#
## Parametros de entrada:
## Fichero csv con el listado de los usuarios a configurar
## Se puede ver el formato del CSV en el fichero de ejemplo
# 
## Requisitos: Estar autenticado en MicrosoftTeams y AzureAd
# Connect-MicrosoftTeams
# Connect-AzureAd 
#
## Configuración:
# cnf/common.ini: Es un fichero con comentarios auto-explicativos
#
## Salida:
# Genera un fichero de salida con los usuarios que han sido modificados y los datos modificados
# 
.\setDRUsers.ps1 .\tmp\csv-setDRUser.csv