-- docdesigner: structured authors.
--
-- An author may be a plain string or an object with sub-fields:
--
--   author:
--     - name: "Joseph N. Cohen"
--       dept: "Department of Sociology"
--
-- Pandoc's LaTeX template writes `\author{$author$}`, and a template renders
-- an object as the boolean "true" -- so the title block read "TRUE" (ajs sets
-- the byline in capitals) instead of the name. This filter replaces each
-- object author with its `name` before the template runs, leaving string
-- authors alone, so `\author{}` and the PDF metadata both get the names.
-- Multiple authors stay a list; the template joins them with \and.
--
-- Supported sub-fields: name, dept, inst, address, email, web, orcid and
-- corresponding.
--
-- Before the names replace the objects, the corresponding author's other
-- fields become the contact block the template sets on a title page
-- (title.layout: page) or in the first-page note (header):
--
--   dd-contact         name / dept, inst / address / email · web, one per line
--   dd-contact-note    the same on one line, after "Correspondence:"
--
-- The corresponding author is the one marked `corresponding: true`, else the
-- first author with an address, email or web address. `orcid` is accepted but
-- not shown. `acknowledgments` is accepted as a spelling of `acknowledgements`.

local function is_object(a)
  -- A MetaMap reaches Lua as a plain table with named keys; strings and
  -- inline lists do not carry a `name` field.
  return type(a) == "table" and pandoc.utils.type(a) ~= "Inlines" and a.name ~= nil
end

local function inlines(v)
  if v == nil then return nil end
  if pandoc.utils.type(v) == "Inlines" then return v end
  return pandoc.Inlines(pandoc.utils.stringify(v))
end

local function link(v, scheme)
  local target = pandoc.utils.stringify(v)
  if scheme == "mailto:" then
    target = "mailto:" .. target
  elseif not target:match("^%a[%w+.-]*://") then
    target = "https://" .. target
  end
  return pandoc.Link(inlines(v), target)
end

local function join(parts, sep)
  local out = pandoc.Inlines({})
  for i, p in ipairs(parts) do
    if i > 1 then out:extend(sep) end
    out:extend(p)
  end
  return out
end

local function contact_of(authors)
  local pick
  for _, a in ipairs(authors) do
    if is_object(a) and a.corresponding == true then pick = a; break end
  end
  if not pick then
    for _, a in ipairs(authors) do
      if is_object(a) and (a.address or a.email or a.web) then pick = a; break end
    end
  end
  if not pick or not (pick.address or pick.email or pick.web) then return nil end

  local lines = pandoc.List()
  lines:insert(inlines(pick.name))
  local aff = pandoc.List()
  if pick.dept then aff:insert(inlines(pick.dept)) end
  if pick.inst then aff:insert(inlines(pick.inst)) end
  if #aff > 0 then lines:insert(join(aff, { pandoc.Str(","), pandoc.Space() })) end
  if pick.address then lines:insert(inlines(pick.address)) end
  local reach = pandoc.List()
  if pick.email then reach:insert(pandoc.Inlines({ link(pick.email, "mailto:") })) end
  if pick.web then reach:insert(pandoc.Inlines({ link(pick.web) })) end
  if #reach > 0 then
    lines:insert(join(reach, { pandoc.Space(), pandoc.Str("·"), pandoc.Space() }))
  end

  local block = pandoc.MetaBlocks({ pandoc.Plain(join(lines, { pandoc.LineBreak() })) })
  local note = pandoc.Inlines({ pandoc.Str("Correspondence:"), pandoc.Space() })
  note:extend(join(lines, { pandoc.Str(","), pandoc.Space() }))
  note:insert(pandoc.Str("."))
  return block, pandoc.MetaInlines(note)
end

function Meta(m)
  if m.acknowledgments and not m.acknowledgements then
    m.acknowledgements = m.acknowledgments
  end

  local a = m.author
  if a == nil then return m end
  local authors = is_object(a) and { a } or (pandoc.utils.type(a) == "List" and a or {})
  local block, note = contact_of(authors)
  if block then
    m["dd-contact"] = block
    m["dd-contact-note"] = note
  end

  -- A single object written without a list: author: {name: ...}
  if is_object(a) then
    m.author = pandoc.MetaList({ a.name })
    return m
  end

  if pandoc.utils.type(a) == "List" then
    local out = pandoc.List()
    for _, one in ipairs(a) do
      out:insert(is_object(one) and one.name or one)
    end
    m.author = pandoc.MetaList(out)
  end
  return m
end
