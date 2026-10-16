-- docdesigner: table handling.
--
-- Pandoc renders Markdown tables as `longtable` environments. That has two
-- problems this filter solves:
--
--   * Two columns: longtable cannot be used under \twocolumn ("longtable not
--     in 1-column mode"). Every table becomes a float: a `table` in its
--     column when it fits the column, a page-spanning `table*` when not.
--
--   * One column: longtable may break between ANY two rows, so a five-row
--     table falling near the foot of a page splits after its header and one
--     row. A short, simple table becomes a `table` float instead: it stays
--     whole, sits where it falls if it fits, and otherwise moves to the top of
--     the next page while the text keeps filling this one -- what journals do.
--     A long table, or one with wrapping text columns or multi-paragraph
--     cells, stays a longtable: it genuinely needs to cross pages, and a
--     `tabular` cannot wrap text.
--
-- The engine preamble already loads booktabs. The column count arrives as
-- metadata (dd-columns), set by pdf().

local columns = 1
local MAX_FLOAT_ROWS = 25

local function read_meta(m)
  if m["dd-columns"] then
    columns = tonumber(pandoc.utils.stringify(m["dd-columns"])) or 1
  end
  return m
end

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

local function all_rows(tbl)
  local rows = {}
  for _, r in ipairs(tbl.head.rows) do rows[#rows + 1] = r end
  for _, body in ipairs(tbl.bodies) do
    for _, r in ipairs(body.body) do rows[#rows + 1] = r end
  end
  return rows
end

-- A table can become a single-column float only if a plain `tabular` can set
-- it exactly as longtable would: default column widths (no wrapping text
-- columns), single-paragraph cells, no spans, and short enough to keep whole.
local function floatable(tbl)
  for _, cs in ipairs(tbl.colspecs) do
    if type(cs[2]) == "number" then return false end
  end
  local rows = all_rows(tbl)
  if #rows > MAX_FLOAT_ROWS then return false end
  for _, row in ipairs(rows) do
    for _, cell in ipairs(row.cells) do
      if cell.row_span ~= 1 or cell.col_span ~= 1 then return false end
      if #cell.contents > 1 then return false end
      local b = cell.contents[1]
      if b and b.t ~= "Plain" and b.t ~= "Para" then return false end
    end
  end
  return true
end

local function to_float(tbl)
  local aligns = {}
  for _, cs in ipairs(tbl.colspecs) do
    aligns[#aligns + 1] = align_char(cs[1])
  end

  local out = {}
  -- Caption ABOVE the table, matching what pandoc's longtable does (and what
  -- table.caption.position declares). Written through pandoc rather than
  -- stringified, so inline markup survives and LaTeX specials (& % $ # _)
  -- are escaped instead of breaking the build.
  local caption = cell_latex({ contents = tbl.caption.long or {} })
  local cap = caption ~= "" and ("\\caption{" .. caption .. "}") or ""

  -- The tabular is set into a box first. Size and zebra shading come from the
  -- engine preamble's \ddtablesetup; longtable gets the same setup from a
  -- hook, and this float is not a longtable, so it asks here.
  out[#out + 1] = "\\begingroup"
  local setup = "\\ifdefined\\ddtablesetup\\ddtablesetup\\fi"
  out[#out + 1] = "\\ifdefined\\ddtabbox\\else\\newsavebox{\\ddtabbox}\\fi"
  -- \normalfont\normalsize: what a float resets to before its body, so the box
  -- is set exactly as the tabular was inside the float (lining figures in a
  -- style whose body text uses oldstyle ones).
  out[#out + 1] = "\\sbox{\\ddtabbox}{\\normalfont\\normalsize" .. setup
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
  out[#out + 1] = "\\end{tabular}}"

  -- One column: a `table` float. Two columns: the table stays in its column
  -- when it fits the column, and only a table wider than the column becomes a
  -- page-spanning `table*` -- decided by LaTeX, which knows the set width.
  -- Only the chosen branch runs, so the caption is counted once. The setup is
  -- repeated inside the float so the caption is set at the table's size, as
  -- it always was.
  local function float(env, place)
    return "\\begin{" .. env .. "}" .. place .. "\\centering" .. setup .. cap ..
      "\\usebox{\\ddtabbox}\\end{" .. env .. "}"
  end
  if columns == 2 then
    out[#out + 1] = "\\ifdim\\wd\\ddtabbox>\\columnwidth " .. float("table*", "[t]")
    out[#out + 1] = "\\else " .. float("table", "[!htbp]") .. "\\fi"
  else
    out[#out + 1] = float("table", "[!htbp]")
  end
  out[#out + 1] = "\\endgroup"

  return pandoc.RawBlock("latex", table.concat(out, "\n"))
end

local function handle_table(tbl)
  -- Two columns: every table must leave longtable. One column: only those a
  -- float can carry; the rest keep longtable's ability to cross pages.
  if columns == 2 or floatable(tbl) then
    return to_float(tbl)
  end
  return nil
end

-- Two passes, so the column count is read before any table is visited.
return {
  { Meta = read_meta },
  { Table = handle_table }
}
