# Dashboard Power BI — FinOps Azure Starter Kit

Guia para criar um dashboard de FinOps conectado aos CSVs gerados pelos scripts deste kit.

---

## Pré-requisitos

- [Power BI Desktop](https://powerbi.microsoft.com/pt-br/desktop/) instalado (gratuito)
- CSVs gerados em `dashboard/data/` — ou use `dashboard/sample-data/costs-sample.csv` para testes

---

## 1. Identidade visual

### Paleta de cores

Use estas cores em todos os visuais para manter consistência:

| Papel | Cor | Hex |
|---|---|---|
| Primário (barras, linhas principais) | Azul Azure | `#0078D4` |
| Destaque / custo alto | Âmbar | `#F77F00` |
| Positivo / economia | Verde-água | `#44BBA4` |
| Alerta / acima do budget | Vermelho suave | `#E63946` |
| Secundário (barras alternadas) | Azul claro | `#48CAE4` |
| Fundo do canvas | Cinza frio claro | `#F0F4F8` |
| Fundo dos cartões | Branco | `#FFFFFF` |
| Texto principal | Azul-marinho escuro | `#1A1A2E` |
| Texto secundário / rótulos | Cinza médio | `#6B7280` |

> Essa paleta usa o azul Azure como âncora (familiar ao público-alvo) e âmbar para custo — associação natural com dinheiro/atenção — sem nunca sobrecarregar a visão.

### Aplicar como tema

1. No Power BI Desktop, vá em **Exibição → Temas → Personalizar tema atual**
2. Configure as cores dos dados na ordem da tabela acima
3. Salve como `.json` para reutilizar (veja template abaixo)

**Template de tema (`finops-theme.json`):**

```json
{
  "name": "FinOps Azure",
  "dataColors": [
    "#0078D4",
    "#F77F00",
    "#44BBA4",
    "#E63946",
    "#48CAE4",
    "#8338EC",
    "#3A86FF",
    "#06D6A0"
  ],
  "background": "#F0F4F8",
  "foreground": "#1A1A2E",
  "tableAccent": "#0078D4",
  "visualStyles": {
    "*": {
      "*": {
        "fontFamily": [{ "value": "Segoe UI" }]
      }
    }
  }
}
```

Para aplicar: **Exibição → Temas → Procurar temas** → selecione o arquivo `.json`.

---

## 2. Conectar os dados

### Opção A — Dados reais (após rodar os scripts)

1. **Página inicial → Obter dados → Texto/CSV**
2. Selecione `dashboard/data/costs-by-resource.csv`
3. Repita para `costs-by-resourcegroup.csv` e `untagged-resources.csv`
4. Confirme os tipos de coluna:
   - `Cost` → Número decimal
   - `UsageDate` → Data
   - Demais colunas → Texto

### Opção B — Dados de exemplo (testes)

1. **Obter dados → Texto/CSV**
2. Selecione `dashboard/sample-data/costs-sample.csv`

### Relacionamento entre tabelas

Após carregar os 3 CSVs, vá em **Modelo** e verifique que não há relacionamentos automáticos indesejados. As 3 tabelas são independentes — use cada uma em sua respectiva página.

---

## 3. Medidas DAX essenciais

Crie uma tabela auxiliar chamada `_Medidas` e adicione:

```dax
// Custo total do período
Custo Total = SUM('costs-by-resource'[Cost])

// Custo do mês atual
Custo Mês Atual =
CALCULATE(
    SUM('costs-by-resource'[Cost]),
    DATESMTD('costs-by-resource'[UsageDate])
)

// Recursos sem tag
Recursos Sem Tag =
COUNTROWS(
    FILTER('costs-by-resource', 'costs-by-resource'[TagsStatus] = "MissingTags")
)

// % recursos sem tag
% Sem Tag =
DIVIDE([Recursos Sem Tag], COUNTROWS('costs-by-resource'), 0)

// Top resource group por custo
Top RG =
TOPN(1, VALUES('costs-by-resourcegroup'[ResourceGroup]),
    CALCULATE(SUM('costs-by-resourcegroup'[Cost])), DESC)
```

---

## 4. Estrutura de páginas

### Página 1 — Visão Geral

Layout em 3 linhas:

**Linha 1 — KPIs (cartões)**
- Custo Total do período — fonte grande, cor `#0078D4`
- Custo Mês Atual — fonte grande, cor `#F77F00`
- Recursos Sem Tag (número + %) — cor `#E63946` se > 20%
- Total de Resource Groups — cor `#44BBA4`

**Linha 2 — Tendência**
- Gráfico de linhas: `UsageDate` (eixo X) × `Custo Total` (eixo Y)
  - Cor da linha: `#0078D4`
  - Marcadores: ativos
  - Título: "Evolução de Custos"

**Linha 3 — Distribuição**
- Gráfico de rosca: `Environment` → `Cost`
  - Cores: Produção=`#0078D4`, Desenvolvimento=`#48CAE4`, Shared=`#44BBA4`
- Gráfico de barras horizontais: Top 10 `ResourceType` por `Cost`
  - Cor das barras: `#0078D4` → gradiente até `#48CAE4`

---

### Página 2 — Por Resource Group

**Filtro no topo:** segmentação por `SubscriptionName`

**Visual principal:**
- Gráfico de barras verticais: `ResourceGroup` × `Cost`
  - Ordenar por custo decrescente
  - Cor: `#0078D4`, com linha de referência média em `#F77F00` (tracejada)
  - Ativar rótulos de dados

**Visual secundário:**
- Tabela: `ResourceGroup` | `Cost` | `Currency`
  - Formatação condicional em `Cost`: escala branco → `#F77F00` → `#E63946`

---

### Página 3 — Recursos Sem Tag

**Objetivo:** mostrar o impacto financeiro da falta de tags.

**KPIs no topo:**
- Total de recursos sem tag
- Custo acumulado dos recursos sem tag — cor `#E63946`

**Visual principal:**
- Tabela: `ResourceName` | `ResourceGroup` | `ResourceType` | `Cost` | `Owner`
  - Formatação condicional em `Owner`: destacar "unknown" em `#F77F00`
  - Ordenar por `Cost` decrescente

**Visual auxiliar:**
- Gráfico de barras: `ResourceGroup` × contagem de recursos sem tag
  - Cor: `#E63946`

---

### Página 4 — Detalhe por Recurso

**Filtros:**
- Segmentação por `Environment`
- Segmentação por `ResourceType`

**Visual principal:**
- Matriz: `ResourceGroup` (linhas) × `Environment` (colunas) × `Cost` (valores)
  - Formatação condicional: escala azul claro → azul escuro

**Visual secundário:**
- Gráfico de dispersão: `Cost` (eixo X) × `ResourceName` (detalhes)
  - Útil para identificar outliers de custo

---

## 5. Formatação geral dos visuais

Aplique em todos os visuais para consistência:

| Elemento | Configuração |
|---|---|
| Fundo do visual | Branco `#FFFFFF`, cantos arredondados 8px, sombra leve |
| Título | Negrito, `#1A1A2E`, tamanho 13, alinhado à esquerda |
| Eixos | Texto `#6B7280`, tamanho 11 |
| Rótulos de dados | `#1A1A2E`, tamanho 10 |
| Grade | Linhas horizontais apenas, cor `#E5E7EB` |
| Borda do cartão | 1px `#E5E7EB` |

**Dica:** use **Formatar painel → Aplicar configurações a → Todos os visuais** para copiar a formatação de um visual para os demais do mesmo tipo.

---

## 6. Salvar e compartilhar

- Salve o arquivo como `dashboard/finops-dashboard.pbix`
- Para publicar no Power BI Service: **Arquivo → Publicar → Power BI**
- Para compartilhar sem licença Pro: exporte como PDF (**Arquivo → Exportar → PDF**)

---

## Resultado esperado

Ao seguir este guia, você terá um dashboard com:
- Paleta coesa em azul Azure + âmbar + verde-água
- Fundo claro que não cansa durante análises longas
- Hierarquia visual clara: KPIs no topo, detalhe embaixo
- Alertas visuais imediatos para recursos sem tag e custos elevados
