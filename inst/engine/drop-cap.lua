-- docdesigner: opening drop cap.
--
-- lettrine needs to wrap the first CHARACTER of one specific paragraph, which
-- is not something a preamble can express: there is no hook for "the first
-- paragraph of the body". Pandoc's tree has one, so the split happens here and
-- the preamble only loads the package.
--
-- The first Para in the document is used, not the first block, so a leading
-- Header ("# Introduction") is stepped over. The abstract arrives via metadata
-- rather than the block list, so it is never a candidate.
--
-- Applied only when a style sets paragraph.drop_cap.lines. The schema's
-- dropcap-twocolumn rule warns that lettrine is unreliable under two columns;
-- the engine gates on that separately.

local lines = 3
local color = "accent"

local function read_meta(m)
  if m["dd-dropcap-lines"] then
    lines = tonumber(pandoc.utils.stringify(m["dd-dropcap-lines"])) or lines
  end
  if m["dd-dropcap-color"] then
    color = pandoc.utils.stringify(m["dd-dropcap-color"])
  end
  return m
end

local function drop_cap(para)
  local first = para.content[1]
  if not first or first.t ~= "Str" then return para end
  local text = first.text
  if pandoc.text.len(text) < 2 then return para end

  local initial = pandoc.text.sub(text, 1, 1)
  local rest = pandoc.text.sub(text, 2)
  local tex = string.format("\\lettrine[lines=%d]{\\color{%s}%s}{}", lines, color, initial)

  local out = { pandoc.RawInline("latex", tex), pandoc.Str(rest) }
  for i = 2, #para.content do
    out[#out + 1] = para.content[i]
  end
  return pandoc.Para(out)
end

local function first_para(doc)
  for i, block in ipairs(doc.blocks) do
    if block.t == "Para" then
      doc.blocks[i] = drop_cap(block)
      break
    end
  end
  return doc
end

return {
  { Meta = read_meta },
  { Pandoc = first_para }
}
