# FinOps Azure Starter Kit

> Visibilidade inicial de custos Azure para times de TI que precisam começar rápido,
> usando exports, CSV e Power BI, sem depender de ferramenta enterprise paga.
> Sem depender de consultoria para começar.

## O Problema

Times de TI de empresas médias gerenciam custos Azure no escuro.

Você sabe que está gastando. Mas não sabe **onde**, **quanto** e **por quê** o custo subiu no mês passado.

## O que você vai ter ao final

- Exportação de custos via Azure Cost Export → Storage → CSV local
- CSVs normalizados prontos para Power BI
- Relatório de recursos sem tag
- Base para dashboard Power BI com dados reais
- Script base para alerta de budget mensal

## Pré-requisitos

- [Azure CLI](https://learn.microsoft.com/pt-br/cli/azure/install-azure-cli) instalado e autenticado
- PowerShell 7+ (Windows) ou Bash + `jq` + `python3` (Linux/macOS)
- Power BI Desktop (para montar o dashboard)
- Permissões mínimas: `Cost Management Reader` + `Storage Blob Data Reader`

> Veja a lista completa em [docs/prerequisites.md](docs/prerequisites.md).

## Quick Start

```bash
git clone https://github.com/caetanod/finops-azure-starter.git
cd finops-azure-starter
az login
az account set --subscription "NOME_DA_SUA_SUBSCRIPTION"
```

**Windows (PowerShell):**
```powershell
cd scripts/export-costs
./export-costs.ps1 `
  -StorageAccountName "SUA_STORAGE" `
  -ContainerName "finops-exports" `
  -OutputPath "../../dashboard/data/"
```

**Linux/macOS (Bash):**
```bash
cd scripts/export-costs
./export-costs.sh "SUA_STORAGE" "finops-exports"
```

Após executar, os arquivos `costs-by-resource.csv`, `costs-by-resourcegroup.csv` e `untagged-resources.csv` estarão em `dashboard/data/`.

> Quer testar sem ter Azure configurado? Use os dados de exemplo em `dashboard/sample-data/costs-sample.csv`.

## Fluxo técnico

```text
Azure Cost Export
      ↓
Storage Account
      ↓
Script PowerShell / Bash + Python
      ↓
CSVs normalizados em dashboard/data/
      ↓
Power BI Desktop
```

## Estrutura

```text
finops-azure-starter-kit/
├── docs/                    # Documentação completa
├── scripts/
│   ├── export-costs/        # Download e normalização do CSV do Azure
│   ├── budget-alert/        # Criação de budget com alerta de 80%
│   └── tagging/             # Auditoria de tags obrigatórias
└── dashboard/
    ├── data/                # Saída dos scripts (não versionado)
    └── sample-data/         # CSV de exemplo com 301 linhas para testes
```

## Documentação

| Arquivo | Conteúdo |
|---|---|
| [docs/prerequisites.md](docs/prerequisites.md) | Ferramentas, permissões RBAC e acessos mínimos necessários |
| [docs/setup-guide.md](docs/setup-guide.md) | Passo a passo: configurar Azure Cost Export e executar o primeiro script |
| [docs/architecture.md](docs/architecture.md) | Diagrama do fluxo e decisões técnicas do MVP |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Erros comuns (permissões, CSV vazio, formato inesperado) e soluções |
| [docs/faq.md](docs/faq.md) | Perguntas frequentes |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Como contribuir com o projeto |
| [SECURITY.md](SECURITY.md) | Política de segurança e como reportar vulnerabilidades |
| [CHANGELOG.md](CHANGELOG.md) | Histórico de versões |

## Dashboard Power BI

Os scripts geram CSVs prontos para conectar ao Power BI Desktop.

O template de dashboard (`.pbix`) com identidade visual, medidas DAX e páginas pré-configuradas está disponível como kit separado — [entre em contato](mailto:diego.caetano@nstech.com.br) para saber mais.

## Status

- [x] Estrutura base
- [x] Sample data (301 linhas)
- [x] Scripts base (PowerShell + Bash)
- [x] Documentação inicial
- [ ] Dashboard Power BI (`.pbix`) — kit separado
- [ ] Screenshots do dashboard
- [ ] Teste de instalação em máquina limpa

## Licença

MIT — veja [LICENSE](LICENSE).
