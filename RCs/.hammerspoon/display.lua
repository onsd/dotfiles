-- 外部ディスプレイ接続時の自動レイアウト
--   - 外部ディスプレイ: HiDPI (@2x) で一番広いモード (無ければ全モードで最大)。名前別の固定も可
--   - 配置: 外部ディスプレイの真下 (左右中央揃え) に内蔵ディスプレイ
-- 接続時に自動適用。手動再適用は ⌃⌘D。

local M = {}

-- 内蔵ディスプレイ判定 (英語 / 日本語ロケール両対応)
local function isBuiltin(s)
  local name = s:name() or ""
  return name:match("Built%-in") ~= nil or name:match("内蔵") ~= nil
end

-- ディスプレイ名ごとの固定モード (availableModes のキー形式)。自動選択が合わないときだけ書く
--   例: ["LG HDR WQHD+"] = "3008x1269@2x 60Hz 8bpp"
M.overrides = {
  ["ZQE-CBA"] = "3440x1440@1x 100Hz 8bpp",   -- ウルトラワイド (HiDPI が無いので 3440x1440 に固定)
}

-- HiDPI (@2x) の中で面積が最大のモード。同面積なら高リフレッシュレートを優先。
-- HiDPI が 1 つも無いディスプレイは全モードから選ぶ
local function bestMode(s)
  local modes = s:availableModes()
  local fixed = M.overrides[s:name()]
  if fixed and modes[fixed] then return modes[fixed] end

  local hidpi = false
  for _, m in pairs(modes) do
    if m.scale >= 2 then hidpi = true break end
  end

  local best
  for _, m in pairs(modes) do
    if hidpi and m.scale < 2 then
      -- HiDPI がある場合は @1x を候補にしない (文字が小さくなりすぎる)
    elseif not best then
      best = m
    else
      local a, b = m.w * m.h, best.w * best.h
      if a > b
         or (a == b and m.scale > best.scale)
         or (a == b and m.scale == best.scale and m.freq > best.freq) then
        best = m
      end
    end
  end
  return best
end

-- 内蔵を外部の真下に置く。座標はメインディスプレイ基準なので、メインでない側を動かす
local function arrange(builtin, ext)
  local bf, ef = builtin:fullFrame(), ext:fullFrame()
  if builtin == hs.screen.primaryScreen() then
    ext:setOrigin(math.floor((bf.w - ef.w) / 2), -ef.h)
  else
    builtin:setOrigin(ef.x + math.floor((ef.w - bf.w) / 2), ef.y + ef.h)
  end
end

function M.apply()
  local builtin, ext
  for _, s in ipairs(hs.screen.allScreens()) do
    if isBuiltin(s) then builtin = s elseif not ext then ext = s end
  end
  if not builtin or not ext then return end

  local m, cur = bestMode(ext), ext:currentMode()
  if m and (cur.w ~= m.w or cur.h ~= m.h or cur.scale ~= m.scale or cur.freq ~= m.freq) then
    ext:setMode(m.w, m.h, m.scale, m.freq, m.depth)
  end

  -- 解像度変更がフレームに反映されてから配置する (反映前だと旧サイズで位置計算してしまう)。
  -- setMode 前に取った screen オブジェクトは frame が古いまま更新されないので、UUID で取り直す
  local bid, eid = builtin:getUUID(), ext:getUUID()
  local deadline = hs.timer.secondsSinceEpoch() + 5
  M.pending = hs.timer.waitUntil(function()
    local s = hs.screen.find(eid)
    local f = s and s:fullFrame()
    return (f and f.w == m.w and f.h == m.h) or hs.timer.secondsSinceEpoch() > deadline
  end, function()
    -- 反映直後は macOS 側の再配置と競合することがあるので一拍置く
    hs.timer.doAfter(0.5, function()
      builtin, ext = hs.screen.find(bid), hs.screen.find(eid)
      if not builtin or not ext then return end
      arrange(builtin, ext)
      local nm = ext:currentMode()
      hs.alert.show(string.format("Display: %s %dx%d@%gx / 内蔵を下に配置", ext:name(), nm.w, nm.h, nm.scale))
    end)
  end, 0.2)
end

-- 接続構成 (UUID の集合) が変わった時だけ適用する。
-- 自分の setMode / setOrigin でも watcher が発火するため、構成キーで無限ループを防ぐ
local function screensKey()
  local ids = {}
  for _, s in ipairs(hs.screen.allScreens()) do table.insert(ids, s:getUUID()) end
  table.sort(ids)
  return table.concat(ids, ",")
end

local lastKey = screensKey()

M.watcher = hs.screen.watcher.new(function()
  local key = screensKey()
  if key == lastKey then return end
  lastKey = key
  -- 接続直後は availableModes が揃っていないことがあるので少し待つ
  hs.timer.doAfter(2, M.apply)
end):start()

hs.hotkey.bind({"ctrl", "cmd"}, "d", M.apply)

return M
