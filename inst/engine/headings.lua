--[=[
headings.lua -- the headings as a map of the argument.

Driven by metadata pdf() sets:

  dd-map-depth        1-3: open the body with a table of every heading to
                      this depth, with its section number, the words under
                      it and the page it starts on (markup.map). 0: off.
  dd-claim-check      true: flag [[LABEL?]] beside a heading of fewer than
                      four words, a label where a claim belongs
                      (markup.claim_check)
  dd-section-chars    > 0: define each level-1 heading's number and text,
                      cut to this many characters, for the running head,
                      and label where each starts (header_footer.section_chars)
  dd-number-sections  true when the style numbers its headings

Only headings in the body's own flow (doc.blocks) are read. Numbers are
counted here, as LaTeX will set them, so a running head carries its number
rather than a \thesection evaluated at the wrong moment. Page numbers come from
\pageref on the label pandoc writes after every heading, and settle on
LaTeX's second pass. The macros are defined in R/markup.R and R/engine.R.
--]=]

local stringify = pandoc.utils.stringify

-- Headings that are apparatus, not argument: never mapped or flagged.
local SKIP = { references = true, bibliography = true, ["works cited"] = true,
               appendix = true, appendices = true, notes = true,
               acknowledgements = true, acknowledgments = true }

local function text_of(el)
  local clean = el:walk({ RawInline = function() return {} end })
  return (stringify(clean):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

local PROSE = { Para = true, Plain = true, BlockQuote = true, BulletList = true,
                OrderedList = true, LineBlock = true, DefinitionList = true, Div = true }

local function word_count(b)
  if not PROSE[b.t] then return 0 end
  local n = 0
  for _ in text_of(b):gmatch("%S+") do n = n + 1 end
  return n
end

local function raw_has(b, pats)
  if b.t ~= "RawBlock" then return false end
  for _, p in ipairs(pats) do if b.text:find(p, 1, true) then return true end end
  return false
end

local function is_figure(b)
  if b.t == "Figure" then return true end
  if b.t == "Para" and #b.content == 1 and b.content[1].t == "Image" then return true end
  return raw_has(b, { "\\begin{figure", "\\includegraphics" })
end

local function is_table(b)
  return b.t == "Table" or raw_has(b, { "\\begin{table", "\\begin{longtable", "\\begin{tabular" })
end

local function commas(n)
  local s = tostring(n)
  while true do
    local k
    s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
    if k == 0 then return s end
  end
end

local function tex(s)
  s = s:gsub("\\", "\0")
  s = s:gsub("([#$%%&_{}])", "\\%1")
  s = s:gsub("~", "\\textasciitilde{}"):gsub("%^", "\\textasciicircum{}")
  return (s:gsub("%z", "\\textbackslash{}"))
end

local function cut(s, n)
  if pandoc.text.len(s) <= n then return s end
  local head = pandoc.text.sub(s, 1, n)
  local at = head:match("^.*() ")
  if at and at > n / 2 then head = head:sub(1, at - 1) end
  return head .. "\u{2026}"
end

local function latex_inlines(inls)
  local s = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inls) }), "latex")
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Pandoc(doc)
  if not FORMAT:match("latex") then return nil end
  local function opt(k) return doc.meta[k] and stringify(doc.meta[k]) or "" end
  local depth = tonumber(opt("dd-map-depth")) or 0
  local claim = opt("dd-claim-check") == "true"
  local chars = tonumber(opt("dd-section-chars")) or 0
  local numbered = opt("dd-number-sections") == "true"
  local blocks = doc.blocks

  -- Section numbers, as LaTeX will set them (h1-h3; h4 is run-in, unnumbered).
  local counters, info = { 0, 0, 0 }, {}
  for k, b in ipairs(blocks) do
    if b.t == "Header" then
      local unnum = b.classes:includes("unnumbered") or b.classes:includes("-")
      local name = text_of(b)
      local num = ""
      if numbered and not unnum and b.level <= 3 then
        counters[b.level] = counters[b.level] + 1
        for l = b.level + 1, 3 do counters[l] = 0 end
        local parts = {}
        for l = 1, b.level do parts[#parts + 1] = tostring(counters[l]) end
        num = table.concat(parts, ".")
      end
      if b.identifier == "" then b.identifier = "dd-sec-" .. k end
      info[k] = { num = num, name = name, unnum = unnum,
                  apparatus = SKIP[name:lower()] or false }
    end
  end

  -- Words under each heading: everything up to the next heading at its level
  -- or above. Totals for the foot of the map.
  local total, tables, figures = 0, 0, 0
  for k, b in ipairs(blocks) do
    if info[k] then
      local n = 0
      for j = k + 1, #blocks do
        local x = blocks[j]
        if x.t == "Header" and x.level <= b.level then break end
        n = n + word_count(x)
      end
      info[k].words = n
    else
      total = total + word_count(b)
      if is_table(b) then tables = tables + 1 end
      if is_figure(b) then figures = figures + 1 end
    end
  end

  local out = {}

  -- Running-head titles: every level-1 heading, numbered and cut, defined
  -- up front; \ddsecanchor marks where each starts.
  if chars > 0 then
    local defs, n = {}, 0
    for k, b in ipairs(blocks) do
      if info[k] and b.level == 1 then
        n = n + 1
        info[k].sec = n
        local label = (info[k].num ~= "" and (info[k].num .. "\\enspace ") or "") .. tex(cut(info[k].name, chars))
        defs[#defs + 1] = "\\ddsectitle{" .. n .. "}{" .. label .. "}"
      end
    end
    if n > 0 then out[#out + 1] = pandoc.RawBlock("latex", table.concat(defs, "\n")) end
  end

  if depth > 0 then
    local rows = {}
    for k, b in ipairs(blocks) do
      local h = info[k]
      if h and b.level <= depth and not h.unnum and not h.apparatus then
        local title = latex_inlines(b.content)
        local cell
        if b.level == 1 then
          rows[#rows + 1] = string.format("%s & %s & %s & \\pageref{%s}\\\\",
            h.num, title, commas(h.words), b.identifier)
        else
          cell = (h.num ~= "" and (h.num .. "\\quad ") or "") .. title
          rows[#rows + 1] = string.format(" & \\ddmapsub{%s} & \\leavevmode{\\color{muted}%s} & \\leavevmode{\\color{muted}\\pageref{%s}}\\\\",
            cell, commas(h.words), b.identifier)
        end
      end
    end
    if #rows > 0 then
      local function plural(n, one, many) return commas(n) .. " " .. (n == 1 and one or many) end
      local totals = { plural(total, "word", "words"), "\\pageref*{LastPage}~\\ifnum\\getpagerefnumber{LastPage}=1 page\\else pages\\fi{}" }
      if tables > 0 then totals[#totals + 1] = plural(tables, "table", "tables") end
      if figures > 0 then totals[#totals + 1] = plural(figures, "figure", "figures") end
      local L = {
        "\\ddmapopen",
        -- A tabular, not a longtable: the map is read whole, so it never
        -- splits across a page.
        "{\\ddlabelfont\\ifdefined\\ddtablesetup\\ddtablesetup\\fi\\noindent",
        "\\begin{tabular}{@{}p{2.2em}@{}>{\\raggedright\\arraybackslash}p{\\dimexpr\\linewidth-8.6em\\relax}" ..
          "@{}>{\\raggedleft\\arraybackslash}p{3.8em}@{}>{\\raggedleft\\arraybackslash}p{2.6em}@{}}",
        "\\toprule",
        "\\ddmaphd{\\S} & \\ddmaphd{Claim} & \\ddmaphd{Words} & \\ddmaphd{p.}\\\\",
        "\\midrule",
      }
      for _, r in ipairs(rows) do L[#L + 1] = r end
      L[#L + 1] = "\\midrule"
      L[#L + 1] = "\\multicolumn{4}{@{}l@{}}{\\ddmaptotal{" ..
        table.concat(totals, " \\textperiodcentered\\ ") .. "}}\\\\"
      L[#L + 1] = "\\end{tabular}\\par}"
      L[#L + 1] = "\\ddmapclose"
      out[#out + 1] = pandoc.RawBlock("latex", table.concat(L, "\n"))
    end
  end

  for k, b in ipairs(blocks) do
    out[#out + 1] = b
    local h = info[k]
    if h then
      if chars > 0 and b.level == 1 and h.sec then
        out[#out + 1] = pandoc.RawBlock("latex", "\\ddsecanchor{" .. h.sec .. "}")
      end
      if claim and b.level <= 3 and not h.unnum and not h.apparatus then
        local n = 0
        for _ in h.name:gmatch("%S+") do n = n + 1 end
        local nxt = blocks[k + 1]
        if n < 4 and nxt and nxt.t == "Para" then
          nxt.content:insert(1, pandoc.RawInline("latex", "\\ddheadflag{LABEL?}"))
        end
      end
    end
  end

  doc.blocks = out
  return doc
end
