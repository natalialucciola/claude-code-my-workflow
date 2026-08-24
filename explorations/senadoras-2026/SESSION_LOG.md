# Session Log — senadoras-2026

**2026-08-19** — Projeto migrado de `Downloads/senadoras_2026/` (plano de pesquisa montado no app do Claude) para `explorations/senadoras-2026/` neste repo, para reusar a infraestrutura de skills/agents/rules do Claude Code. Estrutura de pastas original preservada como estava (`dados/{brutos,processados,dicionarios}`, `scripts/`, `outputs/{figuras,tabelas}`, `docs/plano-pesquisa.md`) — decisão explícita da usuária, para não arriscar quebrar referências entre os 9 scripts R (ainda não executados) e o plano de pesquisa por causa de uma reorganização de nomes. Regras de `.gitignore` do projeto (que vieram como arquivo próprio) migradas para o `.gitignore` raiz do repo, seguindo a convenção já usada para `data/` e `explorations/base-territorial-partidos/`. Nenhum script foi rodado ainda; nenhum dado foi baixado.

**Estado herdado do app do Claude:** plano de pesquisa completo em `docs/plano-pesquisa.md` (4 perguntas de pesquisa, hipóteses, fontes de dados, plano de variáveis, plano analítico, checklist de execução em 10 passos) e 9 scripts R esqueleto (`00_setup.R` a `08_checagem_sanidade.R`), cada um com cabeçalho descrevendo objetivo/inputs/outputs mas sem lógica implementada.

## Checagem 00_setup.R (2026-08-19)

- **Pacote faltando:** `janitor` (instalado nesta sessão, `install.packages("janitor")`). Demais pacotes (`electionsBR`, `dplyr`, `tidyr`, `readr`, `purrr`, `stringr`, `ggplot2`) já estavam presentes. Script roda limpo após a instalação.
- **`electionsBR` versão instalada:** `0.5.0`.
- **API disponível:** as duas gerações coexistem — `candidate_fed()` (clássica, por domínio) **e** `elections_tse()` (unificada) estão exportadas. Plano (Seção 2.2) previa checar qual estava ativa; resposta: ambas.
- **Discrepância com o plano:** a lista de funções exportadas **não inclui** `candidate_asset()` nem `party_composition()`, citadas no plano (Seção 2.2/Seção 4, variável `tamanho_partido`) como possíveis fontes. As funções de bancada/composição disponíveis nesta versão são `seats_fed()` / `seats_local()` (assentos) e `legend_fed()` / `legend_local()` / `party_mun_zone_fed()` — `04_tamanho_partido.R` provavelmente vai precisar usar `seats_fed()` em vez de `party_composition()`. Sinalizar isso ao escrever esse script.
- **Ainda não confirmado (TODOs do próprio script, não executados nesta sessão):** (a) se o ano de 2026 é suportado nativamente por `candidate_fed()`/`elections_tse()` — precisa de um teste de download pequeno (ex. `candidate_fed(year = 2022, uf = "DF")` primeiro, depois tentar 2026); (b) nomes exatos das colunas de sexo/gênero (`DS_GENERO` vs. `CD_GENERO` vs. `SG_GENERO`) — só se confirma inspecionando um download real. Isso é o objetivo de `01_download_candidatos.R`.

## Teste de download — BLOQUEADO pelo TSE nesta sessão (2026-08-19)

Tentativa de teste pequeno (`candidate_fed(year=2022, uf="DF")` e `elections_tse(year=2022, uf="DF", type="candidate")`, ano já encerrado, sem relação com 2026): as duas falharam com `erro 1 na extração a partir de arquivo zip` — o pacote baixa algo, mas o arquivo não é um zip válido.

**Causa raiz identificada**: não é bug do pacote nem do ano/UF testado. Teste direto com `curl` em `cdn.tse.jus.br/estatistica/sead/odsele/consulta_cand/consulta_cand_2022.zip` retorna **HTTP 403 "Access Denied" (Akamai)**, mesmo com User-Agent de navegador. `dadosabertos.tse.jus.br` e até `www.tse.jus.br` (a home page) também retornam 403 direto desta sessão — ou seja, o WAF do TSE está bloqueando toda a rede de saída desta sessão em background (provavelmente por faixa de IP/datacenter), não uma requisição específica.

**Implicação prática**: este ambiente de execução (sessão remota/background) não consegue baixar dados do TSE. Os scripts (`00_setup.R` já validado; `01_download_candidatos.R` em diante) precisam rodar de uma máquina/rede que o TSE não bloqueie — tipicamente a rede doméstica/institucional da usuária, não uma sessão em nuvem. Nada foi alterado nos scripts em si (o placeholder de `01_download_candidatos.R` continua igual); o teste foi feito num script à parte em `tmp/`, fora do repo.

## Diagnóstico completo do bloqueio + solução (2026-08-19)

