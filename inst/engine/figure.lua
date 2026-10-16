-- docdesigner: figure frames (figure.style: ruled | inset).
--
-- Wraps the image in each figure -- not the caption -- in \ddfigstart ...
-- \ddfigend, which the engine preamble defines for the style. Two simpler
-- routes fail. A hook on the figure environment puts the float itself inside
-- the frame, which LaTeX rejects. Extra blocks in the figure make pandoc set
-- each block in a minipage of its own, splitting the frame's begin from its
-- end. So the frame goes inline, around the image, inside the figure's one
-- block. A figure of several blocks (subfigures) is left unframed.

function Figure(fig)
  if #fig.content ~= 1 then return nil end
  local b = fig.content[1]
  if b.t ~= "Plain" and b.t ~= "Para" then return nil end
  b.content:insert(1, pandoc.RawInline("latex", "\\ddfigstart "))
  b.content:insert(pandoc.RawInline("latex", "\\ddfigend "))
  return fig
end
