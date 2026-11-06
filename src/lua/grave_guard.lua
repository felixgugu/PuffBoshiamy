-- Swallow a backtick typed in the middle of a composition.
--
-- The recognizer pattern ^`... only matches when the backtick is the FIRST
-- key.  Without this guard, a later backtick would reach express_editor's
-- DirectCommit and commit the current composition unexpectedly.
--
-- Return values: 0 = kRejected, 1 = kAccepted, 2 = kNoop.

local function processor(key, env)
  if key:release() then
    return 2
  end
  if key.keycode ~= 0x60 then
    return 2
  end
  local ctx = env.engine.context
  if ctx:is_composing() then
    -- Two backticks in a row: the first one only opened the Zhuyin
    -- composition, so turn the pair into two literal backticks.
    if ctx.input == "`" then
      env.engine:commit_text("``")
      ctx:clear()
    end
    return 1
  end
  return 2
end

return processor