**Causa raiz confirmada pela usuária**: ela testou `elections_tse(year=2022, uf="DF", type="candidate")` na própria rede/sessão local (fora desta sessão em background) e obteve o mesmo erro de extração de zip — ou seja, **não é bloqueio específico desta sandbox**. Investigação do código-fonte do `electionsBR` (`electionsBR:::download_unzip`) mostrou que o pacote baixa via `httr::GET()` **sem checar o status HTTP** e salva a resposta em disco mesmo se for uma página de erro — daí o zip "corrompido". Confirmado via `curl` que `cdn.tse.jus.br` (usado por toda função do pacote, não só candidatos) retorna **HTTP 403 "Access Denied" (Akamai)** para requisições não-navegador, incluindo com User-Agent de navegador spoofado — é bloqueio por *fingerprint* do cliente (TLS/bot detection), não por IP nem por header.

**Confirmado pela usuária**: o download manual do mesmo dataset (`dadosabertos.tse.jus.br/dataset/candidatos-2022`) pelo navegador funciona normalmente — o zip abre e tem os CSVs dentro. Ou seja, o bloqueio é só para clientes automatizados (R/curl), não para o navegador.

**Escopo do problema**: como o bloqueio é no domínio `cdn.tse.jus.br` inteiro, afeta toda função do `electionsBR` usada no plano, não só `consulta_cand`: candidatos (9 anos), votação/resultado eleitoral (8 anos, PP1/PP4), bancada pré-eleição (`seats_fed()`, PP2) — ~25 downloads manuais ao longo do projeto. Financiamento de campanha (`personal_finances_fed()`) e bens de candidato ficam como opcionais, não bloqueiam o checklist principal. Usuária optou por seguir com tudo, um dado de cada vez, começando por candidatos.

**Solução implementada**: criado `scripts/utils_tse.R` com `carregar_zip_candidatos_tse(ano)` — lê um zip já baixado manualmente e salvo em `dados/brutos/consulta_cand_<ano>*.zip`, extrai, lê todos os CSVs (um por UF, `;`-delimitado, encoding Latin1) e empilha num único data frame. Se o zip não existir, imprime a URL exata do dataset e instruções de onde salvar, sem quebrar o loop. `scripts/01_download_candidatos.R` reescrito para usar esse loader em vez de `candidate_fed()`/`elections_tse()` — testado sem nenhum zip presente, imprime as 9 instruções corretamente e um resumo tabular por ano, sem tentar acessar rede.

**Não verificado ainda** (porque nenhum zip foi baixado nesta sessão): se a leitura via `read_delim` com os parâmetros assumidos (`;`, Latin1) funciona sem ajuste nos anos mais antigos (1994/1998), que podem ter layout diferente dos anos recentes — o script já avisa (`warning`) se o número de colunas variar entre arquivos do mesmo ano, mas isso só aparece na prática quando os zips reais forem lidos.

**Sessão interrompida aqui (2026-08-19)**: usuária observou que o `electionsBR` estava funcionando neste mesmo terminal há poucos dias — pode ser um bloqueio transitório do TSE (regra de bot temporária), não necessariamente permanente. **Antes de seguir com o caminho manual, retestar amanhã**: `elections_tse(year=2022, uf="DF", type="candidate")`. Se voltar a funcionar, usar o pacote normalmente (o workaround manual em `utils_tse.R`/`01_download_candidatos.R` fica pronto no repo como fallback, sem custo, caso o bloqueio volte). Se continuar bloqueado, seguir com os zips manuais como planejado.

## Reteste do bloqueio TSE (2026-08-20)

**Resultado: bloqueio ainda ativo, não era transitório.** Reexecutado `elections_tse(year=2022, uf="DF", type="candidate")` nesta sessão: roda sem erro fatal (download "completa" a 100%), mas retorna 0 linhas / 0 colunas, com o mesmo warning de ontem (`erro 1 na extração a partir de arquivo zip`). Confirmado via `curl -o /dev/null -w "%{http_code}"` em `cdn.tse.jus.br/estatistica/sead/odsele/consulta_cand/consulta_cand_2022.zip`: **HTTP 403** persiste.

**Decisão:** seguir com o caminho manual já implementado em `scripts/utils_tse.R` (baixar zips pelo navegador em `dadosabertos.tse.jus.br`, salvar em `dados/brutos/`). O fallback automático via `electionsBR` fica documentado como não-funcional nesta rede por ora; reavaliar só se houver sinal de que o TSE mudou a política de bot-blocking.

## Next Steps

- [x] **Reteste do bloqueio TSE** (2026-08-20) — confirmado que persiste, ver acima. Não retestar de novo sem motivo (ex. notícia de mudança na política do TSE).
- [x] Rodar `00_setup.R` para checar versão do `electionsBR` e disponibilidade de dados 2026 (ver Seção 2.2 do plano) — feito, ver acima.
- [x] Testar download pequeno (1 UF, ano recente) — feito; **bloqueado por 403 do TSE**, confirmado em duas sessões (19/08 e 20/08).
- [ ] Baixar manualmente o zip de candidatos 2022 (`https://dadosabertos.tse.jus.br/dataset/candidatos-2022`, recurso BRASIL) e salvar em `dados/brutos/consulta_cand_2022.zip`, para testar `carregar_zip_candidatos_tse(2022)` com dado real.
- [ ] Seguir o checklist de execução da Seção 7 do plano, script por script, depois que o download manual funcionar.
