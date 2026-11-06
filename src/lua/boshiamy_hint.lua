-- Candidate comments: boshiamy short/full codes.
--
-- Boshiamy segment:  candidate <shortest code>  (only when the typed
--                    code is not already the shortest).  Prefix-completion
--                    candidates already carry their matching code.
-- Zhuyin segment:    no inline code comment.  Use ,,fl (last commit) or
--                    ,,fk (full history) to look up the codes after
--                    committing.
--
-- Also records which input method produced the current menu, so the commit
-- notifier in forgotten.lua only logs commits that came from Zhuyin.

local hints = require("boshiamy_hints")

local function filter(input, env)
  local ctx = env.engine.context
  local seg = ctx.composition:back()
  local is_zhuyin = seg and seg:has_tag("zhuyin")
  local is_forgotten = seg and seg:has_tag("forgotten")

  if is_zhuyin then
    _G.PUFF_SOURCE = "zhuyin"
  elseif is_forgotten then
    _G.PUFF_SOURCE = nil
  else
    _G.PUFF_SOURCE = "boshiamy"
  end

  local typed = ctx.input
  for cand in input:iter() do
    -- Inline code hints are only for the Boshiamy segment.  Zhuyin
    -- candidates stay narrow; use ,,fl / ,,fk to look up codes after
    -- committing.
    -- boshiamy_completion.lua already sets the completion code hint; only
    -- exact table candidates need the global shortest-code hint here.
    if not is_forgotten and not is_zhuyin and cand.type ~= "raw"
        and cand.type ~= "completion" then
      local h = hints[cand.text]
      if h and h.short ~= typed then
        local c = cand.comment or ""
        if c ~= "" then
          c = c .. "  "
        end
        cand.comment = c .. h.short
      end
    end
    yield(cand)
  end
end

return filter
