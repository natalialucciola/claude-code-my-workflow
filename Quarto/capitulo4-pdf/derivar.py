"""Deriva Quarto/capitulo4-pdf/capitulo4.qmd do capítulo do livro.

Fonte: Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd (o livro é a fonte; este
PDF avulso, para o orientador, é derivado dele). Ajustes só do PDF, os mesmos da versão de 18/11:
  - cabeçalho YAML de artigo (article, XeLaTeX, 11pt, margens de 1in, seções numeradas,
    fonte menor nas tabelas) no lugar do título de capítulo;
  - sem os comentários HTML do livro;
  - caminhos das figuras e das tabelas incluídas relativos a esta pasta;
  - tabelas de colunas estreitas copiadas com \\hspace{0pt} no cabeçalho (hifenização);
  - remissões a outros capítulos do livro em texto (o PDF não tem os outros capítulos);
  - apêndice do capítulo (Quarto/thesis/chapters/A1-apendice-ec111.qmd, desde 25/11) no fim,
    depois de \\appendix, com os títulos um nível abaixo (seção A);
  - seção de Referências no fim.

    python Quarto/capitulo4-pdf/derivar.py
    quarto render Quarto/capitulo4-pdf/capitulo4.qmd
"""
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
FONTE = RAIZ / "Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd"
APENDICE = RAIZ / "Quarto/thesis/chapters/A1-apendice-ec111.qmd"
TABELAS = RAIZ / "Quarto/thesis/chapters/_tabelas-cap3"
DESTINO = Path(__file__).resolve().parent / "capitulo4.qmd"

YAML = """---
title: "Os Efeitos da EC 111/2021"
subtitle: "Candidaturas, Recursos, Votos e Sucesso Eleitoral de Mulheres e Pessoas Negras"
author: "Natália Lucciola"
date: last-modified
date-format: "DD/MM/YYYY"
lang: pt
bibliography: ../../Bibliography_base.bib
tbl-cap-location: top
format:
  pdf:
    documentclass: article
    number-sections: true
    geometry: margin=1in
    pdf-engine: xelatex
    fontsize: 11pt
    include-in-header:
      text: |
        \\usepackage{etoolbox}
        \\AtBeginEnvironment{longtable}{\\footnotesize}
        \\usepackage{xcolor}
        \\definecolor{alterado}{HTML}{1D4ED8}
        % marca "25/11" na margem (rodada .revisao); omitida onde \\marginpar não é permitido
        % (legendas, tabelas, flutuantes), pelos mesmos testes que o LaTeX faz
        \\makeatletter
        \\newcommand{\\revmarca}{\\ifhmode\\ifinner\\else\\ifnum\\@floatpenalty<\\z@\\else
          \\marginpar{\\raggedright\\scriptsize\\sffamily\\color{alterado}25/11}\\fi\\fi\\fi}
        \\makeatother
filters:
  # pre-ast: o filtro vê as tabelas e figuras como elementos do Pandoc, antes de o Quarto
  # transformá-las em flutuantes, e consegue tirar a marca de margem das legendas
  - path: alterado.lua
    at: pre-ast
---

<!-- Este arquivo é derivado do capítulo do livro (Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd) por Quarto/capitulo4-pdf/derivar.py. Não editar à mão: editar o capítulo e rodar o script. -->

"""

# Remissões a outros capítulos do livro, escritas por extenso no PDF
REMISSOES = {"@sec-revisao-literatura": "Capítulo 2"}
# Tabelas copiadas com hifenização no cabeçalho
HIFENIZAR = ["amostra.md", "transferencias_cargo.md", "descritivo_competitividade.md",
             "reg_mulheres_recursos.md", "reg_mulheres_votos.md", "reg_negras_recursos.md",
             "reg_negras_votos.md", "reg_mulheres_negras_recursos.md",
             "reg_mulheres_negras_votos.md", "viabilidade.md",
             "falsificacao.md", "composicao_lista.md", "sucesso.md", "decomposicao.md",
             "matriz_viabilidade.md"]


def main() -> None:
    texto = FONTE.read_text(encoding="utf-8").replace("\r\n", "\n")
    # YAML do capítulo (tbl-cap-location, desde 26/11) sai; o do PDF está em YAML acima
    texto = re.sub(r"\A---\n.*?\n---\n+", "", texto, flags=re.S)
    # título do capítulo (primeira linha) sai; o título vai no YAML
    texto = texto.split("\n", 1)[1]
    # apêndice: título do apêndice vira seção (##) e as seções dele, subseções (###)
    apendice = APENDICE.read_text(encoding="utf-8").replace("\r\n", "\n")
    apendice = re.sub(r"^(#+) ", lambda m: "#" + m.group(1) + " ", apendice, flags=re.M)
    apendice = apendice.replace("Capítulo [-@sec-ec111-competitividade]", "texto")
    texto = texto.rstrip() + "\n\n```{=latex}\n\\appendix\n```\n\n" + apendice
    # blocos HTML do livro (comentários de trabalho)
    texto = re.sub(r"```\{=html\}\n.*?\n```\n?", "", texto, flags=re.S)
    texto = texto.replace("](../Figures/", "](../thesis/Figures/")
    for ref, extenso in REMISSOES.items():
        texto = texto.replace(ref, extenso)
    definidas = set(re.findall(r"\{#(sec-[a-z0-9-]+)", texto))
    sobra = sorted(r for r in set(re.findall(r"@(sec-[a-z0-9-]+)", texto)) if r not in definidas)
    if sobra:
        raise SystemExit(f"Remissões a outros capítulos sem tradução: {sobra}")

    # tabelas com colunas estreitas: copiadas com \hspace{0pt} em cada célula do cabeçalho,
    # o que permite ao LaTeX hifenizar a primeira palavra da célula
    for nome in HIFENIZAR:
        tab = (TABELAS / nome).read_text(encoding="utf-8").replace("\r\n", "\n").strip()
        cab, resto = tab.split("\n", 1)
        celulas = [c.strip() for c in cab.strip("|").split("|")]
        cab = "| " + " | ".join(r"`\hspace{0pt}`{=latex}" + c for c in celulas) + " |"
        texto = texto.replace(
            "{{< include _tabelas-cap3/%s >}}" % nome,
            "<!-- Cópia de ../thesis/chapters/_tabelas-cap3/%s, com \\hspace{0pt} no cabeçalho "
            "para permitir a hifenização em coluna estreita no PDF. -->\n\n%s\n%s"
            % (nome, cab, resto))
    texto = texto.replace("{{< include _tabelas-cap3/", "{{< include ../thesis/chapters/_tabelas-cap3/")

    with open(DESTINO, "w", encoding="utf-8", newline="\n") as saida:
        saida.write(YAML + texto.strip() + "\n\n## Referências {#refs .unnumbered}\n")
    print(f"Escrito {DESTINO.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
