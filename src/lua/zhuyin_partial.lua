-- Zhuyin completion filter.
--
-- An incomplete code such as 1 (ㄅ) or q (ㄆ) cannot be a syllable on its
-- own, so the dictionary has no exact entry for it.  Rime's completion is
-- enabled to keep the segment alive (otherwise preedit_format is not applied
-- and the raw "1" is displayed instead of "ㄅ").  The completion list itself
-- comes from lua_translator@zhuyin_completion, which is ordered by essay
-- frequency; librime's own completion candidates are dropped here because
-- their order is by remaining code length.
--
-- Candidates that are not built-in completion candidates (exact table
-- candidates plus zhuyin_completion candidates) pass through unchanged.
-- Only when nothing is left (e.g. `su3c or `ji2) is a single placeholder
-- emitted so the segment survives and its Bopomofo preedit is shown.  The
-- placeholder is not committable: zhuyin_digits.lua swallows Space/Enter
-- while it is the only candidate.

local bopomofo = require("zhuyin_bopomofo")

local function filter(input, env)
  local ctx = env.engine.context
  local seg = ctx.composition:back()
  if not seg or not seg:has_tag("zhuyin") then
    for cand in input:iter() do
      yield(cand)
    end
    return
  end

  local saw_candidate = false
  for cand in input:iter() do
    -- Built-in completion is only used to keep an incomplete code alive;
    -- zhuyin_completion.lua supplies the actual, frequency-ordered list.
    if cand.type ~= "completion" then
      saw_candidate = true
      yield(cand)
    end
  end

  if not saw_candidate then
    local code = ctx.input:sub(seg.start + 1, seg._end)
    local symbols = bopomofo.to_bopomofo(code)
    local cand = Candidate("zhuyin_partial", seg.start, seg._end,
                           symbols, "")
    cand.preedit = symbols
    yield(cand)
  end
end

return filter
