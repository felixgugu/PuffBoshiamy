-- Symbol-shape filter for the Boshiamy segment.
--
-- The CIN table stores many symbols as full-width characters.  Depending on
-- the symbol_shape state (driven by full_shape/ascii_punct), rewrite
-- single-character symbol candidates:
--
--   half:    ASCII punctuation/symbols (， -> , ; ＄ -> $)
--   natural: Chinese punctuation/brackets full, ASCII symbols half
--            (， stays ，; ＄ -> $; 「 stays 「)
--   full:    leave the table as-is
--
-- Rewrite known symbol candidates in the Boshiamy segment.  Chinese
-- characters, custom phrases not in the map, the English raw candidate and
-- the /X symbol menu are left alone.

local NATURAL = {
  -- full-width ASCII symbols -> half-width
  ["＄"] = "$", ["＠"] = "@", ["＃"] = "#", ["％"] = "%", ["＆"] = "&",
  ["＝"] = "=", ["＋"] = "+", ["－"] = "-", ["＊"] = "*", ["／"] = "/",
  ["＼"] = "\\", ["＿"] = "_", ["～"] = "~", ["＾"] = "^", ["｜"] = "|",
  ["＜"] = "<", ["＞"] = ">", ["［"] = "[", ["］"] = "]", ["｛"] = "{",
  ["｝"] = "}", ["．"] = ".", ["　"] = " ",
  -- full-width currency -> half-width
  ["￥"] = "¥", ["￡"] = "£", ["￠"] = "¢",
  -- full-width quote forms
  ["＇"] = "'", ["＂"] = "\"",
}

local HALF = {
  -- Chinese punctuation / brackets -> ASCII
  ["，"] = ",", ["。"] = ".", ["、"] = ",", ["；"] = ";", ["："] = ":",
  ["！"] = "!", ["？"] = "?", ["（"] = "(", ["）"] = ")",
  ["『"] = "[", ["』"] = "]",
  ["【"] = "[", ["】"] = "]", ["〔"] = "[", ["〕"] = "]",
  ["《"] = "<", ["》"] = ">", ["〈"] = "<", ["〉"] = ">",
  ["…"] = "...", ["……"] = "...", ["—"] = "-", ["——"] = "-", ["–"] = "-",
  ["‘"] = "'", ["’"] = "'", ["“"] = "\"", ["”"] = "\"",
  ["〝"] = "\"", ["〞"] = "\"",
  -- small-form variants that appear in some symbol codes
  ["﹩"] = "$", ["﹠"] = "&", ["﹡"] = "*", ["﹦"] = "=", ["﹢"] = "+",
  ["﹪"] = "%", ["﹟"] = "#", ["﹫"] = "@", ["﹨"] = "\\", ["／"] = "/",
}
for k, v in pairs(NATURAL) do
  HALF[k] = v
end

local function map_for(ctx)
  if ctx:get_option("full_shape") then
    return nil
  end
  if ctx:get_option("ascii_punct") then
    return HALF
  end
  return NATURAL
end

local function filter(input, env)
  local ctx = env.engine.context
  local seg = ctx.composition:back()
  if not seg or not seg:has_tag("abc") then
    for cand in input:iter() do
      yield(cand)
    end
    return
  end

  local map = map_for(ctx)
  for cand in input:iter() do
    local text = cand.text
    if map and text and map[text] then
      local c = Candidate(cand.type, seg.start, seg._end, map[text], cand.comment)
      if cand.quality ~= nil then
        c.quality = cand.quality
      end
      if cand.preedit and cand.preedit ~= "" then
        c.preedit = cand.preedit
      end
      yield(c)
    else
      yield(cand)
    end
  end
end

return filter
