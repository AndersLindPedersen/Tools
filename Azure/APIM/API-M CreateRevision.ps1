Param(
  [string] $apiManagementRg,
  [string] $apiManagementName,
  [string] $baseUrl,
  [string] $swaggerPath,
  [string] $apiPath,
  [string] $apiId,
  [bool]   $releaseRevision
)

$apiMgmtContext = New-AzureRmApiManagementContext -ResourceGroupName "$apiManagementRg" -ServiceName "$apiManagementName"
Write-verbose "$apiMgmtContext" -verbose

$revision =  (Get-Date).ToString("yyyyMMddhhmmss")
Write-Host 'Creating new revision for $apiId named $revision'
New-AzureRmApiManagementApiRevision -Context $apiMgmtContext -ApiId $apiId -ApiRevision  $revision

$swaggerUrl = $baseUrl + '/' + $swaggerPath
$filename = '$apiId.json'
Write-verbose "Downloading OpenAPI file from $swaggerUrl" -verbose
wget $swaggerUrl  -outfile $filename

Write-Host "Importing OpenAPI file to new revision $revision"
Import-AzureRmApiManagementApi -Context $apiMgmtContext -ApiId $apiId -SpecificationFormat "Swagger" -SpecificationPath $filename -Path $apiPath -ErrorAction Stop -ApiRevision $revision
Write-Host "Completed importing to new revision $revision"

If($releaseRevision -eq $false){
    Write-warning "Existing without releasing revision"
    exit
}

Write-Host 'Releasing new revision'
$release = New-AzureRmApiManagementApiRelease -Context $apiMgmtContext -ApiId $apiId  -ApiRevision $revision

Write-Host 'Removing previous revisions'
$revisionList = Get-AzureRmApiManagementApiRevision -Context $apiMgmtContext -ApiId $apiId 
foreach ($item in $revisionList)
{
	if ($item.ApiRevision -ne $revision)
	{
		Remove-AzureRmApiManagementApiRevision -Context $apiMgmtContext -ApiId $apiId -ApiRevision $item.ApiRevision
	}
}