# data/ — Política de Migração Incremental

Os dados de análise (arquivos `.rds`) vivem originalmente em um projeto R separado, não versionado. Eles são copiados para dentro deste repositório **um de cada vez, sob demanda**, apenas quando um capítulo específico precisa ativamente deles — não há migração em bloco.

## Regras

- **Nunca referenciar o caminho de origem em código versionado.** Copie o arquivo `.rds` específico para `data/raw/` (ou `data/processed/`, se já derivado) antes de usá-lo em qualquer script — caminhos absolutos são proibidos em qualquer arquivo rastreado (`.claude/rules/content-invariants.md`, INV-10).
- `data/raw/` — cópias brutas dos `.rds` de origem, sem transformação.
- `data/processed/` — dados derivados/limpos, gerados por scripts deste repositório.
- Ambas as pastas são ignoradas pelo git (ver `.gitignore`) — apenas este README e os `.gitkeep` são versionados.

## Como migrar um arquivo quando ele for necessário

1. Identificar o `.rds` necessário no projeto de origem.
2. Copiar para `data/raw/` (nome do arquivo preservado).
3. Escrever/ajustar o script R em `scripts/R/` para ler de `data/raw/` via caminho relativo (`here::here("data", "raw", "arquivo.rds")`).
4. Documentar a origem e o propósito do arquivo neste README ou no cabeçalho do script.
