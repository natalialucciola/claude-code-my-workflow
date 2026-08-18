# Humanize Audit: Capítulo 6 — Coordenação Territorial de Listas Partidárias

**Date:** 2026-08-17
**File:** `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`
**Word count (approx.):** 6.700
**Scope:** 10 categorias de tiques de voz de IA (ver `.claude/skills/humanize/SKILL.md`), adaptadas para português acadêmico.

> **Nota metodológica:** o subagente `humanize-auditor` foi lançado primeiro, mas caiu num worktree recém-recriado que não continha `Quarto/thesis/` (efeito colateral de uma chamada anterior a `EnterWorktree` nesta sessão, que reconstruiu o worktree a partir de um branch-base sem os capítulos). A auditoria abaixo foi feita diretamente pelo agente principal sobre o texto completo do capítulo, já lido integralmente mais cedo nesta mesma conversa a partir do checkout principal (`C:\Users\natlu\meu_claude_workflow_academico`). Cobertura idêntica à do agente especializado; só a via de execução mudou.

## Histórico de auditorias

Este não é o primeiro pass de `/humanize` sobre este capítulo. Uma auditoria anterior (2026-08-16, ~5.976 palavras) encontrou 3 achados (0 HIGH, 1 MED, 2 LOW: cinco repetições do slot "X, portanto, Y", cinco parênteses de travessão duplo idênticos, e uma abertura formulaica na seção de Resultados) e registrou que as correções foram aplicadas diretamente naquela mesma sessão. O capítulo cresceu para ~6.700 palavras desde então (conteúdo novo, não apenas essas correções), então esta auditoria de 2026-08-17 é sobre uma versão mais recente do texto e substitui a anterior como o relatório vigente — os achados abaixo já refletem que o "portanto" e os travessões duplos daquele pass não reapareceram no texto atual.

## Resumo por categoria

| # | Categoria | HIGH | MED | LOW |
|---|---|---:|---:|---:|
| 1 | Transições clichê ("além disso", "vale notar", "em suma"...) | 0 | 0 | 1 |
| 2 | Léxico clichê de IA ("mergulhar", "robusto", "lançar luz"...) | 0 | 0 | 0 |
| 3 | Travessão/pontuação em excesso | 0 | 0 | 1 |
| 4 | Parágrafos de forma simétrica (tópico→3 exemplos→síntese) | 0 | 0 | 0 |
| 5 | Abuso de tricolon | 0 | 0 | 0 |
| 6 | Empilhamento de ressalvas ("poderia potencialmente sugerir") | 0 | 0 | 0 |
| 7 | "Não só X, mas também Y" | 0 | 0 | 1 |
| 8 | Aberturas formulaicas ("Este capítulo faz X") | 0 | 0 | 1 |
| 9 | Excesso de hifenização decorativa | 0 | 0 | 0 |
| 10 | Autoimportância / puffery ("contribuição importante", "abordagem inovadora") | 0 | 0 | 0 |
| | **Total** | **0** | **0** | **4** |

**Taxa: 0 HIGH por 1000 palavras.** Muito abaixo do limiar de "cosmético" (<5 HIGH/1000 palavras).

## Achados (todos LOW — nenhum bloqueante)

| Linha | Categoria | Severidade | Texto atual | Sugestão |
|---|---|---|---|---|
| §27 | 1. Transição clichê | LOW | "Os próprios autores mostram, **além disso**, que essa coordenação piora em distritos de magnitude grande" | Inserção medial, não abertura de frase — uso legítimo. Se quiser eliminar por precaução: "Os próprios autores mostram também que..." |
| §17, §124 | 3. Travessão em par | LOW | Construção "substantivo **—** oração explicativa **—**," repetida duas vezes com a mesma arquitetura (ex.: "no diretório nacional ou estadual —, uma medida direta..."; "em qualquer UF em que concorra — um presidente nacional tem poder... —, enquanto...") | Não é overuse por parágrafo (nunca >3 travessões numa mesma passagem), mas é a mesma muleta sintática reaparecendo. Considerar reescrever uma das duas ocorrências com vírgulas ou dois-pontos para variar a cadência. |
| §252 | 7. "Não só X, como Y" | LOW | "a desvantagem territorial de mulheres dentro do partido **não é só** real e mensurável, **como** agora tem uma explicação causal com apoio empírico razoavelmente forte" | Única ocorrência no capítulo inteiro (limiar da skill é >2) — dentro do aceitável, mencionado só por completude. |
| §17 | 8. Abertura formulaica | LOW | "**O capítulo testa** essa hipótese em três camadas..." | Única ocorrência de "[O/Este] capítulo + verbo" como abertura de parágrafo em 273 linhas — não é padrão repetido, não precisa de ação. |

## Parágrafos mais concentrados

Nenhum parágrafo acumula mais de 1 achado LOW simultâneo — não há "hotspots" de tique de IA no capítulo. Os quatro achados acima estão dispersos em pontos distintos do texto (Hipóteses, Modelo 3, Discussão).

## O que NÃO foi encontrado (positivo)

- **Zero** clichês de IA (nenhum "mergulhar em", "abordagem robusta/holística", "papel crucial", "lançar luz sobre").
- **Zero** empilhamento de ressalvas — as ressalvas do capítulo são pontuais e calibradas ("sugestivo, mas não conclusivo", §194; "resposta parcial e assimétrica", §19/§273) — assinatura de voz autoral genuína, não gestão de incerteza de LLM.
- **Zero** puffery/autoimportância — mesmo ao apontar o próprio achado mais forte ("o achado mais sólido deste capítulo", §269), o capítulo o faz de forma comparativa e qualificada, nunca com adjetivos como "inovador", "revolucionário" ou "importante contribuição".
- O termo técnico "federal-específic[a/o]" se repete ~8 vezes ao longo do capítulo — isso **não** é hifenização decorativa (categoria 9): é terminologia consistente para o conceito central da tripla diferença, o que é boa prática, não tique de IA.
- Nenhuma janela de 3+ parágrafos consecutivos com a mesma arquitetura tópico→exemplos→síntese.
- Nenhuma repetição do slot "X, portanto, Y" nem dos parênteses de travessão duplo idênticos flagrados no pass de 2026-08-16 — as correções daquele pass se mantiveram.

## Recomendação de ação

**Cosmético, opcional.** Com 0 HIGH e 0 MED em ~6.700 palavras, o capítulo não precisa de reescrita nem de "despatchamento" de tiques antes da submissão — a prosa já lê como voz autoral. Os 4 achados LOW são no máximo ajustes de variação estilística, não riscos de credibilidade perante revisor. Se quiser, aplique manualmente a sugestão do §27 (trocar "além disso" medial) e considere variar uma das duas construções de travessão pareado (§17/§124) — o resto pode ficar como está.

## Próximo passo sugerido

Como este pass ficou limpo, o gargalo antes da submissão está nos passos que ainda não foram rodados: `/review-r` (qualidade do código), `/verify-claims` (fidelidade das citações) e `/review-paper --peer [journal]` (substância) — ver a lista de sugestões já apresentada na conversa.
