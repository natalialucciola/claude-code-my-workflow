# Página "Estado dos Capítulos"

Página privada no claude.ai que resume cada capítulo da tese (pergunta, estrutura, código, prosa, plano, próxima ação) e dá acesso direto ao texto:

- **Ler (HTML):** o capítulo renderizado pelo Quarto, publicado junto com a página.
- **Fonte (.qmd):** o arquivo-fonte, publicado como texto.
- **GitHub:** o arquivo no repositório privado.

Endereço e demais dados: `quality_reports/estado-capitulos/capitulos.json` (campo `artifact_url`).

## Quando a página é atualizada

Dois hooks em `.claude/settings.json` chamam `gerar.py --hook ...`:

| Hook | Quando avisa |
|---|---|
| `PostToolUse` (Bash) | Logo depois de Claude rodar `git commit`, `merge`, `pull`, `cherry-pick`, `rebase` ou `revert` no `main` |
| `SessionStart` (startup, resume) | Ao abrir uma sessão no `main` — cobre commits feitos fora do Claude (terminal, `!`, GitHub, nuvem) |

Os dois só avisam se o último commit do `main` que toca os caminhos da tese (lista `WATCH` em `gerar.py`: capítulos, figuras, `_quarto.yml`, `.bib`, `explorations/`, `scripts/R/`, `quality_reports/plans/`, `capitulos.json`) for diferente do último publicado. O registro fica em `.claude/state/estado-capitulos.json` no checkout principal (não versionado). O aviso chega a Claude como contexto; quem republica é Claude, porque só ele chama a ferramenta de publicação. Sessões em worktree ou em outro branch não avisam: a página reflete o `main`.

## Procedimento de republicação (para Claude)

1. **Revisar os dados qualitativos.** Ver o que o commit mudou (`git log -1 --stat main`). Se mudou o estado de algum capítulo (nova seção, código rodado, pendência resolvida, novo capítulo no `_quarto.yml`), atualizar o capítulo em `quality_reports/estado-capitulos/capitulos.json`: `status` (`ok` | `part` | `no` | `na`), `o_que_existe`, `pendencias`, `proxima_acao`, `acao_curta`, `fontes`. Palavras, seções, TODOs e data da última alteração são calculados sozinhos. Se `capitulos.json` mudar, commitá-lo antes do passo 2.
2. **Gerar:** `python scripts/estado_capitulos/gerar.py` (renderiza o livro; `--sem-render` reaproveita `Quarto/thesis/_book/`). Saída em `quality_reports/estado-capitulos/_site/` (não versionada), com `publicar.json`.
3. **Publicar** com a ferramenta Artifact, usando `publicar.json`:
   - em uma sessão que ainda não publicou esta página: primeiro `action: "read"` com o `url`, depois `action: "list"`, `scope: "files"`, com o mesmo `url` (a publicação exige ter visto a página e os arquivos);
   - `action: "publish"`, `url` = `url` do manifesto, `file_path` = `file_path` do manifesto, `files` = `files` do manifesto (entradas `null` removem arquivos que saíram). Sem `icon`.
   - `.qmd` vai com `contentType: "text/plain"` exato (sem `charset`), como já está no manifesto.
   - Se a publicação for recusada porque há uma versão mais nova publicada em outro lugar (outra sessão ou edição pela página), levar as mudanças dessa versão para `scripts/estado_capitulos/template.html` (ou para `capitulos.json`, se forem de conteúdo) — nunca só para `_site/`, que é apagado a cada geração —, regenerar e publicar de novo.
4. **Marcar:** `python scripts/estado_capitulos/gerar.py --marcar-publicado`.
5. **Avisar** a autora em uma linha, com o link.

`python scripts/estado_capitulos/gerar.py --status` diz se a página está em dia.
