-- Android/Trime keyboard keys for PuffIME.
--
-- F12 is the "注音" key on the default keyboard:
--   * leave any pending Boshiamy composition,
--   * switch to Chinese mode and hide the half-shape punctuation flag
--     (Trime only draws a keyboard key's Bopomofo `label` when neither
--     ASCII mode nor ASCII punctuation is active),
--   * select Trime's built-in Bopomofo (ㄅㄆㄇ) keyboard through the
--     `_keyboard_bopomofo` runtime option,
--   * start the normal backtick Zhuyin composition.
--
-- When the Zhuyin composition is committed (space, Enter or a candidate
-- click), the keyboard switches back to the default Boshiamy QWERTY
-- keyboard and the previous punctuation shape is restored.
--
-- F11 is the "嘸蝦米" key on the Bopomofo keyboard: it cancels the
-- Zhuyin composition and switches back without committing.
--
-- Return values: 0 = kRejected, 1 = kAccepted, 2 = kNoop.

local F12 = 0xFFC9
local F11 = 0xFFC8

-- Punctuation shape before entering the Bopomofo keyboard, so leaving it
-- restores the user's half/natural/full setting.
local saved_ascii_punct = nil

-- True between pressing the Zhuyin key and committing/leaving Zhuyin.
local zhuyin_active = false

-- Connection to Rime's commit notifier; connected on the first use.
local commit_connection = nil

local function leave_zhuyin(ctx)
  zhuyin_active = false
  if saved_ascii_punct ~= nil then
    ctx:set_option("ascii_punct", saved_ascii_punct)
    saved_ascii_punct = nil
  end
  ctx:set_option("_keyboard_default", true)
end

-- Runs after Rime commits text (space/Enter/candidate click).
local function on_commit(ctx)
  if zhuyin_active then
    leave_zhuyin(ctx)
  end
end

local function ensure_commit_notifier(ctx)
  if commit_connection ~= nil then
    return
  end
  local ok, connection = pcall(function()
    return ctx.commit_notifier:connect(on_commit)
  end)
  if ok then
    commit_connection = connection
  end
end

local function processor(key, env)
  if key:release() then
    return 2
  end

  local ctx = env.engine.context

  if key.keycode == F12 then
    ensure_commit_notifier(ctx)
    if ctx:is_composing() then
      ctx:clear()
    end
    if saved_ascii_punct == nil then
      saved_ascii_punct = ctx:get_option("ascii_punct")
    end
    zhuyin_active = true
    ctx:set_option("ascii_mode", false)
    ctx:set_option("ascii_punct", false)
    ctx:set_option("_keyboard_bopomofo", true)
    env.engine:process_key(KeyEvent("`"))
    return 1
  end

  if key.keycode == F11 then
    if ctx:is_composing() then
      ctx:clear()
    end
    leave_zhuyin(ctx)
    return 1
  end

  return 2
end

return processor
