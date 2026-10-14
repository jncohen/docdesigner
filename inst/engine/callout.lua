--[[
callout.lua -- turn a callout div into the ddcallout environment.

  ::: {.callout title="Key finding"}
  Body text, any blocks.
  :::

becomes \begin{ddcallout}{Key finding} ... \end{ddcallout}. dd_preamble()
defines the environment for every style and reads the callout.* tokens, so
this filter carries no look of its own. The title attribute is parsed as
Markdown, so emphasis and LaTeX specials in it come out correctly.

Other output formats are left alone: html() passes the div through with its
class for the site's own CSS.
--]]

local function title_tex(title)
  if title == nil or title == "" then return "" end
  local doc = pandoc.read(title, "markdown")
  if #doc.blocks == 0 then return "" end
  local inlines = doc.blocks[1].content or {}
  return pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "latex"):gsub("%s+$", "")
end

function Div(el)
  if not el.classes:includes("callout") then return nil end
  if not FORMAT:match("latex") then return nil end
  local blocks = {
    pandoc.RawBlock("latex", "\\begin{ddcallout}{" .. title_tex(el.attributes["title"]) .. "}")
  }
  for _, b in ipairs(el.content) do table.insert(blocks, b) end
  table.insert(blocks, pandoc.RawBlock("latex", "\\end{ddcallout}"))
  return blocks
end
