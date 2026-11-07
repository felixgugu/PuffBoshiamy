-- Boshiamy / English input routing (space and digits).
--
-- english_raw.lua adds an English (raw) candidate for every plain-letter
-- input, so an invalid Boshiamy code still has a menu.
--
-- Space routing:
--   * English-only input -> push a literal space into the buffer; it stays in
--     the preedit and Enter commits the whole sentence ("hello world").
--   * A real (non-raw) Chinese candidate exists -> kNoop, so express_editor
--     commits the highlighted candidate.
--   * Any other invalid code -> kAccepted, swallowing the space so the user
--     can Backspace and fix the code (no raw commit).
--
-- Digit routing:
--   * English-only input -> push the digit into the buffer instead of letting
--     the selector commit candidate #1.  "hello123" + Enter commits the whole
--     string.  Digits are not in speller/alphabet, so the raw tail becomes a
--     separate "raw" segment; preedit and commit still include it.
--   * Otherwise -> kNoop, so the normal selector selects candidates.
--
-- speller/delimiter is " " in the schema, so abc_segmentor keeps a pushed
-- space inside the abc segment; otherwise the space would be dropped from the
-- committed text.  use_space stays false: space only enters the input here.
--
-- Return values: 0 = kRejected, 1 = kAccepted, 2 = kNoop.

local function is_boshiamy(ctx)
  if not ctx:is_composing() then
    return false
  end
  local seg = ctx.composition:back()
  return seg ~= nil and seg:has_tag("abc")
end

local function has_chinese_candidate(ctx)
  local seg = ctx.composition:back()
  if not seg or not seg.menu then
    return false
  end
  if seg.menu:prepare(1) < 1 then
    return false
  end
  local cand = seg:get_candidate_at(0)
  return cand ~= nil and cand.type ~= "raw"
end

-- True while the composition is just raw English.  Lowercase letters, digits,
-- apostrophes and spaces are allowed.  When the menu exists, the first
-- candidate must be the English raw candidate; once a digit has been pushed,
-- the tail is a "raw" segment without a menu, which still counts as English.
local function is_english_mode(ctx)
  local input = ctx.input
  if input == "" or not input:match("^[a-z][a-z0-9' ]*$") then
    return false
  end
  local seg = ctx.composition:back()
  if seg and seg.menu and seg.menu:prepare(1) >= 1 then
    local cand = seg:get_candidate_at(0)
    return cand ~= nil and cand.type == "raw"
  end
  return true
end

local function processor(key, env)
  if key:release() then
    return 2
  end
  -- Shift+Space is the symbol-shape cycle; Shift+digits are candidate
  -- selection via key_binder.  Do not handle either here.
  if key:shift() or key:ctrl() or key:alt() then
    return 2
  end

  local ctx = env.engine.context
  local ch = key.keycode

  if ch == 0x20 then  -- space
    if not ctx:is_composing() then
      return 2
    end
    if is_english_mode(ctx) then
      -- Continuous English: keep the space in the buffer; Enter commits the
      -- whole sentence.  Consecutive spaces are allowed.
      ctx:push_input(" ")
      return 1
    end
    if is_boshiamy(ctx) then
      if has_chinese_candidate(ctx) then
        return 2  -- let express_editor commit the highlighted candidate
      end
      return 1  -- swallow: keep the invalid code for Backspace/Enter
    end
    return 2
  end

  if ch >= 0x30 and ch <= 0x39 then  -- digits 0-9
    if is_english_mode(ctx) then
      ctx:push_input(string.char(ch))
      return 1
    end
  end

  return 2
end

return processor
