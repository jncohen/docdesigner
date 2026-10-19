--[=[
markup.lua -- draft markup for a manuscript printed to be marked up by hand.

Driven by metadata pdf() sets from the markup.* tokens:

  dd-markup-parnum      true: number body paragraphs (\ddparnum, inner margin)
  dd-markup-changebars  true: wrap paragraphs absent from the reference text
                        in \cbstart ... \cbend
  dd-changes-ref        path to the reference text (pdf()'s pre-processor)
  dd-markup-flags       true: [[TAG]] and [[TAG: words]] become margin tags
  dd-markup-citekeys    true: each citation is followed by its key

Paragraphs are compared and numbered BEFORE anything is added to them. Only
paragraphs in the body's own flow are numbered: top-level ones and those in
divs (callouts), not list items, quotations or table cells, which are part of
a numbered paragraph's neighbourhood rather than paragraphs of the argument.
The macros are defined by dd_markup_preamble() in R/markup.R.
--]=]

local stringify = pandoc.utils.stringify

local TAGS = { TODO = true, CITE = true, WEAK = true, CUT = true, CHECK = true, FIX = true }

local function raw(s) return pandoc.RawInline("latex", s) end

local function norm(s)
  return (s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
end

-- Text of a block with any raw LaTeX dropped, for comparison and counting.
local function plain_text(b)
  local clean = b:walk({ RawInline = function() return {} end })
  return norm(stringify(clean))
end

local function image_only(p)
  for _, el in ipairs(p.content) do
    if el.t ~= "Image" and el.t ~= "Space" and el.t ~= "SoftBreak" then return false end
  end
  return true
end

-- The comparison key for changebars: the text with inline code and citations
-- removed (a citation may already be rendered in the current text but not in
-- the reference), and only the tokens that hold a letter and no digit. A reference is usually the .Rmd source, whose
-- `r ...` inline code has not been evaluated, while the current text holds
-- the numbers it produced. Ignoring both, bars track edits to the prose; a
-- number that changes because the data or code changed is not marked.
local function compare_key(b)
  local clean = b:walk({ RawInline = function() return {} end,
                         Code = function() return {} end,
                         Cite = function() return {} end })
  local words = {}
  for w in stringify(clean):gmatch("%S+") do
    if w:find("%a") and not w:find("%d") then words[#words + 1] = w end
  end
  return table.concat(words, " ")
end

-- The paragraphs of the reference text, as a set of comparison keys.
local function reference_set(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local txt = f:read("a")
  f:close()
  -- An R Markdown chunk header (```{r setup, include=FALSE}) is not a valid
  -- pandoc fence, so its backticks would pair up with the next chunk's and
  -- swallow the prose between them. Chunks hold no prose: drop them.
  local kept, fence = {}, nil
  for line in (txt .. "\n"):gmatch("(.-)\r?\n") do
    if fence then
      if line:match("^%s*" .. fence .. "+%s*$") then fence = nil end
    else
      local f2 = line:match("^%s*(```+)%s*{") or line:match("^%s*(~~~+)%s*{")
      if f2 then fence = f2:sub(1, 3) else kept[#kept + 1] = line end
    end
  end
  txt = table.concat(kept, "\n")
  local ok, doc = pcall(pandoc.read, txt, "markdown")
  if not ok then return nil end
  local set = {}
  doc:walk({
    Para = function(p) set[compare_key(p)] = true end,
    Plain = function(p) set[compare_key(p)] = true end
  })
  return set
end

-- --- Flags ----------------------------------------------------------------
-- [[ and ]] may sit inside a Str ("claim[[CITE]].") or span several inlines
-- ("[[TODO:", Space, "rerun]]"). Split them out as markers first, then pair.

local function is_marker(x) return type(x) == "table" and x.marker ~= nil end

local function split_markers(inls)
  local out = {}
  for _, el in ipairs(inls) do
    if el.t == "Str" and (el.text:find("[[", 1, true) or el.text:find("]]", 1, true)) then
      local t, pos = el.text, 1
      while true do
        local a = t:find("[[", pos, true)
        local b = t:find("]]", pos, true)
        local at, kind
        if a and (not b or a < b) then at, kind = a, "open"
        elseif b then at, kind = b, "close"
        else break end
        if at > pos then out[#out + 1] = pandoc.Str(t:sub(pos, at - 1)) end
        out[#out + 1] = { marker = kind }
        pos = at + 2
      end
      if pos <= #t then out[#out + 1] = pandoc.Str(t:sub(pos)) end
    else
      out[#out + 1] = el
    end
  end
  return out
end

local function literal(items)
  local res = pandoc.Inlines({})
  for _, x in ipairs(items) do
    if is_marker(x) then res:insert(pandoc.Str(x.marker == "open" and "[[" or "]]"))
    else res:insert(x) end
  end
  return res
end

-- The inlines between [[ and ]], as a flag, or nil when they are not one.
local function make_flag(inner)
  local first = inner[1]
  if not first or is_marker(first) or first.t ~= "Str" then return nil end
  for _, x in ipairs(inner) do if is_marker(x) then return nil end end
  local tag, rest = first.text:match("^(%u+%??):(.*)$")
  if not tag then
    tag = first.text:match("^(%u+%??)$")
    if not tag or #inner > 1 then return nil end
  end
  if not TAGS[tag] then return nil end
  local out = pandoc.Inlines({ raw("\\ddflag{" .. tag .. "}") })
  local words = pandoc.Inlines({})
  if rest and rest ~= "" then words:insert(pandoc.Str(rest)) end
  for k = 2, #inner do
    local x = inner[k]
    if not (#words == 0 and (x.t == "Space" or x.t == "SoftBreak")) then words:insert(x) end
  end
  if #words > 0 then
    out:insert(raw("\\ddflagtext{"))
    out:extend(words)
    out:insert(raw("}"))
  end
  return out
end

local function flag_inlines(inls)
  if not stringify(inls):find("[[", 1, true) then return nil end
  local toks = split_markers(inls)
  local res = pandoc.Inlines({})
  local i = 1
  while i <= #toks do
    local t = toks[i]
    if is_marker(t) and t.marker == "open" then
      local j = i + 1
      while j <= #toks and not (is_marker(toks[j]) and toks[j].marker == "close") do j = j + 1 end
      if j > #toks then
        res:insert(pandoc.Str("[["))
        i = i + 1
      else
        local inner = { table.unpack(toks, i + 1, j - 1) }
        local flag = make_flag(inner)
        if flag and #flag == 1 and #res > 0 and res[#res].t == "Space" then
          -- A bare tag leaves nothing in the text, so it must not leave a
          -- doubled space or a space before punctuation either.
          local nxt = toks[j + 1]
          if nxt and not is_marker(nxt) and nxt.t == "Space" then
            j = j + 1
          elseif nxt and not is_marker(nxt) and nxt.t == "Str" and nxt.text:match("^[%.,;:!?%)]") then
            res:remove(#res)
          end
        end
        if flag then res:extend(flag)
        else
          res:insert(pandoc.Str("[["))
          res:extend(literal(inner))
          res:insert(pandoc.Str("]]"))
        end
        i = j + 1
      end
    elseif is_marker(t) then
      res:insert(pandoc.Str("]]"))
      i = i + 1
    else
      res:insert(t)
      i = i + 1
    end
  end
  return res
end

-- --- The filter -------------------------------------------------------------

function Pandoc(doc)
  if not FORMAT:match("latex") then return nil end
  local function opt(k) return doc.meta[k] and stringify(doc.meta[k]) or "" end
  local parnum = opt("dd-markup-parnum") == "true"
  local flags = opt("dd-markup-flags") == "true"
  local citekeys = opt("dd-markup-citekeys") == "true"
  local refs = nil
  if opt("dd-markup-changebars") == "true" and opt("dd-changes-ref") ~= "" then
    refs = reference_set(opt("dd-changes-ref"))
  end

  -- Levels set run-in: h4 always, plus any in headings.run_in. A run-in
  -- heading opens its paragraph's first line, so that paragraph's number
  -- goes on the heading; set after it, it would print over the heading.
  local runin = { [4] = true }
  for lv in opt("dd-runin-levels"):gmatch("%d") do runin[tonumber(lv)] = true end

  local count = 0
  local function mark(blocks)
    for i, b in ipairs(blocks) do
      if b.t == "Para" and not image_only(b) then
        local text = plain_text(b)
        if text ~= "" then
          local pre = pandoc.Inlines({})
          local changed = refs ~= nil and not refs[compare_key(b)]
          if changed then pre:insert(raw("\\cbstart{}")) end
          if parnum then
            count = count + 1
            local prev = blocks[i - 1]
            if prev and prev.t == "Header" and runin[prev.level] then
              -- pandoc keeps it out of the PDF bookmark (\\texorpdfstring).
              prev.content:insert(1, raw("\\ddparnumhead{" .. count .. "}"))
            else
              pre:insert(raw("\\ddparnum{" .. count .. "}"))
            end
          end
          local content = pandoc.Inlines({})
          content:extend(pre)
          content:extend(b.content)
          if changed then content:insert(raw("\\cbend{}")) end
          b.content = content
        end
      elseif b.t == "Div" then
        mark(b.content)
      elseif refs and (b.t == "BulletList" or b.t == "OrderedList" or b.t == "BlockQuote") then
        -- Lists and quotations take changebars, but not paragraph numbers.
        local items = b.t == "BlockQuote" and { b.content } or b.content
        for _, item in ipairs(items) do
          for _, x in ipairs(item) do
            if (x.t == "Para" or x.t == "Plain") and plain_text(x) ~= "" and not refs[compare_key(x)] then
              local c = pandoc.Inlines({ raw("\\cbstart{}") })
              c:extend(x.content)
              c:insert(raw("\\cbend{}"))
              x.content = c
            end
          end
        end
      end
    end
  end
  if parnum or refs then mark(doc.blocks) end

  local walkers = {}
  if flags then
    walkers.Para = function(p) local c = flag_inlines(p.content); if c then p.content = c; return p end end
    walkers.Plain = function(p) local c = flag_inlines(p.content); if c then p.content = c; return p end end
  end
  if citekeys then
    walkers.Cite = function(c)
      local keys = {}
      for _, ct in ipairs(c.citations) do keys[#keys + 1] = ct.id end
      return { c, raw("\\ddcitekey{\\detokenize{" .. table.concat(keys, ", ") .. "}}") }
    end
  end
  if next(walkers) then doc = doc:walk(walkers) end
  return doc
end
