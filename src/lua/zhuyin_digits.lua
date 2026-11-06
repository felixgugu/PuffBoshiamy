-- Zhuyin digit / space routing.
--
-- In the zhuyin segment digits are normally input (ㄅ=1, ㄉ=2, ...).  A
-- digit only selects a candidate when the current code already ends with an
-- explicit tone (3/4/6/7); otherwise it is needed to finish the syllable
-- (e.g. `wu` + 0 = ㄊㄧㄢ).
--
--   * input ends with tone 3/4/6/7 + plain digit -> highlight candidate
--   * Shift+digit (any time a menu is open)     -> highlight candidate
--   * input does NOT end with a tone + plain digit -> input
--   * menu open + space -> express_editor confirms the highlighted candidate
--   * no menu + space -> swallow (do not commit raw invalid zhuyin)
--   * menu open + Return -> replay space (commit the highlighted candidate)
--   * no menu + Return -> swallow (do not commit raw `w8 text)
--
-- Candidate selection only highlights; it does NOT commit.  The user presses
-- space to commit.  This applies to both plain digits and Shift+digits in the
-- zhuyin segment.  (Boshiamy digits still use the normal selector, which
-- commits immediately.)
--
-- Consequence: to start a new syllable with a digit after a toned syllable,
-- press space first (which commits the highlighted candidate).

local SHIFT_DIGIT = {
  ["!"] = "1", ["@"] = "2", ["#"] = "3", ["$"] = "4", ["%"] = "5",
  ["^"] = "6", ["&"] = "7", ["*"] = "8", ["("] = "9", [")"] = "0",
}

local function is_zhuyin(ctx)
  if not ctx:is_composing() then
    return false
  end
  local input = ctx.input
  return input ~= "" and input:sub(1, 1) == "`"
end

local function digit_from_key(key)
  local ch = key.keycode
  if ch >= 0x30 and ch <= 0x39 then
    return string.char(ch)
  end
  if ch < 1 or ch > 255 then
    return nil
  end
  return SHIFT_DIGIT[string.char(ch)]
end

local function select_candidate(ctx, env, digit)
  local seg = ctx.composition:back()
  if not seg or not seg.menu then
    return false
  end
  local n = tonumber(digit)
  if n == 0 then
    n = 10
  end
  local page_size = env.engine.schema.page_size
  if not page_size or page_size <= 0 then
    page_size = 9
  end
  local page_start = math.floor(seg.selected_index / page_size) * page_size
  local target = page_start + n - 1
  local current = seg.selected_index
  local delta = target - current
  if delta == 0 then
    return true
  end
  -- The bundled librime-lua has neither ctx:highlight() nor a functional
  -- Segment.selected_index setter.  Move the highlight with Tab/Shift+Tab;
  -- the selector changes selected_index without confirming the segment.
  local key_name = delta > 0 and "Tab" or "Shift+Tab"
  for _ = 1, math.abs(delta) do
    env.engine:process_key(KeyEvent(key_name))
    local now = ctx.composition:back()
    if not now or now.selected_index == current then
      break
    end
    current = now.selected_index
  end
  return true
end

local function processor(key, env)
  if key:release() then
    return 2  -- kNoop: never treat a key release as a second press
  end
  local ctx = env.engine.context
  local ch = key.keycode

  if not is_zhuyin(ctx) then
    return 2  -- kNoop
  end

  if ch == 0x20 then  -- space
    if key:shift() or key:ctrl() or key:alt() then
      return 2  -- Shift+Space cycles symbol shape; let symbol_shape handle it
    end
    if ctx:has_menu() then
      return 2  -- let express_editor commit the highlighted candidate
    end
    return 1  -- swallow: do not commit invalid zhuyin as raw text
  end

  if ch == 0xFF0D or ch == 0xFF8D then  -- Return / KP_Enter
    if ctx:has_menu() then
      -- Replay Space so express_editor commits the highlighted candidate
      -- exactly like the space key (same commit path/notifier).
      env.engine:process_key(KeyEvent("space"))
    end
    return 1  -- swallow: never commit the raw `w8 text
  end

  local digit = digit_from_key(key)
  if not digit then
    return 2
  end
  if not ctx:has_menu() then
    return 2  -- no candidate yet: let the digit be zhuyin input
  end

  if not key:shift() then
    local input = ctx.input
    if not input:match("[3467]$") then
      return 2  -- syllable not toned yet: plain digit is input
    end
  end

  select_candidate(ctx, env, digit)
  return 1  -- kAccepted
end

return processor
