-- Pinta de azul, no PDF, o texto marcado como revisado no capítulo do livro:
-- ::: {.alterado} ... ::: (blocos) e [trecho]{.alterado} (trechos). A cor "alterado"
-- é definida no cabeçalho gerado por derivar.py. No HTML do livro, o mesmo destaque
-- vem de Quarto/thesis/alteracoes.css.
--
-- Rodada de 25/11 (.revisao): também em azul e, no corpo do texto, com uma marca "25/11" na
-- margem, para distinguir das rodadas anteriores (no HTML, fundo azul-claro). Em legendas,
-- tabelas e notas de rodapé, onde \marginpar não é permitido, a marca é só a cor.

local function latex() return FORMAT:match("latex") end

local function cor(el, nome)
  table.insert(el.content, 1, pandoc.RawInline("latex", "{\\color{" .. nome .. "}"))
  table.insert(el.content, pandoc.RawInline("latex", "}"))
  return el
end

-- \revmarca é definido no cabeçalho gerado por derivar.py e só põe a marca onde o LaTeX
-- permite \marginpar (fora de legendas, tabelas e flutuantes)
local MARGEM = "\\revmarca{}"

-- 1º passo: dentro de notas, tabelas, figuras e imagens, a marca .revisao vira só cor
local function so_cor(el)
  return el:walk({
    Span = function(s)
      if s.classes:includes("revisao") then
        s.classes = pandoc.List({ "revisao-cor" })
        return s
      end
    end
  })
end

local passo1 = { Note = so_cor, Table = so_cor, Figure = so_cor, Image = so_cor }

-- 2º passo: aplica as cores e a marca de margem
local passo2 = {
  Div = function(el)
    if not latex() then return nil end
    if el.classes:includes("alterado") or el.classes:includes("revisao") then
      -- marca de margem no início do primeiro parágrafo do bloco
      local prim = el.content[1]
      if el.classes:includes("revisao") and prim and (prim.t == "Para" or prim.t == "Plain") then
        table.insert(prim.content, 1, pandoc.RawInline("latex", MARGEM))
      end
      table.insert(el.content, 1, pandoc.RawBlock("latex", "\\begingroup\\color{alterado}"))
      table.insert(el.content, pandoc.RawBlock("latex", "\\endgroup"))
      return el
    end
  end,
  Span = function(el)
    if not latex() then return nil end
    if el.classes:includes("alterado") or el.classes:includes("revisao-cor") then
      return cor(el, "alterado")
    end
    if el.classes:includes("revisao") then
      cor(el, "alterado")
      table.insert(el.content, 1, pandoc.RawInline("latex", MARGEM))
      return el
    end
  end
}

return { passo1, passo2 }
