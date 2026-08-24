# Thesis_Template — Modelo LaTeX Oficial do IESP-UERJ

**Origem:** cópia de `Modelo_de_tese_dissertação_IESP_UERJ/` do projeto separado de análise em R (não versionado, fora deste repositório), copiada em 2026-08-15.

**Status:** referência apenas. Ainda **não está conectada** a nenhum build deste repositório — o Quarto book em `Quarto/thesis/` renderiza somente em HTML por enquanto.

## Conteúdo

| Arquivo | Papel |
| --- | --- |
| `repUERJ.cls` | Classe LaTeX oficial do IESP-UERJ (ABNT) |
| `repUERJformat.sty`, `repUERJpseudocode.sty` | Pacotes de suporte da classe |
| `main.tex` | Documento LaTeX de referência (Overleaf) |
| `abnt-options4.bib`, `bibliografia.bib` | Bibliografia no formato ABNT usada no Overleaf |
| `logo_uerj_cor.jpg`, `logo_uerj_cinza.png`, `marcadagua_uerj_cinza.png` | Logos institucionais |

## Integração futura (fora de escopo por enquanto)

Gerar o PDF final da tese diretamente do Quarto book usando `repUERJ.cls` é um problema técnico separado: o pipeline de PDF do Quarto usa seu próprio template Pandoc/LaTeX, e compatibilizá-lo com uma classe institucional customizada (ABNT, marca d'água, front matter específico) provavelmente exige um format/extension Quarto dedicado. Isso deve virar um plano à parte quando já houver capítulos com conteúdo real para testar a compilação.

Até lá, a bibliografia deste repo usa apenas `Bibliography_base.bib` (raiz do repo) — `abnt-options4.bib`/`bibliografia.bib` não estão mesclados nela.
