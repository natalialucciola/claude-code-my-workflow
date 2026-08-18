# Revisão de Coesão e Fluidez — Capítulo 6

**Data:** 2026-08-17
**Arquivo:** `Quarto/thesis/chapters/06-sobreposicao-territorial-partido.qmd`
**Escopo:** capítulo inteiro, com atenção adicional às seções indicadas pela autora (Hipóteses, Amostra, Variáveis, Estratégia de inferência).
**Regra seguida:** `.claude/rules/proofreading-protocol.md` — Fase 1 (propor, não editar). Nenhuma mudança foi aplicada ao arquivo.

## Diagnóstico geral

O padrão apontado é real e tem localização precisa: **Introdução, Revisão de Literatura, Resultados e Discussão** mantêm prosa argumentativa — frases-elo que retomam o parágrafo anterior antes de avançar ("Essa leitura, porém, não é o quadro completo", "Uma pergunta natural é se esse padrão..."). Já **Hipóteses, Amostra, Variáveis e parte da Estratégia de inferência** (§45–130) alternam entre esse mesmo registro e trechos onde a prosa colapsa em asserções paralelas sem conectivo — o efeito é de checklist, não de argumento. Os 7 achados abaixo estão concentrados exatamente aí. Não encontrei problemas de coesão em Resultados, Discussão, Limitações ou Conclusão — essas seções já leem bem e não precisam de intervenção.

## Achados

### 1. Hipóteses — lista sem transição de entrada, H1/H2 subdesenvolvidas

**Local:** entre §47 (fim do parágrafo de fundamentação) e a lista H1–H5.
**Atual:**
> [...] e não depende de o candidato ter permanecido no mesmo partido entre uma eleição e outra, ao contrário da incumbência.
>
> 1. H1. Candidatas mulheres apresentam taxa de sobreposição territorial maior do que candidatos homens.
> 2. H2. Candidatos negros apresentam taxa de sobreposição territorial maior do que candidatos brancos.

O parágrafo anterior é elaborado (retórica plena, travessões explicativos); a lista que vem em seguida cai abruptamente em duas frases de uma oração só, sem nenhuma frase-ponte. H3, H4 e H5 já têm uma segunda frase que os situa no argumento — H1 e H2 não.

**Proposta:**
> [...] e não depende de o candidato ter permanecido no mesmo partido entre uma eleição e outra, ao contrário da incumbência. O capítulo testa essa hipótese geral em cinco proposições, da mais descritiva à mais diretamente causal:
>
> 1. H1. Candidatas mulheres apresentam taxa de sobreposição territorial maior do que candidatos homens — o padrão descritivo de base que os testes causais adiante (H3–H5) investigam.
> 2. H2. Pelo mesmo padrão, candidatos negros apresentam taxa de sobreposição territorial maior do que candidatos brancos.

**Categoria:** transição ausente + desequilíbrio de desenvolvimento entre itens da lista.

---

### 2. Amostra — tabela sem frase de leitura

**Local:** entre a tabela (@tbl-amostra-descritiva, §77–84) e o parágrafo de proveniência dos dados (§86).
**Atual:** a tabela é seguida diretamente por "Os dados vêm de fontes públicas do Tribunal Superior Eleitoral (TSE)." — nenhuma frase interpreta o que a tabela mostra antes de mudar de assunto (de "quem está na amostra" para "de onde vêm os dados").

**Proposta:** inserir uma frase de leitura entre a tabela e o parágrafo de proveniência, por exemplo:
> Mulheres e candidatos negros são minoria nas quatro combinações de cargo e ano, mas a diferença se estreita de 2018 para 2022 nos dois cargos — o pano de fundo descritivo sobre o qual H1 e H2 são testadas adiante.

**Categoria:** ausência de frase-ponte entre tabela e prosa.

---

### 3. Amostra — parágrafo de fontes de dados como lista anafórica ("X vêm de Y" repetido 3×)

**Local:** §86.
**Atual:**
> Os dados vêm de fontes públicas do Tribunal Superior Eleitoral (TSE). O Quociente Locacional do gasto eleitoral, no nível candidato-município, é derivado de dados de prestação de contas eleitorais do TSE. Variáveis de candidatura — gênero, raça autodeclarada, partido, situação eleitoral — vêm dos registros de candidatura do TSE dos mesmos pleitos, obtidos via `electionsBR::elections_tse()`, incluindo Deputado Federal 2014, usada apenas para a análise de incumbência. Os dados de liderança formal do partido, usados no Modelo 3, vêm do sistema de Gerenciamento de Informações Partidárias (SGIP) do TSE [...]

