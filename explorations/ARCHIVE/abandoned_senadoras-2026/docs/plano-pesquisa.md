# Plano de Pesquisa
## O aumento da presença de mulheres nas corridas ao Senado Federal em 2026: descrição e explicação

*Documento de trabalho para execução com Claude Code, usando dados do TSE / pacote `electionsBR` (R). Elaborado para orientar a coleta, tratamento e análise de dados visando um artigo submetido à Revista Dados.*

---

## 1. Perguntas de pesquisa

**PP1 (descritiva).** Como evoluiu a participação de mulheres nas candidaturas ao Senado Federal, em número absoluto e em proporção, no Brasil entre 1994 (ou o primeiro ano disponível de dados confiáveis) e 2026 — no agregado nacional, por unidade da federação e por partido? Há algo inédito ou estatisticamente atípico em 2026 em relação à série histórica?

**PP2 (explicativa — oferta partidária).** O aumento de 2026 é puxado por partidos grandes (com bancada relevante) ou por partidos pequenos/nanicos? Existe correlação entre tamanho/força eleitoral do partido e propensão a lançar mulheres ao Senado?

**PP3 (explicativa — substituição entre cargos).** O possível aumento de candidaturas femininas ao Senado ocorre às custas de menor presença feminina em outros cargos disputados pelo mesmo partido no mesmo ciclo (deputada federal, governadora, vice-governadora, presidente/vice-presidente)? Ou o crescimento é geral, atingindo todos os cargos?

**PP4 (explicativa — perfil e experiência).** As candidatas de 2026 diferem das de eleições anteriores em nível de experiência política prévia (já eleitas antes, já candidatas antes, ocupação de cargos de liderança partidária, tempo de filiação) e em perfil sociodemográfico (idade, escolaridade, ocupação, raça/cor autodeclarada)? Há indício de que 2026 está recrutando um perfil mais "consolidado" (efeito vitrine com nomes fortes) ou mais um perfil de estreantes?

Hipóteses de trabalho (a refinar após a leitura de literatura):
- H1: O crescimento em número absoluto de candidatas ao Senado em 2026 não é acompanhado por crescimento proporcional equivalente, porque o total de candidaturas ao cargo caiu (ver nota da matéria do Correio Braziliense/TSE já levantada nesta conversa: 315 candidaturas em 2026 vs. 361 em 2018).
- H2: Como a cota de gênero da Lei 9.504/1997 (art. 10, §3º) **não se aplica a eleições majoritárias** (Senado, Presidente, Governador) — só a proporcionais (Câmara Federal, Câmara Estadual, Vereador) —, qualquer aumento de mulheres no Senado é decisão estratégica voluntária dos partidos, não obrigação legal. Isso torna a pergunta "por quê" mais interessante teoricamente: não há piso legal a cumprir.
- H3: Partidos podem estar usando candidaturas femininas ao Senado como "vitrine" (nomes de maior densidade midiática/política) justamente por não haver obrigação de cota — o que sugeriria concentração em poucas candidatas de alto perfil, não distribuição ampla.

---

## 2. Fontes de dados

### 2.1 Fonte primária: Repositório de Dados Abertos do TSE
`https://dadosabertos.tse.jus.br` (ou o portal `cepesp.io` / `CEPESPdata` da FGV como alternativa tratada).

Conjuntos relevantes, por ano de eleição (1994, 1998, 2002, 2006, 2010, 2014, 2018, 2022, 2026):
- **Candidatos (`consulta_cand`)**: um registro por candidatura, com sexo, cargo, UF, partido, coligação/federação, situação de candidatura, situação de totalização (eleito/não eleito/suplente), idade, grau de instrução, ocupação, raça/cor (a partir de 2014), CPF (público, permite reconstrução de painel entre eleições).
- **Bens de candidato (`bem_candidato`)** — opcional, para robustez (indício de recursos próprios).
- **Prestação de contas / receitas de campanha (`receitas_candidatos`)** — importante para verificar se as candidatas de 2026 recebem financiamento partidário e do Fundo Eleitoral em proporção equivalente à cota mínima de recursos para mulheres (Lei 9.504, art. 44, com jurisprudência do TSE fixando percentuais mínimos do Fundo Partidário e do Fundo Eleitoral para candidaturas femininas — **isto vale mesmo para o Senado**, e é uma pista relevante para PP2/PP3: um partido pode estar cumprindo a cota de recursos via candidatura vistosa ao Senado).
- **Composição de legendas/coligações por cargo** — para identificar se a candidata concorre sozinha pelo partido ou em federação/coligação.
- **Resultados eleitorais (`votação candidato`)** — necessário só para os anos já com pleito realizado (não 2026, que ainda não ocorreu na data deste plano).

