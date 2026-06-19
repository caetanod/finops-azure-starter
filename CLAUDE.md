# CLAUDE.md — FinOps Azure Starter Kit

## Objetivo do Projeto

Kit de FinOps leve e open-source para times de TI de empresas médias que precisam começar a ter visibilidade de custos Azure de forma rápida, sem ferramentas enterprise pagas e sem consultoria.

O fluxo principal é:
```
Azure Cost Management Export → Storage Account → Scripts (PS/Bash) → CSVs normalizados → Power BI Desktop
```

## Estrutura do Projeto

```
finops-azure-starter-kit/
├── .github/workflows/          # CI/CD via GitHub Actions (lint + validação)
├── .gitattributes              # Normalização de line endings (LF para scripts, CRLF para .csv Windows)
├── docs/
│   ├── architecture.md         # Diagrama e decisões de arquitetura
│   ├── faq.md                  # Perguntas frequentes
│   ├── powerbi.md              # Guia de criação do dashboard: paleta, páginas, DAX
│   ├── prerequisites.md        # Pré-requisitos: az CLI, permissões RBAC, Power BI
│   ├── setup-guide.md          # Passo a passo de instalação e primeira execução
│   └── troubleshooting.md      # Erros comuns e soluções
├── scripts/
│   ├── export-costs/           # Scripts PS + Bash para baixar e normalizar CSV do Azure Storage
│   ├── budget-alert/           # Script PS para criar budget com alerta de 80%
│   └── tagging/                # Script PS para auditar tags obrigatórias nos recursos
├── dashboard/
│   ├── data/                   # Saída dos scripts (ignorado pelo git, só .gitkeep)
│   └── sample-data/            # CSV de exemplo com 301 linhas para testes no Power BI
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
└── LICENSE (MIT)
```

## Stack Tecnológica

| Camada | Tecnologia |
|--------|-----------|
| Cloud | Azure Cost Management, Azure Storage Account, Azure RBAC |
| CLI | Azure CLI (`az`) |
| Scripts | PowerShell 7+ (Windows), Bash + Python (Linux/macOS) |
| Formato intermediário | CSV |
| BI | Power BI Desktop (externo, não incluso) |
| CI/CD | GitHub Actions, PSScriptAnalyzer, ShellCheck |

## Scripts Principais

### `scripts/export-costs/export-costs.ps1`
- Parâmetros: `-StorageAccountName`, `-ContainerName`, `-Directory` (default `raw`), `-OutputPath`
- Valida autenticação Azure CLI
- Baixa o CSV mais recente do Storage
- Valida colunas obrigatórias (`ResourceId`, `CostInBillingCurrency`, etc.)
- Gera 3 CSVs em `dashboard/data/`:
  - `costs-by-resource.csv`
  - `costs-by-resourcegroup.csv`
  - `untagged-resources.csv`

### `scripts/export-costs/export-costs.sh`
- Equivalente Bash do script acima, para Linux/macOS
- Argumentos posicionais: `StorageAccountName ContainerName [Directory] [OutputPath]`
- Dependências externas: `az`, `jq`, `python3` (checadas na inicialização)
- Normalização dos CSVs feita via Python3 embutido (heredoc inline)
- Gera os mesmos 3 CSVs em `dashboard/data/`

### `scripts/budget-alert/create-budget-alert.ps1`
- Cria budget mensal no Azure com alerta em 80% do valor definido

### `scripts/tagging/validate-tags.ps1`
- Audita todos os recursos da subscription
- Tags obrigatórias padrão: `environment`, `cost-center`, `owner`
- Exporta relatório CSV de recursos sem tag

## Dados de Saída (Colunas Normalizadas)

```
ResourceName, ResourceGroup, SubscriptionName, Environment,
ResourceType, Cost, Currency, UsageDate, Owner, TagsStatus
```

## Convenções

- Idioma do projeto: **Português (pt-BR)** — docs e comentários de usuário final
- Idioma do código: **Inglês** — nomes de variáveis, funções, parâmetros
- Sem servidores, sem banco de dados — toolkit local + Azure CLI
- Credenciais via Azure CLI (`az login`) — nunca como parâmetros de script
- Arquivos `.env` e `*.secret` estão no `.gitignore`

## CI/CD

O workflow `.github/workflows/validate-scripts.yml` roda em pushes para `main`/`develop` e PRs:
1. **PSScriptAnalyzer** — lint em todos os `.ps1`
2. **ShellCheck** — lint no `.sh`
3. **Validação de dados** — checa header do `costs-sample.csv`

## O que está pendente (roadmap MVP)

- [ ] Arquivo `.pbix` com dashboard Power BI
- [ ] Screenshots do dashboard para documentação
- [ ] Teste de instalação em máquina limpa
- [ ] Pipeline de exportação automatizada (trigger agendado)
