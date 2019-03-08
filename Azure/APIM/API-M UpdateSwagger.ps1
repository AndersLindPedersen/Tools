Param(
  [string] $apiManagementRg,
  [string] $apiManagementName,
  [string] $baseUrl,
  [string] $swaggerPath,
  [string] $apiPath,
  [string] $apiId,
  [string] $apiName
)

$apiMgmtContext = New-AzureRmApiManagementContext -ResourceGroupName "$apiManagementRg" -ServiceName "$apiManagementName"
Write-verbose "$apiMgmtContext" -verbose

$swaggerUrl = $baseUrl + '/' + $swaggerPath
Write-verbose "Downloading OpenAPI file from $swaggerUrl" -verbose
wget $swaggerUrl  -outfile "apiswagger.json"

Write-verbose "Updating API Mgmt with OpenAPI Spec for $apiName $apiId" -verbose
Import-AzureRmApiManagementApi -Context $apiMgmtContext -SpecificationFormat "Swagger" -SpecificationPath "apiswagger.json" -Path "$apiPath" -ApiId "$apiId"

Write-verbose "Ensure https only - if backend API does not support https we want it on incoming request to APIM" -verbose
Set-AzureRmApiManagementApi -Context $apiMgmtContext -ApiId "$apiId" -Protocols @('https') -ServiceUrl "$baseUrl" -Name "$apiName"