### 2.2 Pacote R `electionsBR`
Duas gerações de funções coexistem no pacote — **checar qual está ativa na versão instalada antes de escrever o pipeline definitivo**, pois a API mudou ao longo do tempo:
- Funções "clássicas" por domínio: `candidate_fed(year, uf = "all")` (dados de candidatos a cargos federais/estaduais, incluindo Senador), `candidate_local()` (cargos municipais), `candidate_asset()`, `party_composition()`, `seats_fed()`, `seats_local()`, `vote_mun_zone_fed()`, `voter_profile()`, entre outras.
- Função unificada mais recente: `elections_tse(year, uf, type)`, com o argumento `type` controlando qual base baixar (ex.: `"candidate"`, `"personal_finances"`, `"vote_mun_zone"`, `"party_mun_zone"`, `"legends"`, `"seats"`, `"social_media"`, `"voter_profile"`).

**Passo obrigatório no início da execução:** rodar `packageVersion("electionsBR")`, consultar `?electionsBR` e a vinheta instalada localmente (`vignette("introduction", package = "electionsBR")`), e confirmar (a) se 2026 já está disponível como ano suportado pelo pacote — na documentação consultada em agosto de 2026 os exemplos mostravam suporte oficial só até 2022 — e (b) os nomes exatos de colunas retornadas (sexo costuma vir como `DS_GENERO` ou `CD_GENERO`/`SG_GENERO` dependendo da base; validar com `names(df)` e `str(df)` antes de programar o restante do pipeline). Se 2026 ainda não estiver empacotado, baixar diretamente do portal de dados abertos do TSE (arquivos `consulta_cand_2026_BRASIL.csv`, um por UF ou um nacional consolidado) e tratar manualmente com o mesmo layout de colunas dos anos anteriores, para garantir consistência de schema no *append* entre anos.

### 2.3 Fonte complementar: CEPESPdata (FGV)
`https://www.cepesp.io` — base alternativa/cruzada de candidatos e votação, útil para checagem de consistência (mesma pessoa, mesma candidatura, contagens batem?) e para preencher eventuais lacunas do `electionsBR` em anos mais antigos.

### 2.4 Fonte para contexto normativo
Jurisprudência do TSE sobre cota de gênero (proporcional vs. majoritário) e sobre percentual mínimo de recursos do Fundo Partidário/Fundo Eleitoral destinado a candidaturas femininas — usar como referência qualitativa/legal na seção teórica, não como dado a baixar em painel.

---

## 3. Escopo e recorte da amostra

- **Cargo-alvo:** Senador (`DS_CARGO == "SENADOR"`).
- **Cargos de comparação (PP3):** Deputado Federal, Governador, Vice-Governador, Presidente, Vice-Presidente — mesmo painel de anos, para comparar dentro do mesmo partido e ciclo eleitoral.
- **Janela temporal:** idealmente todas as eleições desde 1994 (primeira com dados TSE minimamente padronizados) até 2026. Se o esforço de padronização de schema anterior a 2002 for excessivo, definir como janela mínima 2002–2026 (4 ciclos completos de renovação 1/3 e 4 de 2/3, cobrindo pelo menos duas rodadas completas do padrão de alternância 1/3–2/3) e registrar essa limitação no artigo.
- **Unidade de análise:** candidatura individual (uma linha por candidato/cargo/ano/UF). Consolidações posteriores (por partido, por UF, por ano) são agregações desse nível-base — não baixar dados já agregados quando o nível de candidatura estiver disponível, para preservar flexibilidade analítica.
- **Importante (correção já incorporada nesta conversa):** o Senado é renovado alternadamente em 1/3 (uma vaga por UF) e 2/3 (duas vagas por UF) a cada eleição. 2026 é ano de renovação de 2/3 (54 cadeiras, duas por UF), assim como 2018; 2014 e 2022 foram de 1/3. Esse desenho precisa ser controlado nas comparações "número de candidatas por eleição", porque anos de 2/3 mecanicamente comportam mais candidaturas por UF do que anos de 1/3 — o ideal é normalizar por número de vagas em disputa, não só por total de candidaturas, ao comparar 2026 com 2022 (1/3) — mas comparar 2026 diretamente com 2018 (também 2/3) é a comparação mais limpa "maçã com maçã".

---

## 4. Construção de variáveis