Quatro frases seguidas no molde "[sujeito] vêm de / é derivado de [fonte]" — a repetição do mesmo template sintático é o que dá a sensação de lista, não de texto corrido.

**Proposta:** subordinar as três fontes a uma frase-guarda-chuva, variando a sintaxe:
> Todos os dados vêm de fontes públicas do TSE, mas de três sistemas distintos conforme a variável: o Quociente Locacional do gasto eleitoral, no nível candidato-município, é derivado dos dados de prestação de contas eleitorais; as variáveis de candidatura — gênero, raça autodeclarada, partido, situação eleitoral — vêm dos registros de candidatura dos mesmos pleitos, obtidos via `electionsBR::elections_tse()` (incluindo Deputado Federal 2014, usado apenas na análise de incumbência); e os dados de liderança formal do partido, usados no Modelo 3, vêm do sistema de Gerenciamento de Informações Partidárias (SGIP), disponibilizado como dado aberto [...]

**Categoria:** anáfora sintática repetida (mesmo padrão de frase 3-4× seguidas).

---

### 4. Amostra — parágrafo órfão de uma frase (PMB/PMN)

**Local:** §88, imediatamente após §86.
**Atual:** "Dois partidos da amostra, PMB e PMN, não têm nenhum registro de órgão partidário no sistema do TSE sob nenhum nome, histórico ou atual; seus candidatos (3,3% da amostra) são tratados como dado ausente na variável de liderança formal, não como não-líderes, e excluídos do Modelo 3." — parágrafo de frase única, isolado logo após o parágrafo de proveniência de dados, sem transição.

**Proposta:** anexar ao final do §86 como ressalva, em vez de parágrafo isolado:
> [...] permitindo reconstruir a composição da liderança de cada partido em qualquer momento passado, não apenas a atual. Dois partidos da amostra, porém — PMB e PMN —, não têm nenhum registro de órgão partidário no sistema do TSE sob nenhum nome, histórico ou atual; seus candidatos (3,3% da amostra) são tratados como dado ausente na variável de liderança formal, não como não-líderes, e excluídos do Modelo 3. As bases usadas na análise foram construídas por mim a partir dessas três fontes originais.

**Categoria:** parágrafo de frase única sem transição (candidato a fusão).

---

### 5. Variáveis — abertura em duas frases curtas desconectadas

**Local:** §59, abertura da subseção "Variáveis".
**Atual:** "A estratégia de coordenação partidária será operacionalizada por meio da análise da distribuição geográfica dos gastos de campanha realizados por candidatos. Havendo coordenação, espera-se que candidatos de um mesmo partido não concentrem suas campanhas, em termos de despesas realizadas, num mesmo município."

Duas frases declarativas curtas, cada uma fechada em si — a segunda não usa nenhum conectivo que a amarre à primeira além da ordem.

**Proposta:** fundir num só período:
> A estratégia de coordenação partidária é operacionalizada pela distribuição geográfica dos gastos de campanha dos candidatos: havendo coordenação, espera-se que candidatos de um mesmo partido não concentrem suas despesas no mesmo município.

**Categoria:** frases curtas adjacentes sem conectivo (poderiam ser um período só).

---

### 6. Variáveis — três parágrafos paralelos ("No nível do X") sem frase-guia

**Local:** §63 ("No nível do município...") e §65 ("No nível do candidato...").
**Atual:** os dois parágrafos definem a métrica em dois níveis de agregação, mas nada antes deles avisa o leitor de que são duas definições complementares — o segundo parágrafo simplesmente começa, sem nenhum "da mesma forma" ou equivalente.

**Proposta:** inserir uma frase-guia antes de §63:
> A sobreposição territorial é operacionalizada em dois níveis complementares — o do município, onde se conta quantos correligionários concentram gasto ali, e o do candidato, onde se mede a fração do próprio território que é compartilhada.
>
> No nível do município, para cada combinação de partido, cargo, ano, UF e município [...]

**Categoria:** parágrafos paralelos sem frase-guia declarando o paralelismo.

---

### 7. Estratégia de inferência — nomenclatura confusa + referência cruzada órfã

