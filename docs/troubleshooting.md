# Troubleshooting

## Fluxo esperado

```text
Azure Cost Export → Storage Account → Script baixa CSV → CSV local → Power BI
```

## 1. Permissões insuficientes

Verifique Cost Management Contributor e Storage Blob Data Reader.

## 2. Arquivo do export não aparece no Storage

Valide:
- Run now
- Storage Account
- Container
- Directory
- Permissão no Storage

```bash
az storage blob list --account-name SUA_STORAGE --container-name finops-exports --auth-mode login -o table
```

## 3. Power BI não atualiza

Verifique se os CSVs estão em `dashboard/data/`.

## 4. CSV em formato inesperado

Colunas esperadas:
- ResourceId
- ResourceGroupName
- CostInBillingCurrency
- BillingCurrencyCode
- UsageDate
