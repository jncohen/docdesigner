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
-- The other sub-fields (dept, inst, email, web, orcid) are not rendered yet:
-- the title-page contact block belongs to the template port.

local function is_object(a)
  -- A MetaMap reaches Lua as a plain table with named keys; strings and
  -- inline lists do not carry a `name` field.
  return type(a) == "table" and pandoc.utils.type(a) ~= "Inlines" and a.name ~= nil
end

function Meta(m)
  local a = m.author
  if a == nil then return nil end

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
    return m
  end

  return nil
end
