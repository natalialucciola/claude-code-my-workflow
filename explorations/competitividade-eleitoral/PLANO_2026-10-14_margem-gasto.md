# Plano — Competitividade pelo gasto derivada da margem OLPR (2014–2022)

**Status:** APPROVED (2026-10-14)
**Branch:** `worktree-competitividade-margem-gasto` (a partir de `worktree-competitividade-abd-lss`)
**Exploração:** `explorations/competitividade-eleitoral/` (scripts `R/10`–`R/14`)
**Relacionado:** `explorations/competitividade-gasto/` (`razao_p10`, m2/m6/m8)

## Decisões da autora (2026-10-14)

- **As três medidas, com A como principal.** A = margem de gasto OLPR; D2 = dinheiro faltante
  pela elasticidade voto–gasto; D3 = gasto em relação ao eleito marginal da lista.
- **Escopo:** 2014, 2018 e 2022 (2026 quando sair a prestação final), descritivo + a mesma
  tripla diferença do `R/05`.

## As medidas

### A — Margem de gasto OLPR (principal, *ex ante*)

A margem de votos pergunta: quantos votos a mais (ou a menos) mudariam o resultado da
candidatura? A margem de gasto faz a mesma pergunta num mundo contrafactual em que **o gasto
faz o papel do voto**: as listas recebem cadeiras pelo gasto total das suas candidaturas, e
dentro da lista as candidaturas são ordenadas pelo gasto.

- Mesma máquina (`funcoes_margem.R`, sem alteração): `distribuir()` + busca binária em
  `margem_candidato()`, com `v` = gasto em reais (inteiro), `lst` = a mesma lista (coligação
  ou federação) da margem de votos, `extra` = 0 (não há "gasto de legenda" por distrito).
- **Regra do ano**, com as cláusulas aplicadas ao "QE de gasto" (10%/80%/20%). Robustez:
  D'Hondt puro, sem cláusulas.
- `margem_gasto` em R$ (positivo = folga do eleito pelo gasto; negativo = déficit).
- **Normalização principal:** `margem_gasto_qe = margem_gasto ÷ (gasto do distrito ÷ M)`,
  análoga a `margem_qe`. Não depende de deflator, é comparável entre cargos e anos.
- Desfechos: `eleita_gasto` e "eleita pelo gasto ou a < h do limiar", h ∈ {0,1; 0,25}.

**Validação:** (i) acerto da distribuição pelo gasto em relação aos eleitos reais, por
cargo × ano × gênero; (ii) correlação de Spearman com `margem_qe` e concordância nas bandas;
(iii) comparação com `razao_p10 ≥ 0,5`. Uma medida *ex ante* não precisa acertar 100% dos
eleitos. O acerto mostra quanto do resultado o dinheiro, sozinho, explica.

### D2 — Dinheiro faltante (complemento, *ex post*)

Converte a margem de votos já calculada em reais:
G\*_i = (G_i + 1)·((V_i + Δ_i + 1)/(V_i + 1))^{1/ε} − 1, Δ$_i = G\*_i − G_i.

- ε vem de `log(V+1) ~ log(G+1)` **dentro da lista** (EF de lista), separado por
  gênero × cargo × ano. Sensibilidade com ε em ±1 EP e com o ε comum.
- Normalizado pelo mesmo QE de gasto (`d2_qe`), para ficar na escala de A.
- **Ressalva:** ε observacional é endógeno, porque quem já é forte arrecada mais. A conversão
  vale sob essa suposição explícita e não é um efeito causal.

### D3 — Gasto relativo ao eleito marginal da lista (complemento)

`d3 = G_i ÷ G_âncora`. A âncora é o gasto do último eleito da lista pelo voto; em listas sem
eleitos, é o menor gasto entre os eleitos do distrito. Mesma família de `razao_p10`, ancorada
na lista como a margem de ABD. Corte de referência: 0,5.

## Dados

| Ano | Gasto por candidatura | Fonte |
| --- | --- | --- |
| 2014 | despesas sem doações a outros e sem "Baixa de Estimáveis" | `data/raw/prestacao_final_2014.zip` (regra do `07_placebo_2014.R`) |
| 2018, 2022 | despesas contratadas sem repasses | `data/processed/competitividade_gasto_cand.rds` |
| 2026 | — | prestação final ainda não publicada |

Junção pela `sq_candidato` × ano com `margem_resultado.rds`: 99,9% das aptas em 2018/2022
(conferido). Candidatura apta sem despesa entra com gasto 0.

## Etapas

1. `R/10_gasto_candidaturas.R`: gasto 2014–2022 por candidatura, junto à margem →
   `data/processed/margem_gasto_insumos.rds`; tabela de cobertura.
2. `R/11_margem_gasto.R`: medida A com cache por distrito (`margens_gasto_por_distrito/`),
   em paralelo como o `R/03`; validação (acerto, Spearman, bandas) em `output/`.
3. `R/12_dinheiro_faltante_d2_d3.R`: elasticidades, D2 e D3.
4. `R/13_descritivo_gasto.R`: distribuição das três medidas por gênero, raça, cargo e ano;
   cruzamento com a margem de votos (competitiva pelo voto × pelo gasto); figuras no padrão
   da tese.
5. `R/14_ddd_gasto.R`: tripla diferença do `R/05` (did::att_gt, UF × cargo, sem DF, base 2018,
   bandas uniformes, *cluster* por UF), com desfechos de A (principal), D3 ≥ 0,5 e D2 ≤ 0,1
   QE de gasto. Mulheres, pessoas negras e mulheres negras.
6. README (nova seção) e SESSION_LOG.

## Ponto de atenção: 2014 como pré-teste

Em 2026-09-28, a autora decidiu que **2014 não serve de referência de tendência para recursos**,
por causa do fim da doação empresarial (2015). As medidas A e D3 são relativas dentro do
distrito, então devem sofrer menos com a mudança de nível. Mesmo assim, o coeficiente de 2014
será reportado **sinalizado, sem leitura de pré-teste**. A leitura principal fica no 2×2
2018 → 2022. Se a autora quiser outra leitura, ela decide.

## Verificação

- `scripts/testar_exemplos_artigos.R` segue passando (a função não muda).
- Teste de sanidade de A: com `v` = votos, o `R/11` reproduz a `margem` do `R/03` num distrito.
- Acerto, Spearman e concordância de bandas reportados em `output/`.
- Cada script roda do zero a partir da raiz; sem caminhos absolutos.