**Local:** §94, abertura de "Modelo 1: especificação da tripla diferença".
**Atual:** "O desenho é uma diferença-em-diferenças estendida para uma terceira dimensão de comparação, por isso chamada de tripla diferença, ou diferença em diferenças."

A cláusula "ou diferença em diferenças" repete o nome do método de base (DiD simples), não do método de fato usado (tripla diferença) — como está, a frase parece dizer que "tripla diferença" e "diferença em diferenças" são sinônimos, o que contradiz a frase anterior ("estendida para uma terceira dimensão"). Isso não é uma questão de fluidez, é uma inconsistência de nomenclatura que vale conferir com a autora antes de reescrever.

Também: mais adiante no mesmo trecho, "(ver nota metodológica abaixo)" (§106) referencia uma "nota metodológica" que não encontrei em nenhum ponto posterior do capítulo — pode ser um resíduo de uma versão anterior do texto, ou a nota pode estar em outro capítulo/arquivo.

**Proposta (nomenclatura):**
> O desenho é uma diferença-em-diferenças estendida para uma terceira dimensão de comparação — por isso chamado de tripla diferença (ou *difference-in-differences-in-differences*, DDD).

**Ação sugerida (referência cruzada):** confirmar se a "nota metodológica" existe em algum outro lugar (talvez no capítulo de Dados e Métodos geral, `02-dados-metodos.qmd`, hoje placeholder) e trocar por um `@sec-...` de verdade, ou remover a remissão se não houver nota correspondente.

**Categoria:** nomenclatura potencialmente incorreta + link cruzado quebrado/órfão — **sinalizado para decisão da autora**, não uma sugestão de redação pura.

## O que NÃO precisa de mudança

Passei o resto do capítulo com a mesma lente e não encontrei problemas de coesão:

- **Introdução (§1–19):** arco narrativo já construído com frases-elo.
- **Revisão de Literatura (§21–43):** transições fortes entre parágrafos ("Essa leitura, porém, não é o quadro completo"; "Se a coordenação partidária existe, mas é seletiva...").
- **Resultados (§132–242):** o uso de pergunta-resposta retórica ("Uma pergunta natural é se esse padrão está concentrado nas capitais... A resposta é que sim", §165) e de frases-síntese no início de cada subseção funciona bem — não mexer.
- **Modelo 2 / Modelo 3 (§108–227):** a repetição de estrutura entre as duas seções ("O Modelo X mede a sobreposição...") é paralelismo deliberado para facilitar a comparação entre os três modelos — isso é um recurso, não um problema, mantive fora da lista de achados.
- **Discussão, Limitações, Conclusão (§244–273):** synthesis bem construída, Limitações é lista numerada por convenção de gênero (esperado, não é "prosa mal estruturada").

## Disposição (2026-08-17)

Todos os 7 achados foram aplicados diretamente ao `.qmd`, a pedido da autora:

1. Frase-ponte inserida antes da lista H1–H5; H1 e H2 ganharam segunda oração situando-as no argumento. **Aplicado.**
2. Frase de leitura da tabela inserida entre @tbl-amostra-descritiva e o parágrafo de proveniência de dados. **Aplicado.**
3. Parágrafo de fontes de dados reescrito como um período subordinado (guarda-chuva + três cláusulas), em vez de quatro frases "X vêm de Y". **Aplicado.**
4. Parágrafo órfão do PMB/PMN fundido ao parágrafo de proveniência de dados, com conector ("Dois partidos da amostra, porém —"). **Aplicado.**
5. Abertura da subseção Variáveis fundida num só período. **Aplicado.**
6. Frase-guia inserida antes dos parágrafos paralelos "No nível do município" / "No nível do candidato". **Aplicado.**
7. Nome do método corrigido ("tripla diferença... ou *difference-in-differences-in-differences*, DDD"); a remissão órfã "(ver nota metodológica abaixo)" foi **removida** — não encontrei nenhuma nota metodológica em outro ponto do capítulo, e inventar um link (`@sec-...`) teria sido pior do que não ter remissão nenhuma. Se a nota existir em outro capítulo (ex.: `02-dados-metodos.qmd`, hoje placeholder), a remissão pode ser restaurada como link real quando esse capítulo for escrito.

Nenhuma outra parte do capítulo foi tocada — Introdução, Revisão de Literatura, Resultados, Discussão, Limitações e Conclusão permanecem como estavam, por já lerem bem (ver "O que NÃO precisa de mudança" acima).
