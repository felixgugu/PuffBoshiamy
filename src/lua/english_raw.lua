-- Raw English candidate for the boshiamy segment.
--
-- The candidate is the current input text, shown as an extra candidate at
-- the very end of the list.  This gives short English words (the, he, was,
-- out, ...) a selectable candidate even when the same letters are also a
-- valid boshiamy code.  Enter commits the raw input directly (express_editor).
--
-- Spaces are part of the raw input while typing a sentence: boshiamy_space
-- pushes them into the buffer when no Chinese candidate remains, so the
-- preedit shows "hello world" and Enter commits the whole string.  The raw
-- candidate mirrors the input (including its spaces).
--
-- Only plain lowercase letters/apostrophes/spaces are echoed; punctuation-heavy
-- boshiamy symbol codes do not get an English candidate.

local function translator(input, seg, env)
  if not seg:has_tag("abc") then
    return
  end
  if input == "" then
    return
  end
  if not input:match("^[a-z][a-z' ]*$") then
    return
  end
  local cand = Candidate("raw", seg.start, seg._end, input, "英")
  cand.quality = -1000000
  yield(cand)
end

return translator
