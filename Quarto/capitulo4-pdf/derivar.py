"""Deriva Quarto/capitulo4-pdf/capitulo4.qmd do capítulo do livro.

Fonte: Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd (o livro é a fonte; este
PDF avulso, para o orientador, é derivado dele). Ajustes só do PDF, os mesmos da versão de 18/11:
  - cabeçalho YAML de artigo (article, XeLaTeX, 11pt, margens de 1in, seções numeradas,
    fonte menor nas tabelas) no lugar do título de capítulo;
  - sem os comentários HTML do livro;
  - caminhos das figuras e das tabelas incluídas relativos a esta pasta;
  - tabelas de colunas estreitas copiadas com \\hspace{0pt} no cabeçalho (hifenização);
  - remissões a outros capítulos do livro em texto (o PDF não tem os outros capítulos);
  - seção de Referências no fim.

    python Quarto/capitulo4-pdf/derivar.py
    quarto render Quarto/capitulo4-pdf/capitulo4.qmd
"""
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
FONTE = RAIZ / "Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd"
TABELAS = RAIZ / "Quarto/thesis/chapters/_tabelas-cap3"
DESTINO = Path(__file__).resolve().parent / "capitulo4.qmd"

YAML = """---
title: "Os Efeitos da EC 111/2021"
subtitle: "Candidaturas, Recursos, Votos e Sucesso Eleitoral de Mulheres e Pessoas Negras"
author: "Natália Lucciola"
date: last-modified
lang: pt
bibliography: ../../Bibliography_base.bib
tbl-cap-location: bottom
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
---

<!-- Este arquivo é derivado do capítulo do livro (Quarto/thesis/chapters/03-ec111-competitividade-eleitoral.qmd) por Quarto/capitulo4-pdf/derivar.py. Não editar à mão: editar o capítulo e rodar o script. -->

"""

# Remissões a outros capítulos do livro, escritas por extenso no PDF
REMISSOES = {"@sec-revisao-literatura": "Capítulo 2"}
# Tabelas copiadas com hifenização no cabeçalho
HIFENIZAR = ["amostra.md", "transferencias_cargo.md"]


def main() -> None:
    texto = FONTE.read_text(encoding="utf-8").replace("\r\n", "\n")
    # título do capítulo (primeira linha) sai; o título vai no YAML
    texto = texto.split("\n", 1)[1]
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
