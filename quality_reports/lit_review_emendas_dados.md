# Levantamento: trabalhos sobre emendas parlamentares com dados e códigos disponíveis

**Data:** 2026-11-25
**Status:** primeira passada (busca web). Os repositórios de dados (Harvard Dataverse, Mendeley Data, sites.usp.br, scielo.br) **não puderam ser abertos** desta sessão por restrição de rede. Por isso nada abaixo sobre o conteúdo dos arquivos foi conferido. Toda referência deve passar por `/verify-claims` antes de ir ao texto.

---

## 1. Replicação com dados disponíveis (prioridade)

| Trabalho | O que faz | Dados/código | Uso no capítulo | Conferido? |
|---|---|---|---|---|
| Firpo, Ponczek & Sanfelice (2015), "The relationship between federal budget amendments and local electoral power", *J. of Development Economics* 116: 186–198 | RDD em eleições apertadas para a Câmara: deputados favorecem municípios importantes para sua eleição e eleitores recompensam quem leva recursos | Mendeley Data, DOI 10.17632/skwr8989tk.1 (dez/2016) | Modelo diádico deputado × município (B e C). Período pré-impositivo, útil como benchmark | Existência via busca; conteúdo **não** conferido |
| "Partisanship and local fiscal policy: evidence from Brazilian cities" | Partidarismo e política fiscal municipal | Harvard Dataverse, DOI 10.7910/DVN/11BW20 (2021), inclui arquivos `amendments_<ano>` por ano (ex.: 2003, 7.819 obs., 12 variáveis) | Código de limpeza de emendas por município e alinhamento com prefeito (B). Autoria a confirmar | Não |
| Dataset de 2023 sobre emendas individuais impositivas e o domínio do Executivo no ciclo orçamentário | Efeito da EC 86/2015 sobre a execução | Harvard Dataverse, DOI 10.7910/DVN/O08RNG | Execução empenhado → pago; contexto institucional (seção 2 do capítulo). Autoria e artigo a confirmar | Não |
| Bueno & Dunning (2017), "Race, Resources, and Representation: Evidence from Brazilian Politicians", *World Politics* 69(2): 327–365 | Diferenças de recursos (patrimônio, financiamento) entre candidatos brancos e não brancos | Harvard Dataverse, DOI 10.7910/DVN/RAHUFD | Codificação de raça e recursos de campanha como controles e mecanismo | Existência via busca |
| "Sources of Incumbency (Dis)Advantage", *Brazilian Political Science Review* | Vantagem/desvantagem do incumbente, RDD | Harvard Dataverse, DOI 10.7910/DVN/5GVHTE | Código RDD e montagem da base eleitoral | Não |

## 2. Literatura sem pacote de replicação localizado (pedir aos autores ou reconstruir)

- **Baião & Couto (2017)**, "A eficácia do pork barrel: a importância de emendas orçamentárias e prefeitos aliados na eleição de deputados", *Opinião Pública*. Canal via prefeito aliado (HB2, HC3).
- **Estudo da 54ª legislatura (2011–2014)**, hospedado na biblioteca digital do TSE. Estima que as emendas individuais alocadas nos municípios explicam cerca de 22% dos votos dos candidatos à reeleição.
- **Pinheiro**, working paper que antecede o artigo do JDE: eleitores votam em quem leva recursos, mas as emendas sozinhas não necessariamente elevam a chance de reeleição.
- **Artigo na *Revista Brasileira de Ciência Política*** sobre lealdade ao governo e taxa de execução das emendas (SciELO, rbcpol DBnm3psznZxrwY9ymLZDXCB).
- **"Mapeando escolhas: emendas parlamentares e alocação de recursos ao SUS em tempos de impositividade"**, *Revista Brasileira de Ciência Política* (SciELO, rbcpol M6sJqWVjNd9R7jXKFtZXdWn). Emendas de saúde de 2015 a 2022 e perfil do legislador, **incluindo mulher e não branco**. É o trabalho mais próximo do Bloco A. A página não pôde ser lida, então coeficientes, autoria e disponibilidade de dados estão por conferir. **Prioridade de leitura nº 1.**
- **Saúde coletiva**: transferências do Ministério da Saúde a municípios por emenda, 2015–2021 (*Ciência & Saúde Coletiva* 29(7), 2024), e estudo do Cedeplar/UFMG (Diamantina 2024) sobre a distribuição do investimento em saúde por emendas, 2016–2020. Úteis para decompor a saúde (piso × discricionário).
- **Ipea**: relatório de 2014–2024 com dados do Siga Brasil e Texto para Discussão 2732, com avaliação da qualidade da informação sobre emendas.

**Lacuna confirmada:** nenhuma busca achou trabalho que cruze **gênero e raça do autor** com a **alocação municipal** e o **retorno eleitoral**. "Mapeando escolhas" cobre só gênero/raça × saúde. Essa lacuna é o argumento de contribuição do capítulo.

## 3. Fontes primárias e ferramentas de coleta

| Fonte | Cobertura | Observação |
|---|---|---|
| Portal da Transparência (CGU), download "Emendas parlamentares" | Emendas desde ~2014/2015; autor, tipo, função, localidade, empenhado/liquidado/pago | Desde 2024 separa transferências "com finalidade definida" e "especiais" (Pix). Em jan/2026 ganhou área de rastreamento da indicação ao pagamento |
| Projeto da USP (sites.usp.br/pen) | Emendas da Câmara e do Senado, 2015–2025, extraídas do SIOP | Possivelmente o melhor ponto de partida pronto. **Não acessado**; verificar formato e licença |
| Tesouro Transparente | Demonstrativo anual das emendas individuais e de bancada a estados e municípios, com planilha municipal | Bom para transferências especiais por município |
| API de Dados Abertos da Câmara | Emendas e deputados | Útil para autoria e mandatos |
| Pacotes R `transpbrr` (stats4good/lcgodoy) e `portransp` (pompylio) | Download do Portal da Transparência | Genéricos. Checar se cobrem emendas e se estão mantidos |
| Base dos Dados (BigQuery) | TSE (candidatos com raça e gênero, resultados por município/seção), IBGE | Não se confirmou tabela de emendas. TSE e IBGE certamente estão lá |

## 4. Próximos passos sugeridos

1. Liberar na rede da sessão os hosts `dataverse.harvard.edu`, `data.mendeley.com`, `sites.usp.br` e `www.scielo.br`, ou baixar localmente, para inspecionar os arquivos.
2. Ler "Mapeando escolhas" e o pacote de Firpo, Ponczek & Sanfelice. Decidir se o código deles serve de base para os scripts `01`–`04`.
3. Baixar o arquivo de emendas da CGU (2015–2026) e montar o primeiro painel deputado × ano × função (Bloco A), que não depende de localização municipal.
4. Rodar `/lit-review` completo (gênero, raça, *credit claiming*) e `/verify-claims` sobre esta lista.
