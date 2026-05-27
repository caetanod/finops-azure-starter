# Setup Guide

## 1. Configurar Azure Cost Export

Portal Azure → Cost Management → Exports → Add

Configuração recomendada:

| Campo | Valor |
|---|---|
| Nome | finops-export-mensal |
| Tipo | Monthly cost by resource |
| Container | finops-exports |
| Directory | raw |

Depois clique em **Run now**.

## 2. Executar script

```powershell
cd scripts/export-costs
./export-costs.ps1 `
  -StorageAccountName "SUA_STORAGE" `
  -ContainerName "finops-exports" `
  -OutputPath "../../dashboard/data/"
```
