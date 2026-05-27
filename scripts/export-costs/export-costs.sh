#!/usr/bin/env bash
# Requires: Azure CLI (az), jq, python3
set -euo pipefail

STORAGE_ACCOUNT_NAME="${1:-}"
CONTAINER_NAME="${2:-}"
DIRECTORY="${3:-raw}"
OUTPUT_PATH="${4:-../../dashboard/data/}"

usage() {
    echo "Uso: $0 <StorageAccountName> <ContainerName> [Directory] [OutputPath]"
    echo ""
    echo "Parâmetros:"
    echo "  StorageAccountName  Nome da storage account no Azure (obrigatório)"
    echo "  ContainerName       Nome do container de blobs (obrigatório)"
    echo "  Directory           Prefixo do diretório no container (padrão: raw)"
    echo "  OutputPath          Pasta local de saída (padrão: ../../dashboard/data/)"
    exit 1
}

if [[ -z "$STORAGE_ACCOUNT_NAME" || -z "$CONTAINER_NAME" ]]; then
    usage
fi

# Verifica dependências
for cmd in az jq python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERRO: '$cmd' não encontrado. Instale antes de prosseguir." >&2
        exit 1
    fi
done

# Verifica autenticação Azure
if ! az account show --output json &>/dev/null; then
    echo "ERRO: Nenhuma conta Azure autenticada. Execute 'az login'." >&2
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query "name" -o tsv)

# Cria diretórios de saída
mkdir -p "$OUTPUT_PATH"
TEMP_PATH="${OUTPUT_PATH}/_raw"
mkdir -p "$TEMP_PATH"
RAW_FILE="${TEMP_PATH}/azure-cost-export.csv"

echo "Buscando blobs em ${STORAGE_ACCOUNT_NAME}/${CONTAINER_NAME}/${DIRECTORY}..."

BLOBS_JSON=$(az storage blob list \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$CONTAINER_NAME" \
    --auth-mode login \
    --output json)

# Encontra o CSV mais recente com o prefixo do diretório
LATEST_BLOB=$(echo "$BLOBS_JSON" | jq -r \
    --arg dir "$DIRECTORY" \
    '[.[] | select(.name | startswith($dir)) | select(.name | endswith(".csv"))]
    | sort_by(.properties.lastModified)
    | last
    | .name')

if [[ -z "$LATEST_BLOB" || "$LATEST_BLOB" == "null" ]]; then
    echo "ERRO: Nenhum CSV encontrado. Verifique Cost Export, Storage, container, diretório e permissões." >&2
    exit 1
fi

echo "Baixando: $LATEST_BLOB"

az storage blob download \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --container-name "$CONTAINER_NAME" \
    --name "$LATEST_BLOB" \
    --file "$RAW_FILE" \
    --auth-mode login \
    --overwrite true \
    --output none

if [[ ! -s "$RAW_FILE" ]]; then
    echo "ERRO: CSV baixado está vazio." >&2
    exit 1
fi

echo "Normalizando dados..."

python3 - "$RAW_FILE" "$OUTPUT_PATH" "$SUBSCRIPTION_NAME" <<'PYTHON_EOF'
import csv, sys, os, collections

raw_file     = sys.argv[1]
output_path  = sys.argv[2]
subscription = sys.argv[3]

REQUIRED_COLUMNS = {"ResourceId", "ResourceGroupName", "CostInBillingCurrency", "BillingCurrencyCode", "UsageDate"}

with open(raw_file, newline="", encoding="utf-8-sig") as f:
    reader = csv.DictReader(f)
    rows = list(reader)

if not rows:
    print("ERRO: CSV baixado está vazio.", file=sys.stderr)
    sys.exit(1)

missing = REQUIRED_COLUMNS - set(rows[0].keys())
if missing:
    print(f"ERRO: CSV em formato inesperado. Colunas ausentes: {', '.join(sorted(missing))}", file=sys.stderr)
    sys.exit(1)

normalized = []
for row in rows:
    resource_id = row.get("ResourceId", "")
    resource_name = resource_id.split("/")[-1] if resource_id else "unknown"
    tags_raw = row.get("Tags", "").strip()
    normalized.append({
        "ResourceName":    resource_name,
        "ResourceGroup":   row["ResourceGroupName"],
        "SubscriptionName": subscription,
        "Environment":     "Unknown",
        "ResourceType":    row.get("ResourceType", ""),
        "Cost":            row["CostInBillingCurrency"],
        "Currency":        row["BillingCurrencyCode"],
        "UsageDate":       row["UsageDate"],
        "Owner":           "unknown",
        "TagsStatus":      "MissingTags" if not tags_raw else "Tagged",
    })

def write_csv(path, fieldnames, data):
    os.makedirs(os.path.dirname(path) if os.path.dirname(path) else ".", exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(data)

base_fields = ["ResourceName","ResourceGroup","SubscriptionName","Environment",
               "ResourceType","Cost","Currency","UsageDate","Owner","TagsStatus"]
write_csv(os.path.join(output_path, "costs-by-resource.csv"), base_fields, normalized)

rg_totals = collections.defaultdict(lambda: {"Cost": 0.0, "Currency": ""})
for row in normalized:
    rg = row["ResourceGroup"]
    rg_totals[rg]["Cost"]     += float(row["Cost"]) if row["Cost"] else 0
    rg_totals[rg]["Currency"]  = row["Currency"]
rg_rows = [{"ResourceGroup": k, "Cost": round(v["Cost"], 4), "Currency": v["Currency"]}
           for k, v in sorted(rg_totals.items())]
write_csv(os.path.join(output_path, "costs-by-resourcegroup.csv"),
          ["ResourceGroup","Cost","Currency"], rg_rows)

untagged = [r for r in normalized if r["TagsStatus"] == "MissingTags"]
write_csv(os.path.join(output_path, "untagged-resources.csv"), base_fields, untagged)

print(f"costs-by-resource.csv     → {len(normalized)} linhas")
print(f"costs-by-resourcegroup.csv → {len(rg_rows)} grupos")
print(f"untagged-resources.csv     → {len(untagged)} recursos sem tags")
PYTHON_EOF

echo ""
echo "Arquivos gerados em: ${OUTPUT_PATH}"
