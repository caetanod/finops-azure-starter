param(
    [Parameter(Mandatory=$true)][string]$StorageAccountName,
    [Parameter(Mandatory=$true)][string]$ContainerName,
    [Parameter(Mandatory=$false)][string]$Directory = "raw",
    [Parameter(Mandatory=$false)][string]$OutputPath = "../../dashboard/data/"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI não encontrado. Instale e execute az login."
}

$account = az account show --output json | ConvertFrom-Json
if (-not $account.id) {
    throw "Nenhuma conta Azure autenticada. Execute az login."
}

New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
$tempPath = Join-Path $OutputPath "_raw"
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

$blobs = az storage blob list `
    --account-name $StorageAccountName `
    --container-name $ContainerName `
    --auth-mode login `
    --output json | ConvertFrom-Json

$csvBlobs = $blobs | Where-Object { $_.name -like "*.csv" -and $_.name -like "$Directory*" }

if (-not $csvBlobs) {
    throw "Nenhum CSV encontrado. Verifique Cost Export, Storage, container, directory e permissões."
}

$latestBlob = $csvBlobs | Sort-Object { $_.properties.lastModified } -Descending | Select-Object -First 1
$rawFile = Join-Path $tempPath "azure-cost-export.csv"

az storage blob download `
    --account-name $StorageAccountName `
    --container-name $ContainerName `
    --name $latestBlob.name `
    --file $rawFile `
    --auth-mode login `
    --overwrite true | Out-Null

$data = Import-Csv $rawFile
if (-not $data) { throw "CSV baixado está vazio." }

$columns = $data[0].PSObject.Properties.Name
$required = @("ResourceId","ResourceGroupName","CostInBillingCurrency","BillingCurrencyCode","UsageDate")
$missing = $required | Where-Object { $_ -notin $columns }
if ($missing) { throw "CSV em formato inesperado. Colunas ausentes: $($missing -join ', ')" }

$normalized = foreach ($row in $data) {
    [PSCustomObject]@{
        ResourceName = if ($row.ResourceId) { ($row.ResourceId -split "/")[-1] } else { "unknown" }
        ResourceGroup = $row.ResourceGroupName
        SubscriptionName = $account.name
        Environment = "Unknown"
        ResourceType = $row.ResourceType
        Cost = [decimal]$row.CostInBillingCurrency
        Currency = $row.BillingCurrencyCode
        UsageDate = $row.UsageDate
        Owner = "unknown"
        TagsStatus = if ([string]::IsNullOrWhiteSpace($row.Tags)) { "MissingTags" } else { "Tagged" }
    }
}

$normalized | Export-Csv (Join-Path $OutputPath "costs-by-resource.csv") -NoTypeInformation -Encoding UTF8
$normalized | Group-Object ResourceGroup | ForEach-Object {
    [PSCustomObject]@{ ResourceGroup=$_.Name; Cost=($_.Group | Measure-Object Cost -Sum).Sum; Currency=($_.Group[0].Currency) }
} | Export-Csv (Join-Path $OutputPath "costs-by-resourcegroup.csv") -NoTypeInformation -Encoding UTF8
$normalized | Where-Object TagsStatus -eq "MissingTags" | Export-Csv (Join-Path $OutputPath "untagged-resources.csv") -NoTypeInformation -Encoding UTF8

Write-Host "Arquivos gerados em $OutputPath" -ForegroundColor Green
