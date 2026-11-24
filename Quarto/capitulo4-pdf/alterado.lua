-- Pinta de azul, no PDF, o texto marcado como revisado no capítulo do livro:
-- ::: {.alterado} ... ::: (blocos) e [trecho]{.alterado} (trechos). A cor "alterado"
-- é definida no cabeçalho gerado por derivar.py. No HTML do livro, o mesmo destaque
-- vem de Quarto/thesis/alteracoes.css.

function Div(el)
  if el.classes:includes("alterado") and FORMAT:match("latex") then
    table.insert(el.content, 1, pandoc.RawBlock("latex", "\\begingroup\\color{alterado}"))
    table.insert(el.content, pandoc.RawBlock("latex", "\\endgroup"))
    return el
  end
end

function Span(el)
  if el.classes:includes("alterado") and FORMAT:match("latex") then
    table.insert(el.content, 1, pandoc.RawInline("latex", "{\\color{alterado}"))
    table.insert(el.content, pandoc.RawInline("latex", "}"))
    return el
  end
end
