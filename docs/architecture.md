# Arquitetura

## Fluxo do MVP

```text
Azure Cost Export → Storage Account → Script → CSV local → Power BI
```

## Decisão técnica

O MVP usa CSV como camada intermediária para reduzir complexidade e evitar backend.
