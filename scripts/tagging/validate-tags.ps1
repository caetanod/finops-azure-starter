param(
    [string]$OutputPath = "../../dashboard/data/untagged-resources.csv",
    [string[]]$RequiredTags = @("environment","cost-center","owner")
)
$resources = az resource list --output json | ConvertFrom-Json
$result = foreach ($resource in $resources) {
    $tags = $resource.tags
    $missing = @()
    foreach ($tag in $RequiredTags) {
        if (-not $tags -or -not $tags.PSObject.Properties.Name.Contains($tag)) { $missing += $tag }
    }
    if ($missing.Count -gt 0) {
        [PSCustomObject]@{
            ResourceName=$resource.name
            ResourceGroup=$resource.resourceGroup
            ResourceType=$resource.type
            MissingTags=($missing -join "|")
            ResourceId=$resource.id
        }
    }
}
New-Item -ItemType Directory -Path (Split-Path $OutputPath) -Force | Out-Null
$result | Export-Csv $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Relatório gerado: $OutputPath"
