#  Get-AzureADSubscribedSku | select SkuPartNumber,SkuId
#
#  SkuPartNumber     SkuId
#  -------------     -----
#  VISIOCLIENT       c5928f49-12ba-48f7-ada3-0d743a3601d5
#  STREAM            1f2f344a-700d-42c9-9427-5cea1d5d7ba6
#  WINDOWS_STORE     6470687e-a428-4b7a-bef2-8a291ad947c9
#  *ENTERPRISEPACK    6fd2c87f-b296-42f0-b197-1e91e994b900
#  FLOW_FREE         f30db892-07e9-47e9-837c-80727f46fd3d
#  POWERAPPS_VIRAL   dcb1a3ae-b33f-4487-846a-a640262fadf4
#  POWER_BI_STANDARD a403ebcc-fae0-4ca2-8c8c-7a907fd6c235
#  *EMS               efccb6f7-5641-4e0e-bd10-b4976e1bf68e
#  AAD_PREMIUM       078d2b04-f1bd-4111-bbd4-b4b1b354cef4
#
#  $licenses = Get-AzureADSubscribedSku
#  $licenses[3].ServicePlans | select ServicePlanName,ServicePlanId
#
#  ENTERPRISEPACK
#
#  ServicePlanName       ServicePlanId
#  ---------------       -------------
#  BPOS_S_TODO_2         c87f142c-d1e9-4363-8630-aaea9c4d9ae5
#  FORMS_PLAN_E3         2789c901-c14e-48ab-a76a-be334d9d793a
#  STREAM_O365_E3        9e700747-8b1d-45e5-ab8d-ef187ceec156
#  Deskless              8c7d2df8-86f0-4902-b2ed-a0458298f3b3
#  FLOW_O365_P2          76846ad7-7776-4c40-a281-a386362dd1b9
#  POWERAPPS_O365_P2     c68f8d98-5534-41c8-bf36-22fa496fa792
#  TEAMS1                57ff2da0-773e-42df-b2af-ffb7a2317929
#  PROJECTWORKMANAGEMENT b737dad2-2f6c-4c65-90e3-ca563267e8b9
#  SWAY                  a23b959c-7ce8-4e57-9140-b90eb88a9e97
#  INTUNE_O365           882e1d05-acd1-4ccb-8708-6ee03664b117
#  YAMMER_ENTERPRISE     7547a3fe-08ee-4ccb-b430-5077c5041653
#  RMS_S_ENTERPRISE      bea4c11e-220a-4e6d-8eb8-8ea15d019f90
#  OFFICESUBSCRIPTION    43de0ff5-c92c-492b-9116-175376d08c38
#  MCOSTANDARD           0feaeb32-d00e-4d66-bd5a-43b5b83db82c
#  SHAREPOINTWAC         e95bec33-7c88-4a70-8e19-b10bd9d0c014
#  SHAREPOINTENTERPRISE  5dbe027f-2339-4123-9542-606e4d348a72
#  EXCHANGE_S_ENTERPRISE efb87545-963c-4e0d-99df-69c6916d9eb0
#
#  $licenses[7].ServicePlans | select ServicePlanName,ServicePlanId
#
#  EMS
#
#  ServicePlanName       ServicePlanId
#  ---------------       -------------
#  EXCHANGE_S_FOUNDATION 113feb6c-3fe4-4440-bddc-54d774bf0318
#  ADALLOM_S_DISCOVERY   932ad362-64a8-4783-9106-97849a1a30b9
#  RMS_S_PREMIUM         6c57d4b6-3b23-47a5-9bc9-69f17b4947b3
#  INTUNE_A              c1ec4a95-1f05-45b3-a911-aa3fa01094f5
#  RMS_S_ENTERPRISE      bea4c11e-220a-4e6d-8eb8-8ea15d019f90
#  AAD_PREMIUM           41781fb2-bc02-4b7c-bd55-b576c07bb09d
#  MFA_PREMIUM           8a256a2b-b617-496d-b51b-e76466e88db0

# Users that are enabled and have Enterprise E3 assigned
$users = Get-AzureADUser -All $true | where {$_.AccountEnabled -eq $true -and $_.AssignedLicenses.SkuId -eq '6fd2c87f-b296-42f0-b197-1e91e994b900'}

# Users that are enabled, have Enterprise E3 assigned, and have Enterprise Mobility + Security E3 unassigned
$users = Get-AzureADUser -All $true | where {$_.AccountEnabled -eq $true -and $_.AssignedLicenses.SkuId -eq '6fd2c87f-b296-42f0-b197-1e91e994b900' -and !($_.AssignedLicenses.SkuId -eq 'efccb6f7-5641-4e0e-bd10-b4976e1bf68e')}

# Assign EMS E3 licensing
foreach($user in $users){
  Set-AzureADUser -ObjectId $user.ObjectId -UsageLocation US
  $SkuFeaturesToEnable = @("MFA_PREMIUM","INTUNE_A","AAD_PREMIUM")
  $StandardLicense = Get-AzureADSubscribedSku | Where {$_.SkuId -eq "efccb6f7-5641-4e0e-bd10-b4976e1bf68e"}
  $SkuFeaturesToDisable = $StandardLicense.ServicePlans | ForEach-Object { $_ | Where {$_.ServicePlanName -notin $SkuFeaturesToEnable }}
  $License = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
  $License.SkuId = $StandardLicense.SkuId
  $License.DisabledPlans = $SkuFeaturesToDisable.ServicePlanId
  $LicensesToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
  $LicensesToAssign.AddLicenses = $License
  Set-AzureADUserLicense -ObjectId $user.ObjectId -AssignedLicenses $LicensesToAssign
  }
