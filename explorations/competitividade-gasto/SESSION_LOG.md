# Session log — competitividade-gasto

## 2026-09-28

- Objetivo: medida de competitividade da candidatura baseada em gasto, comparável entre Deputado Federal e Estadual, para testar se o aumento de votos das mulheres 2018→2022 variou por nível de competitividade.
- Busca de literatura: nenhuma referência mede competitividade da candidatura pelo gasto; Wylie et al. (2019) e Fonseca et al. (2026) usam voto. Correção registrada: Wylie et al. definem "laranja" só por voto (< 1% do quociente mínimo), não por gasto.
- Decisão: gasto = despesas contratadas (prestação final TSE) sem "Doações financeiras a outros candidatos/partidos"; não usar GPPER (cobertura 71–87% dos aptos, não identifica repasses).
- Descoberta: limite legal de deputado é igual em todas as UFs (Lei 13.488/2017; Portaria TSE 647/2022) → `pct_teto` compara cargos, não UFs; e o gasto real cresceu muito em 2022, então `pct_teto` também não compara anos.
- `razao_min` instável (eleitos com gasto ~0); `razao_p10` mais estável — candidata a medida principal; `pctl_uf` como robustez.
- Mulheres gastam proporcionalmente mais em todos os grupos de resultado, inclusive não competitivas pelo voto → classificação pelo gasto e pelo voto divergem justamente para mulheres.
- Esclarecido com a autora: os grupos de resultado nas tabelas do script 01 vêm da classificação pelo voto (≥ 10% QE); o gasto só foi comparado a ela.
- Script 02: distribuição (quantis, ECDF, % acima de 0,5× p10 dos eleitos, IC Wilson) por gênero × raça × resultado, 2018 × 2022. Lacunas de gênero e raça no % acima do patamar diminuíram (raça no estadual: −16,4 → −7,5 pp); parte do avanço das mulheres ocorre entre não competitivas pelo voto.
- Script 03 (pergunta inversa: o ganho de votos das mulheres veio das que gastaram mais?): participação das mulheres nos votos nominais +4,9 pp (federal) e +1,6 pp (estadual), inteiramente em faixas ≥ 0,5× o patamar; decomposição por CPF mostra que o ganho veio de novas candidatas, não de quem repetiu a disputa aumentando o gasto. CPF usado só em memória para parear anos.
- Desenho DiD (plano em quality_reports/plans/2026-09-28_competitividade-gasto-did.md) aprovado pela autora; medidas m2, m6, m8; placebo 2014 adiado. Autora esclareceu os dois incentivos (30%/proporcionalidade racial nos dois cargos; votos em dobro só no federal) → DiD isola os votos em dobro.
- Scripts 04–06: receitas (origem "Recursos de partido político"), medidas/perfil/decomposição, DiD (`did` 2.5.1). Bug corrigido: id de lista criado dentro de .by. Mulheres: recursos para viáveis +9 a +14 pp, nº de viáveis ≈ 0, votos +5,2 pp vindos das faixas baixas. Negras/os: sem efeito; viáveis caem.
- Placebo 2014 (script 07): prestação de contas 2014 baixada pelo Chrome com autorização da autora (CDN do TSE bloqueia curl/PowerShell). Tempo de evento do `did` é em anos (placebo e = −4) — corrigido filtro que usava e == −1. Votos das mulheres passam no placebo; recursos para mulheres falham (pré-tendência −22 pp); queda de candidaturas negras viáveis passa.
- Autora: 2014 não serve como referência para recursos (fim da doação empresarial). Refeito o DiD de recursos com três fontes (todas as receitas, públicos FEFC + FP, partido): mulheres +7,5 / +9,6 / +15,7 pp; efeito maior quanto mais controlado pelo partido; comparável a Fonseca et al. (+12,3%).
- Script roda da raiz do repo; saídas conferidas contra a primeira execução (CSVs idênticos). Dados de entrada copiados para `data/raw/` (5 arquivos novos; os demais já existiam e são idênticos).
