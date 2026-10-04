-- docdesigner: table header treatment.
--
-- Pandoc emits a Markdown table's header as ordinary cells sitting between
-- \toprule and \midrule, with no macro wrapped around them. There is therefore
-- nothing for the preamble to hook: a font declaration placed after \toprule
-- lands inside the first cell only, because declarations do not survive `&`.
-- The treatment has to be applied to the document tree instead, before the
-- table becomes LaTeX.
--
-- Applied only when a style sets table.header.weight or .case away from the
-- engine default. Must run BEFORE twocolumn-tables.lua, which rewrites Tables
-- into raw LaTeX -- that filter renders each cell with pandoc.write, so the
-- markup added here survives the conversion.

local weight = "bold"
local case = "none"

local function read_meta(m)
  if m["dd-table-header-weight"] then
    weight = pandoc.utils.stringify(m["dd-table-header-weight"])
  end
  if m["dd-table-header-case"] then
    case = pandoc.utils.stringify(m["dd-table-header-case"])
  end
  return m
end

local function style_inlines(inlines)
  if case == "upper" then
    inlines = pandoc.walk_inline(pandoc.Span(inlines), {
      Str = function(s) return pandoc.Str(pandoc.text.upper(s.text)) end
    }).content
  elseif case == "smallcaps" then
    inlines = { pandoc.SmallCaps(inlines) }
  end
  if weight == "bold" then
    inlines = { pandoc.Strong(inlines) }
  end
  return inlines
end

local function style_cell(cell)
  cell.contents = pandoc.walk_block(pandoc.Div(cell.contents), {
    Plain = function(p) return pandoc.Plain(style_inlines(p.content)) end,
    Para  = function(p) return pandoc.Para(style_inlines(p.content)) end
  }).content
  return cell
end

local function style_table(tbl)
  for _, row in ipairs(tbl.head.rows) do
    for i, cell in ipairs(row.cells) do
      row.cells[i] = style_cell(cell)
    end
  end
  return tbl
end

-- Two passes, so the metadata is read before any table is visited.
return {
  { Meta = read_meta },
  { Table = style_table }
}
