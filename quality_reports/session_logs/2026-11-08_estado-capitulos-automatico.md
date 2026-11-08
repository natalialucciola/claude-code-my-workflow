# Sessão 2026-11-07/08 — fusão do sumário e página "Estado dos Capítulos"

**Objetivos:** (1) fundir os branches de exploração pelo novo sumário; (2) publicar um quadro dos capítulos; (3) mantê-lo atualizado a cada commit, com links para o HTML e o `.qmd`.

- 11/07: fusão concluída (plano `2026-11-07_fusao-sumario-tese.md`); `main` em `fffbf0a`, enviado ao `private`; branches e worktrees integrados removidos.
- 11/07: quadro publicado como página privada: https://claude.ai/artifact/8HGZSw58Vv8Lq9tmhjKsPc
- 11/08: automação (plano `2026-11-08_estado-capitulos-automatico.md`). Hook de git não publica página; só Claude publica. Solução: hooks PostToolUse (Bash) e SessionStart que comparam o último commit do `main` nos caminhos da tese com o último publicado e pedem a Claude que republique.
- Problema: neste Windows `python3` é o atalho da Microsoft Store e falha; `python` funciona. Os hooks novos tentam `python3` e caem para `python`. Os hooks antigos do projeto chamam só `python3` e provavelmente falham em silêncio nesta máquina (não corrigido — fora do escopo; avisado à autora).
- Problema: PyYAML ausente → dados em JSON (só biblioteca padrão).
- Problema: outra sessão publicou uma versão da página com campo "Pasta da tese no seu computador" (links `file://`). Fundido no `template.html` para sobreviver às regenerações.
- Problema: `contentType` com `charset` é recusado; `.qmd` vai como `text/plain`.
- Achado: `quality_reports/plans/` e `session_logs/` são ignorados pelo git; o plano e o log da fusão se perderam ao remover o worktree. Recriados e adicionados com `git add -f`, como o plano do `ql-municipio`.
- Achado: o Cap. 05 tem 2 comentários `TODO` (linhas 252 e 261) que o resumo de 11/07 não registrava; a página agora os conta sozinha.
