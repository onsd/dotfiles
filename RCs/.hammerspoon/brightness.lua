-- 外部ディスプレイの明るさを ⌘ + 照度キー (F1/F2) で上げ下げする
--   Apple Silicon では hs.screen:setBrightness が外部ディスプレイに効かないので、
--   DDC/CI を m1ddc (brew install m1ddc) 経由で叩く。
--   ⌘ 無しの照度キーは従来どおり内蔵ディスプレイに効く。

local M = {}

M.m1ddc = "/opt/homebrew/bin/m1ddc"
M.step = 10   -- 1 回の押下で変える量 (0-100)

-- m1ddc の display 番号 → 現在の明るさ。
-- DDC の読み値はたまにブレる (max 超えの値が返る) ので、初回だけ読んで以降は手元で保持する
local cache = {}

-- `m1ddc display list` の "[2] DELL S2722QC (UUID)" から名前付きの外部ディスプレイ番号を拾う
local function displays()
  local out = hs.execute(M.m1ddc .. " display list") or ""
  local list = {}
  for idx, name in out:gmatch("%[(%d+)%]%s+([^\n]-)%s+%(") do
    if name ~= "(null)" then table.insert(list, { idx = idx, name = name }) end
  end
  return list
end

local function read(idx)
  for _ = 1, 3 do
    local v = tonumber((hs.execute(M.m1ddc .. " display " .. idx .. " get luminance")))
    if v and v >= 0 and v <= 100 then return v end
  end
  return 50
end

-- キー長押しのリピートで DDC 書き込みが詰まらないよう、最後の値だけ少し遅らせて書く
local pending
local function flush()
  for idx, v in pairs(cache) do
    hs.task.new(M.m1ddc, nil, { "display", idx, "set", "luminance", tostring(v) }):start()
  end
end

local function change(delta)
  local list = displays()
  if #list == 0 then
    hs.alert.closeAll()
    hs.alert.show("外部ディスプレイ (DDC) が見つかりません")
    return
  end
  local shown = {}
  for _, d in ipairs(list) do
    local v = cache[d.idx] or read(d.idx)
    v = math.max(0, math.min(100, v + delta))
    cache[d.idx] = v
    table.insert(shown, string.format("%s %d%%", d.name, v))
  end
  hs.alert.closeAll()
  hs.alert.show("☀ " .. table.concat(shown, " / "), 0.8)
  if pending then pending:stop() end
  pending = hs.timer.doAfter(0.15, flush)
end

-- 照度キーは通常キーではなく systemDefined イベントで来るので hs.hotkey では拾えない
M.tap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(e)
  local k = e:systemKey()
  if k.key ~= "BRIGHTNESS_UP" and k.key ~= "BRIGHTNESS_DOWN" then return false end
  if not e:getFlags().cmd then return false end
  if k.down then change(k.key == "BRIGHTNESS_UP" and M.step or -M.step) end
  return true   -- ⌘ 付きは内蔵ディスプレイに渡さない (down / up とも握りつぶす)
end):start()

-- eventtap は処理が遅いと OS に無効化されることがあるので、定期的に生き返らせる
M.keepalive = hs.timer.doEvery(5, function()
  if not M.tap:isEnabled() then M.tap:start() end
end)

-- ディスプレイ構成が変わったら番号がずれうるので保持値を捨てる
M.watcher = hs.screen.watcher.new(function() cache = {} end):start()

return M