| Variável | Como construir | Uso |
|---|---|---|
| `mulher` | `DS_GENERO`/campo de sexo == "FEMININO" | variável dependente central |
| `uf`, `ano`, `cargo`, `partido`, `coligacao_federacao` | direto da base de candidatos | agregações e controles |
| `eleita` | `DS_SIT_TOT_TURNO` (ELEITO, ELEITO POR QP, ELEITO POR MÉDIA, SUPLENTE, NÃO ELEITO) | resultado (não disponível para 2026 até a eleição ocorrer) |
| `tamanho_partido` | nº de cadeiras do partido na Câmara/Senado *antes* da eleição em questão (via `party_composition()`/`seats_fed()` do ano anterior, ou base de composição da Câmara/Senado na data de registro das candidaturas) | testar H de "partidos grandes vs. pequenos" (PP2) |
| `candidata_experiente` | indicador construído via painel entre eleições: CPF da candidata aparece em `consulta_cand` de anos anteriores (já foi candidata) e/ou em `DS_SIT_TOT_TURNO` de eleição anterior com resultado "ELEITO" (já foi eleita, a este ou outro cargo) | PP4 |
| `perfil_sociodemografico` | idade na posse, grau de instrução, ocupação declarada, raça/cor autodeclarada (disponível a partir de 2014) | PP4, comparação descritiva |
| `financiamento_fundo_eleitoral_mulher` | valor recebido do Fundo Eleitoral/Partidário por candidatas vs. candidatos ao Senado, por partido | evidência complementar de priorização/tokenismo em PP2/PP3 |
| `share_mulheres_cargo_partido_ano` | nº candidatas / nº candidatos totais, por partido × cargo × ano | variável-chave para PP3 (comparação entre cargos dentro do mesmo partido/ano) |

**Reconstrução de painel de candidatos (CPF como chave).** O campo de CPF do candidato é informação pública nos dados de candidatura (diferente do CPF de eleitor, que é sigiloso), o que permite unir a mesma pessoa através dos anos. Confirmar isso experimentalmente logo no início (`table(duplicated(consulta_cand$NR_CPF_CANDIDATO))` entre dois anos-teste) antes de montar o pipeline completo, porque o layout de nomes de coluna varia entre anos e há necessidade de harmonização manual (dicionário de "de-para" de nomes de coluna por ano, comum em quem trabalha com dados do TSE).

---

## 5. Plano analítico por pergunta

**PP1 — Descritiva**
1. Série histórica nacional: nº e % de candidatas ao Senado por ano (1994–2026), com anotação visual dos anos de renovação 1/3 vs. 2/3.
2. Série por UF: nº e % de candidatas por UF e ano — heatmap ou pequenos múltiplos (state-year grid).
3. Série por partido: nº e % de candidatas por partido e ano, ranqueado por partidos com maior variação positiva em 2026 vs. 2018 (comparação 2/3-para-2/3).
4. Teste estatístico simples de mudança estrutural: teste de proporções (two-proportion z-test ou qui-quadrado) comparando 2026 vs. cada eleição anterior, nacional e por UF, para checar se a diferença é estatisticamente significativa e não apenas ruído amostral (relevante dado N pequeno em vários estados).
5. Reportar explicitamente, como já apurado nesta conversa: recorde em número absoluto de candidatas (69), mas proporção (22%) estável/ligeiramente abaixo de 2022; universalização (100% dos estados com ao menos uma candidata) inédita desde 2014.

**PP2 — Oferta partidária (tamanho do partido)**
1. Classificar partidos por tercis de tamanho de bancada pré-eleição (grande/médio/pequeno).
2. Regressão logística: `mulher ~ tamanho_partido + uf + ano + ano:tamanho_partido`, clusterizando erros-padrão por partido. Interpretar o coeficiente de `tamanho_partido` e sua interação com o ano de 2026 (efeito diferencial em 2026 vs. anos anteriores).
3. Complementar com análise descritiva simples (mais interpretável para um artigo de ciência política): ranking de partidos por Δ do share de mulheres ao Senado entre 2018 e 2026, cruzado com tamanho de bancada em 2018.

