-- Three-state symbol shape, cycled with Shift+Space.
--
-- States (using the built-in Rime options so punctuator follows too):
--   half:    ascii_punct=1, full_shape=0
--   natural: ascii_punct=0, full_shape=0
--   full:    ascii_punct=0, full_shape=1
--
-- Cycle order: half -> natural -> full -> half.
-- Return values: 0 = kRejected, 1 = kAccepted, 2 = kNoop.

local NEXT = {
  half = "natural",
  natural = "full",
  full = "half",
}

local function current_state(ctx)
  if ctx:get_option("full_shape") then
    return "full"
  end
  if ctx:get_option("ascii_punct") then
    return "half"
  end
  return "natural"
end

local function set_state(ctx, state)
  ctx:set_option("full_shape", state == "full")
  ctx:set_option("ascii_punct", state == "half")
end

local function processor(key, env)
  if key:release() then
    return 2
  end

  local ctx = env.engine.context

  -- In half mode ascii_punct makes the punctuator pass '/' straight through,
  -- which would otherwise prevent the /X symbol menu from starting.  Push
  -- the slash into the input so the recognizer can still match /jt etc.
  if key.keycode == 0x2F and not key:shift() and not key:ctrl() and not key:alt() then
    if not ctx:is_composing() and not ctx:get_option("ascii_mode")
        and ctx:get_option("ascii_punct") then
      ctx:push_input("/")
      return 1
    end
  end

  if key.keycode ~= 0x20 or not key:shift() then
    return 2
  end
  if key:ctrl() or key:alt() then
    return 2
  end

  if ctx:get_option("ascii_mode") then
    return 2  -- let Shift+Space pass through in ASCII mode
  end

  set_state(ctx, NEXT[current_state(ctx)])
  return 1  -- swallow Shift+Space
end

return processor
