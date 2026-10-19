--[[
underline.lua -- keep links out of underlines in LaTeX.

pandoc writes [text]{.underline} as soul's \ul{...}. soul typesets its
argument letter by letter and cannot take \url or \href inside it, so an
underlined reference with its URL stops LaTeX ("Argument of \hyper@n@rmalise
has an extra }"). Here the links come out of the underline: the text around
them stays underlined, the links are set plain. A link nested deeper (inside
emphasis inside the underline) takes its whole piece out of the underline.

Other output formats are left alone.
--]]

local function has_link(inls)
  local found = false
  pandoc.Inlines(inls):walk({ Link = function() found = true end })
  return found
end

function Underline(el)
  if not FORMAT:match("latex") then return nil end
  if not has_link(el.content) then return nil end
  local out, run = pandoc.Inlines({}), pandoc.Inlines({})
  local function flush()
    if #run > 0 then out:insert(pandoc.Underline(run)); run = pandoc.Inlines({}) end
  end
  for _, x in ipairs(el.content) do
    if x.t == "Link" or has_link({ x }) then
      flush()
      out:insert(x)
    else
      run:insert(x)
    end
  end
  flush()
  return out
end
