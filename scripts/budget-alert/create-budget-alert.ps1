param(
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][decimal]$BudgetAmount,
    [Parameter(Mandatory=$true)][string]$AlertEmail,
    [string]$BudgetName = "finops-monthly-budget"
)
az account set --subscription $SubscriptionId
$startDate = (Get-Date -Day 1).ToString("yyyy-MM-dd")
$endDate = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
az consumption budget create `
  --budget-name $BudgetName `
  --amount $BudgetAmount `
  --category Cost `
  --time-grain Monthly `
  --start-date $startDate `
  --end-date $endDate `
  --notifications "Actual_GreaterThan_80_Percent={enabled:true,operator:GreaterThan,threshold:80,contactEmails:['$AlertEmail']}" `
  --output table
