-- Boshiamy space routing.
--
-- english_raw.lua adds an English (raw) candidate for every plain-letter
-- input, so an invalid Boshiamy code still has a menu.  Without this guard
-- Space would commit that raw text as if it were a valid code.
--
-- Space is only allowed to fall through to express_editor when a real
-- (non-raw) Chinese candidate exists.  With no such candidate, Space is
-- swallowed so the user can Backspace and fix the code.  Enter is not
-- intercepted: express_editor's commit_raw_input still commits the raw text.
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

local function processor(key, env)
  if key:release() then
    return 2
  end
  -- Shift+Space is the symbol-shape cycle; do not treat it as a plain space.
  if key:shift() or key:ctrl() or key:alt() then
    return 2
  end
  if key.keycode ~= 0x20 then  -- space only
    return 2
  end

  local ctx = env.engine.context
  if not is_boshiamy(ctx) then
    return 2
  end

  if has_chinese_candidate(ctx) then
    return 2  -- let express_editor commit the highlighted candidate
  end
  return 1  -- swallow: keep the invalid code for Backspace/Enter
end

return processor
