-- Boshiamy "v" select-second shortcut.
--
-- After a boshiamy code that has candidates, pressing v selects the second
-- candidate and commits it, but only when code.."v" is not a prefix of any
-- boshiamy code.  If code.."v" is a valid code/prefix, v is passed to the
-- speller as a normal code character.
--
-- Examples (official CIN table):
--   ak   -> 駐(1), 鐵(2); akv is not a prefix -> v commits 鐵
--   a    -> 對; av is a code (族) -> v inputs (av)
--   v    -> 要 (no menu; normal input)
--
-- Return values: 0 = kRejected, 1 = kAccepted, 2 = kNoop.

local prefixes = require("boshiamy_prefixes")

local function processor(key, env)
  if key:release() then
    return 2
  end
  if key.keycode ~= 0x76 or key:shift() then  -- 'v'
    return 2
  end

  local ctx = env.engine.context
  if not ctx:is_composing() then
    return 2
  end
  local seg = ctx.composition:back()
  if not seg or not seg:has_tag("abc") or not seg.menu then
    return 2
  end
  if not ctx:has_menu() then
    return 2
  end

  local input = ctx.input
  if input == "" then
    return 2
  end
  if prefixes[input .. "v"] then
    return 2  -- v is part of a valid code/prefix
  end

  local page_size = env.engine.schema.page_size
  if not page_size or page_size <= 0 then
    page_size = 9
  end
  local page_start = math.floor(seg.selected_index / page_size) * page_size
  local index = page_start + 1
  if seg.menu:prepare(index + 1) < index + 1 then
    return 2  -- no second candidate on this page
  end

  -- Commit directly instead of ctx:select()+confirm().  The v shortcut must
  -- not feed the user dictionary, otherwise the selected second candidate is
  -- promoted and the next v selects a different character.
  local cand = seg:get_candidate_at(index)
  if cand then
    env.engine:commit_text(cand.text)
    ctx:clear()
    return 1
  end
  return 2
end

return processor
