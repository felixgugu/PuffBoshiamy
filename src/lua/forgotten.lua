-- Forgotten boshiamy codes.
--
-- Records every character committed from a Zhuyin composition into
-- <rime-user-dir>/puffime_forgotten.tsv:
--
--     char <TAB> short <TAB> full <TAB> count <TAB> last-epoch
--
-- The `,,f` affix segment uses this module as a lua_translator:
--   ,,fk -> full history, newest first
--   ,,fl -> only the most recent Zhuyin commit
-- Selecting a candidate commits the character; short/full codes are shown
-- as a comment.

local hints = require("boshiamy_hints")

local M = {}

-- Characters from the most recent Zhuyin commit.  Used by ,,fl.
M.last_commit = nil

-- Copy the old PuffBoshiamy history once, so renaming the project does not
-- lose the user's ,,fk / ,,fl data.
local function migrate_legacy(dir)
  local new_path = dir .. "\\puffime_forgotten.tsv"
  local new_file = io.open(new_path, "r")
  if new_file then
    new_file:close()
    return new_path
  end
  local old_path = dir .. "\\puffboshiamy_forgotten.tsv"
  local old_file = io.open(old_path, "rb")
  if not old_file then
    return new_path
  end
  local content = old_file:read("*a")
  old_file:close()
  local dst = io.open(new_path, "wb")
  if dst then
    dst:write(content)
    dst:close()
  end
  return new_path
end

local function data_path()
  -- Only the headless harness sets PUFF_HARNESS_USER_DIR.  The real IME
  -- must always use %APPDATA%\Rime, even if PUFF_RIME_USER_DIR leaked from
  -- a deployment/test script.
  local dir = os.getenv("PUFF_HARNESS_USER_DIR")
  if dir and dir ~= "" then
    local candidate = migrate_legacy(dir)
    local probe = io.open(candidate, "a")
    if probe then
      probe:close()
      return candidate
    end
  end
  dir = (os.getenv("APPDATA") or ".") .. "\\Rime"
  return migrate_legacy(dir)
end

local function load_entries()
  local entries = {}
  local f = io.open(data_path(), "r")
  if not f then
    return entries
  end
  for line in f:lines() do
    local char, short, full, count, last =
      line:match("^([^\t]+)\t([^\t]*)\t([^\t]*)\t(%d+)\t(%d+)$")
    if char then
      entries[char] = {
        char = char,
        short = short,
        full = full,
        count = tonumber(count) or 1,
        last = tonumber(last) or 0,
      }
    end
  end
  f:close()
  return entries
end

local function sorted_entries()
  local list = {}
  for _, e in pairs(load_entries()) do
    table.insert(list, e)
  end
  table.sort(list, function(a, b)
    if a.last ~= b.last then
      return a.last > b.last
    end
    if a.count ~= b.count then
      return a.count > b.count
    end
    return a.char < b.char
  end)
  return list
end

-- Fallback for ,,fl after an engine restart: the newest timestamp group in
-- the TSV.  Commits made in the same second are treated as one commit.
local function newest_group()
  local all = sorted_entries()
  if #all == 0 then
    return all
  end
  local newest = all[1].last
  local group = {}
  for _, e in ipairs(all) do
    if e.last ~= newest then
      break
    end
    table.insert(group, e)
  end
  return group
end

local function comment_for(e, with_count)
  local c
  if e.short ~= e.full then
    c = "簡: " .. e.short .. " / 拆: " .. e.full
  else
    c = "簡: " .. e.short
  end
  if with_count then
    c = c .. "  (" .. e.count .. ")"
  end
  return c
end

local function record(char, short, full)
  local entries = load_entries()
  local e = entries[char]
  if not e then
    e = { char = char, short = short, full = full, count = 0, last = 0 }
    entries[char] = e
  end
  e.short = short
  e.full = full
  e.count = e.count + 1
  e.last = os.time()

  local f = io.open(data_path(), "w")
  if not f then
    return
  end
  for _, v in pairs(entries) do
    f:write(v.char, "\t", v.short, "\t", v.full, "\t",
            tostring(v.count), "\t", tostring(v.last), "\n")
  end
  f:close()
end

function M.init(env)
  env.engine.context.commit_notifier:connect(function(ctx)
    local source = _G.PUFF_SOURCE
    _G.PUFF_SOURCE = nil
    if source ~= "zhuyin" then
      return
    end
    local text = ctx:get_commit_text()
    if not text or text == "" then
      return
    end
    local last = {}
    for _, cp in utf8.codes(text) do
      local ch = utf8.char(cp)
      local h = hints[ch]
      if h then
        record(ch, h.short, h.full)
        table.insert(last, { char = ch, short = h.short, full = h.full })
      end
    end
    if #last > 0 then
      M.last_commit = last
    end
  end)
end

function M.func(input, seg, env)
  if not seg:has_tag("forgotten") then
    return
  end

  -- ,,fk -> full history; ,,fl -> only the most recent commit.
  local only_last = (input == "l" or input == ",,fl")
  local list
  local with_count
  if only_last then
    list = M.last_commit
    with_count = false
    if not list or #list == 0 then
      list = newest_group()
    end
  else
    list = sorted_entries()
    with_count = true
  end

  if #list == 0 then
    yield(Candidate("forgotten", seg.start, seg._end,
                    "（尚無忘記紀錄）", "先用注音上屏一些字"))
    return
  end
  local limit = math.min(#list, 100)
  for i = 1, limit do
    local e = list[i]
    yield(Candidate("forgotten", seg.start, seg._end, e.char,
                    comment_for(e, with_count)))
  end
end

return M
