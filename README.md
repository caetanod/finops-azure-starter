# FinOps Azure Starter Kit

> Visibilidade inicial de custos Azure para times de TI que precisam começar rápido,
> usando exports, CSV e Power BI, sem depender de ferramenta enterprise paga.
> Sem depender de consultoria para começar.

## O Problema

Times de TI de empresas médias gerenciam custos Azure no escuro.

Você sabe que está gastando. Mas não sabe **onde**, **quanto** e **por quê** o custo subiu no mês passado.

## O que você vai ter ao final

- Exportação de custos via Azure Cost Export → Storage → CSV local
- CSVs normalizados para Power BI
- Relatório de recursos sem tag
- Base para dashboard Power BI
- Script base para alerta de budget

## Quick Start

```bash
git clone https://github.com/seu-usuario/finops-azure-starter-kit.git
cd finops-azure-starter-kit
az login
az account set --subscription "SUA_SUBSCRIPTION"
```

```powershell
cd scripts/export-costs
./export-costs.ps1 `
  -StorageAccountName "SUA_STORAGE" `
  -ContainerName "finops-exports" `
  -OutputPath "../../dashboard/data/"
```

## Fluxo técnico

```text
Azure Cost Export
      ↓
Storage Account
      ↓
Script PowerShell/Bash
      ↓
CSV local em dashboard/data/
      ↓
Power BI Desktop
```

## Estrutura

```text
finops-azure-starter-kit/
├── docs/
├── scripts/
└── dashboard/
```

## Status

- [x] Estrutura base
- [x] Sample data
- [x] Scripts base
- [x] Docs iniciais
- [ ] Dashboard Power BI
- [ ] Screenshots
- [ ] Teste em máquina limpa
