-- docdesigner: two-column table handling.
--
-- Pandoc renders Markdown tables as `longtable` environments, but longtable
-- cannot be used under \twocolumn ("longtable not in 1-column mode"). This
-- filter is applied only for two-column styles: it converts each Table into a
-- page-spanning `table*` float holding a booktabs `tabular`, which typesets
-- correctly across both columns. The engine preamble already loads booktabs.

local function align_char(a)
  if a == "AlignRight" then return "r"
  elseif a == "AlignCenter" then return "c"
  else return "l" end
end

-- Render a table cell's blocks to a LaTeX string (preserves inline markup).
local function cell_latex(cell)
  local s = pandoc.write(pandoc.Pandoc(cell.contents), "latex")
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function row_latex(row)
  local cells = {}
  for _, cell in ipairs(row.cells) do
    cells[#cells + 1] = cell_latex(cell)
  end
  return table.concat(cells, " & ") .. " \\\\"
end

function Table(tbl)
  local aligns = {}
  for _, cs in ipairs(tbl.colspecs) do
    aligns[#aligns + 1] = align_char(cs[1])
  end

  local out = {}
  out[#out + 1] = "\\begin{table*}[t]"
  out[#out + 1] = "\\centering"
  out[#out + 1] = "\\begin{tabular}{" .. table.concat(aligns, "") .. "}"
  out[#out + 1] = "\\toprule"
  for _, row in ipairs(tbl.head.rows) do
    out[#out + 1] = row_latex(row)
  end
  out[#out + 1] = "\\midrule"
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      out[#out + 1] = row_latex(row)
    end
  end
  out[#out + 1] = "\\bottomrule"
  out[#out + 1] = "\\end{tabular}"

  local caption = pandoc.utils.stringify(tbl.caption.long or {})
  if caption ~= "" then
    out[#out + 1] = "\\caption{" .. caption .. "}"
  end
  out[#out + 1] = "\\end{table*}"

  return pandoc.RawBlock("latex", table.concat(out, "\n"))
end