**PP3 — Substituição entre cargos**
1. Construir painel partido × cargo × ano com `share_mulheres_cargo_partido_ano`.
2. Modelo de efeitos fixos de partido e ano (ou diferenças-em-diferenças, tratando "ser candidatura ao Senado" como tratamento dentro do partido): testar se o aumento do share de mulheres no Senado em 2026, dentro de um partido, correlaciona-se negativamente com o share de mulheres do mesmo partido em outros cargos no mesmo ciclo.
3. Atenção: cargos proporcionais (Deputado Federal) têm piso legal de 30% — qualquer "substituição" ali é mais restrita estruturalmentedo que em cargos majoritários (Governador, Vice, Presidente/Vice), onde não há piso. A hipótese de substituição é mais plausível entre cargos majoritários do que entre Senado e Deputado Federal, e isso deve ser discutido explicitamente na interpretação dos resultados, não só testado estatisticamente.

**PP4 — Perfil e experiência**
1. Comparar, entre candidatas de 2026 e candidatas de eleições anteriores (idealmente 2018, ano de mesmo desenho de vagas): % que já foi candidata antes (qualquer cargo), % que já foi eleita antes (qualquer cargo), % com cargo de liderança partidária, idade média, escolaridade, ocupação declarada, raça/cor.
2. Comparar candidatas de 2026 com candidatos homens de 2026 nas mesmas dimensões, para isolar se o "diferencial de experiência" é específico do sexo ou reflexo geral do perfil de quem concorre ao Senado.
3. Se o volume de dados permitir, tipologia qualitativa simples (não estatística) das top-N candidatas por intenção de voto nas pesquisas (dado já levantado nesta conversa via Quaest) — verificar se são todas "nomes fortes" (ex.: ex-ministras, senadoras em exercício, deputadas federais) ou há also estreantes competitivas, para dialogar com a hipótese de "vitrine" (H3).

---

## 6. Estrutura sugerida do artigo (alinhada a formato Revista Dados)

1. Introdução — o "achado" de 2026 (recorde absoluto, não proporcional; universalização territorial) como gancho.
2. Revisão de literatura — cotas de gênero no Brasil, distinção proporcional/majoritário, "efeito cremalheira", tokenismo/vitrine, financiamento de campanha e gênero (usar como ponto de partida a literatura já localizada: artigo da Revista de Informação Legislativa sobre "Mulheres, raça e partidos no Brasil" e o estudo do Instituto Esfera/2026 sobre sub-representação feminina, ambos já identificados nesta conversa; complementar com busca sistemática em periódicos de ciência política).
3. Dados e método (baseado neste plano).
4. Resultados — um bloco por pergunta de pesquisa (PP1–PP4).
5. Discussão — conectar resultados às hipóteses (H1–H3) e à literatura.
6. Conclusão e agenda de pesquisa futura (ex.: acompanhar se as favoritas nas pesquisas de fato se elegem, uma vez že os resultados de outubro de 2026 estiverem disponíveis).

---

## 7. Checklist de execução (ordem sugerida para o Claude Code)

1. Verificar versão/API do `electionsBR` instalada e disponibilidade de dados 2026 (funções vs. download manual).
2. Baixar e harmonizar `consulta_cand` de todos os anos do escopo definido (Seção 3), cargo Senador, e também os cargos de comparação da PP3.
3. Validar schema (nomes de coluna, encoding, valores de `DS_GENERO`) ano a ano, documentando um dicionário de harmonização.
4. Construir base de painel candidato (chave CPF) para a variável de experiência prévia.
5. Construir base de tamanho de partido por ano (bancada pré-eleição).
6. Rodar a bateria descritiva da PP1 (tabelas + gráficos).
7. Rodar os modelos de PP2 e PP3.
8. Rodar a comparação de perfil da PP4.
9. Redigir resultados preliminares e checá-los contra os números já levantados manualmente nesta conversa (69 candidatas, 22%, RN/SC/SP com 5 cada, AC/AL/AM/BA/MS/PB/SE/TO com 1 cada) como teste de sanidade do pipeline.
10. Escrever o artigo seguindo a estrutura da Seção 6.

---

## 8. Limitações a declarar no artigo

- Dados de resultado (eleita/não eleita) de 2026 só existirão após a eleição — o artigo pode ser submetido com a análise de oferta de candidaturas e, posteriormente, atualizado/complementado com resultado eleitoral em versão revisada.
- Mudança no desenho de renovação (1/3 vs. 2/3) exige cuidado nas comparações ano a ano; preferir sempre comparações "mesmo desenho" (2018 vs. 2026) como comparação central, com os demais anos como contexto de série longa.
- CPF como chave de painel pode ter inconsistências de captura em anos mais antigos (pré-2010); validar taxa de matching e reportar.
- Dados de raça/cor autodeclarada só existem a partir de 2014 — qualquer comparação de perfil racial fica limitada a esse subperíodo.
