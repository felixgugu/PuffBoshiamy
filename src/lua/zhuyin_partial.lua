-- Placeholder candidate for an incomplete Zhuyin syllable.
--
-- A bare initial such as 1 (ㄅ) or q (ㄆ) cannot be a syllable on its own, so
-- the dictionary has no entry for it.  Rime then leaves the segment in the
-- kVoid state and preedit_format is not applied; typing ` + 1 displayed the
-- raw "1" instead of "ㄅ".
--
-- The zhuyin translator therefore enables completion, which makes an
-- incomplete code still produce candidates.  This filter removes those
-- completion candidates.  When an exact code exists the candidate list is
-- left exactly as before; otherwise a single placeholder is emitted so the
-- segment survives and its Bopomofo preedit is shown.  The placeholder is
-- not committable: zhuyin_digits.lua swallows Space/Enter while it is the
-- only candidate.

local BOPOMOFO = {
  ["1"] = "ㄅ", ["q"] = "ㄆ", ["a"] = "ㄇ", ["z"] = "ㄈ",
  ["2"] = "ㄉ", ["w"] = "ㄊ", ["s"] = "ㄋ", ["x"] = "ㄌ",
  ["e"] = "ㄍ", ["d"] = "ㄎ", ["c"] = "ㄏ",
  ["r"] = "ㄐ", ["f"] = "ㄑ", ["v"] = "ㄒ",
  ["5"] = "ㄓ", ["t"] = "ㄔ", ["g"] = "ㄕ", ["b"] = "ㄖ",
  ["y"] = "ㄗ", ["h"] = "ㄘ", ["n"] = "ㄙ",
  ["u"] = "ㄧ", ["j"] = "ㄨ", ["m"] = "ㄩ",
  ["8"] = "ㄚ", ["i"] = "ㄛ", ["k"] = "ㄜ", [","] = "ㄝ",
  ["9"] = "ㄞ", ["o"] = "ㄟ", ["l"] = "ㄠ", ["."] = "ㄡ",
  ["0"] = "ㄢ", ["p"] = "ㄣ", [";"] = "ㄤ", ["/"] = "ㄥ",
  ["-"] = "ㄦ",
  ["6"] = "ˊ", ["3"] = "ˇ", ["4"] = "ˋ", ["7"] = "˙",
}

local function to_bopomofo(code)
  return (code:gsub(".", BOPOMOFO))
end

local function filter(input, env)
  local ctx = env.engine.context
  local seg = ctx.composition:back()
  if not seg or not seg:has_tag("zhuyin") then
    for cand in input:iter() do
      yield(cand)
    end
    return
  end

  -- Completion candidates are only used to keep an incomplete syllable alive.
  -- Exact table candidates come first, so stop at the first completion.
  local saw_exact = false
  for cand in input:iter() do
    if cand.type == "completion" then
      break
    end
    saw_exact = true
    yield(cand)
  end

  if not saw_exact then
    local code = ctx.input:sub(seg.start + 1, seg._end)
    local symbols = to_bopomofo(code)
    local cand = Candidate("zhuyin_partial", seg.start, seg._end,
                           symbols, "")
    cand.preedit = symbols
    yield(cand)
  end
end

return filter
