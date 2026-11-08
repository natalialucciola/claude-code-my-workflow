# Página "Estado dos Capítulos" atualizada a cada commit

**Status:** COMPLETED (2026-11-08)
**Página:** https://claude.ai/artifact/8HGZSw58Vv8Lq9tmhjKsPc

## Pedido da autora

1. Atualizar a página a cada commit que mexa no conteúdo da tese.
2. Na página, links para abrir o `.qmd` e o HTML de leitura de cada capítulo.

## Restrição de desenho

Um hook de git não consegue publicar a página: só Claude chama a ferramenta de publicação. Por isso a atualização passa por uma sessão do Claude Code:

- **Hook PostToolUse (Bash):** depois de um `git commit`/`merge`/`pull`/`cherry-pick`/`rebase`/`revert` feito por Claude no `main`, se o último commit do `main` nos caminhos da tese for diferente do último publicado, o hook injeta a instrução de republicar.
- **Hook SessionStart (startup|resume):** cobre commits feitos fora do Claude (terminal, `!`, GitHub). Ao abrir uma sessão no `main`, a mesma checagem roda.
- O estado (último commit publicado) fica em `.claude/state/estado-capitulos.json`, no diretório comum do git, compartilhado entre worktrees.

## Peças

| Arquivo | Papel |
|---|---|
| `quality_reports/estado-capitulos/capitulos.json` | Dados qualitativos por capítulo (pergunta, status, pendências, próxima ação, fontes) — Claude atualiza quando o commit muda o estado do capítulo |
| `scripts/estado_capitulos/gerar.py` | Gera a página em `quality_reports/estado-capitulos/_site/` (gitignored): fatos automáticos (palavras, seções, TODOs, último commit), cópia do livro renderizado (`livro/`) e dos `.qmd` (`fonte/`), e `publicar.json` com o mapa de arquivos; modos `--hook post|sessao` e `--marcar-publicado` |
| `scripts/estado_capitulos/template.html` | Modelo visual da página |
| `scripts/estado_capitulos/README.md` | Procedimento de republicação que o hook manda seguir |
| `.claude/settings.json` | Os dois hooks |

## Links na página

- **Ler:** HTML do capítulo renderizado pelo Quarto, publicado junto com a página (`livro/chapters/*.html`) — abre para quem tem acesso à página.
- **.qmd:** cópia do fonte publicada como texto (`fonte/*.qmd`).
- **GitHub:** o arquivo no repositório privado (só para quem tem acesso ao repo).
