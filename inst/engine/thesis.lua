-- docdesigner: thesis title page (title.layout: thesis).
--
-- The style supplies defaults (pdf() passes them as dd-thesis-defaults); the
-- document's own fields win:
--
--   degree: "Master of Arts in Sociology"
--   institution: ["Queens College", "The City University of New York"]
--   statement: "A thesis submitted in partial fulfillment of ..."
--   committee:
--     - name: "Joseph N. Cohen"
--       role: "Committee Chair"
--   signatures: true      # signature lines for the committee
--   copyright: true       # or the text of the copyright line
--
-- The template reads the merged results as dd-statement, dd-degree,
-- dd-institution, dd-committee, dd-signatures, dd-copyright and
-- dd-front-roman.

local str = pandoc.utils.stringify

-- A field the document leaves empty ("") falls back to the style default.
local function given(v)
  if v == nil or str(v) == "" then return nil end
  return v
end

local function inlines(v)
  if v == nil then return nil end
  if pandoc.utils.type(v) == "Inlines" then return v end
  return pandoc.Inlines(str(v))
end

local function truthy(v)
  if v == nil then return nil end
  if type(v) == "boolean" then return v end
  local s = str(v):lower()
  return s == "true" or s == "yes"
end

local function lines(v)
  if v == nil then return nil end
  local out = pandoc.List()
  if pandoc.utils.type(v) == "List" then
    for _, x in ipairs(v) do out:insert(pandoc.MetaInlines(inlines(x))) end
  else
    for line in str(v):gmatch("[^\n]+") do out:insert(pandoc.MetaInlines(pandoc.Inlines(line))) end
  end
  return out
end

function Meta(m)
  local d = m["dd-thesis-defaults"] or {}

  local statement = given(m.statement) or d.statement
  if statement and str(statement) ~= "" then m["dd-statement"] = pandoc.MetaInlines(inlines(statement)) end

  local degree = given(m.degree) or d.degree
  if degree and str(degree) ~= "" then m["dd-degree"] = pandoc.MetaInlines(inlines(degree)) end

  local inst = lines(given(m.institution)) or lines(d.institution)
  if inst and #inst > 0 then m["dd-institution"] = pandoc.MetaList(inst) end

  local sig = truthy(m.signatures)
  if sig == nil then sig = truthy(d.signatures) end
  if sig then
    m["dd-signatures"] = true
    local committee = pandoc.List()
    if m.committee and pandoc.utils.type(m.committee) == "List" then
      for _, c in ipairs(m.committee) do
        if type(c) == "table" and c.name then
          committee:insert(pandoc.MetaMap({ name = c.name, role = c.role or pandoc.MetaString("") }))
        else
          committee:insert(pandoc.MetaMap({ name = c, role = pandoc.MetaString("") }))
        end
      end
    end
    -- No committee named: one line for the chair to sign.
    if #committee == 0 then
      committee:insert(pandoc.MetaMap({ name = pandoc.MetaString(""),
                                        role = pandoc.MetaString("Committee Chair") }))
    end
    m["dd-committee"] = pandoc.MetaList(committee)
  end

  local cr = m.copyright
  if cr ~= nil and truthy(cr) ~= false then
    if truthy(cr) == true then
      local year = (m.date and str(m.date):match("%d%d%d%d")) or os.date("%Y")
      local names = {}
      if m.author then
        local a = pandoc.utils.type(m.author) == "List" and m.author or { m.author }
        for _, x in ipairs(a) do names[#names + 1] = str(x) end
      end
      m["dd-copyright"] = pandoc.MetaInlines(pandoc.Inlines(
        "© " .. year .. " " .. table.concat(names, ", ") .. ". All rights reserved."))
    else
      m["dd-copyright"] = pandoc.MetaInlines(inlines(cr))
    end
  end

  if truthy(d.roman) then m["dd-front-roman"] = true end
  m["dd-thesis-defaults"] = nil
  return m
end
