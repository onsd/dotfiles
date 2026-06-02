-- AppGrid 互換のグリッド操作 + Rectangle 相当の分割配置 (Hammerspoon)
-- これ一つで AppGrid / Rectangle の両方を置き換える。

-- ターミナルから `hs -c '...'` で状態確認できるようにする
require("hs.ipc")

-- ===== グリッド設定 =====
-- '横マス数 x 縦マス数'。マスを増やすほど 1 コマの移動/伸縮が細かくなる。
hs.grid.setGrid('4x2')
hs.grid.setMargins({0, 0})
hs.window.animationDuration = 0   -- アニメ無しでキビキビ

local mash  = {"ctrl", "cmd"}          -- ⌃⌘  : AppGrid 系（グリッド操作）
local mash2 = {"ctrl", "alt", "cmd"}   -- ⌃⌥⌘ : Rectangle 系（分割配置）

-- ===== Electron (Chromium) アプリ対策 =====
-- Slack / VS Code / Discord 等は既定でウィンドウを AX (アクセシビリティ API) に
-- 公開しないため、hs.window がウィンドウを掴めず操作できない。
-- AXManualAccessibility を明示的に ON にして AX ツリーを公開させる。
local function enableAX(app)
  if not app then return end
  local ax = hs.axuielement.applicationElement(app)
  if ax then ax:setAttributeValue("AXManualAccessibility", true) end
end

-- 起動済みアプリすべてに適用（対象を絞らず全アプリに撒いておけば取りこぼさない）
for _, app in ipairs(hs.application.runningApplications()) do
  enableAX(app)
end

-- 後から起動 / フォーカスされたアプリにも自動適用
hs.application.watcher.new(function(_, event, app)
  if event == hs.application.watcher.launched
     or event == hs.application.watcher.activated then
    enableAX(app)
  end
end):start()

-- フォーカスウィンドウを安全に取得（無ければ何もしない / AppGrid のクラッシュ対策）
local function withWin(fn)
  return function()
    local w = hs.window.focusedWindow()
    if w then fn(w) end
  end
end
local function unit(rect) return withWin(function(w) w:moveToUnit(rect) end) end

-- 縦移動: 通常は 1 コマ移動。ただし縦幅いっぱいのときは縦を 1 コマ縮める
--   dir = -1 (上) / +1 (下)
local function moveVert(dir)
  return withWin(function(w)
    local g = hs.grid.getGrid(w:screen())   -- グリッド分割数 (g.w x g.h)
    local c = hs.grid.get(w)                 -- 現在のセル {x,y,w,h}
    if c.h >= g.h then
      -- 縦いっぱい → 1 コマ縮める（上なら上寄せ / 下なら下寄せ）
      hs.grid.set(w, { x = c.x, y = (dir < 0) and 0 or 1, w = c.w, h = g.h - 1 }, w:screen())
    elseif dir < 0 then
      hs.grid.pushWindowUp()
    else
      hs.grid.pushWindowDown()
    end
  end)
end

-- ============================================================
-- AppGrid 系: ⌃⌘
-- ============================================================
-- 移動（サイズ維持・1 コマ）
hs.hotkey.bind(mash, "h", hs.grid.pushWindowLeft)
hs.hotkey.bind(mash, "j", moveVert(1))
hs.hotkey.bind(mash, "k", moveVert(-1))
hs.hotkey.bind(mash, "l", hs.grid.pushWindowRight)
-- 伸縮（左端固定で右端を 1 コマ）
hs.hotkey.bind(mash, "o", hs.grid.resizeWindowWider)    -- 右に伸ばす
hs.hotkey.bind(mash, "i", hs.grid.resizeWindowThinner)  -- 縮める
-- 全画面
hs.hotkey.bind(mash, "m", hs.grid.maximizeWindow)
-- 縦の伸縮
hs.hotkey.bind(mash, "u", hs.grid.resizeWindowTaller)   -- 縦に伸ばす
hs.hotkey.bind(mash, "n", hs.grid.resizeWindowShorter)  -- 縦を縮める

-- ============================================================
-- Rectangle 系: ⌃⌥⌘
-- ============================================================
-- 半分割（矢印）
hs.hotkey.bind(mash2, "Left",  unit({0,   0,   0.5, 1  }))  -- 左半分
hs.hotkey.bind(mash2, "Right", unit({0.5, 0,   0.5, 1  }))  -- 右半分
hs.hotkey.bind(mash2, "Up",    unit({0,   0,   1,   0.5}))  -- 上半分
hs.hotkey.bind(mash2, "Down",  unit({0,   0.5, 1,   0.5}))  -- 下半分
-- 1/4（U I J K = 左上/右上/左下/右下）
hs.hotkey.bind(mash2, "u", unit({0,   0,   0.5, 0.5}))
hs.hotkey.bind(mash2, "i", unit({0.5, 0,   0.5, 0.5}))
hs.hotkey.bind(mash2, "j", unit({0,   0.5, 0.5, 0.5}))
hs.hotkey.bind(mash2, "k", unit({0.5, 0.5, 0.5, 0.5}))
-- サード（D F G = 左/中/右）
hs.hotkey.bind(mash2, "d", unit({0,     0, 1/3, 1}))
hs.hotkey.bind(mash2, "f", unit({1/3,   0, 1/3, 1}))
hs.hotkey.bind(mash2, "g", unit({2/3,   0, 1/3, 1}))
-- 2/3（E = 左 2/3 / T = 右 2/3）
hs.hotkey.bind(mash2, "e", unit({0,   0, 2/3, 1}))
hs.hotkey.bind(mash2, "t", unit({1/3, 0, 2/3, 1}))
-- 中央寄せ / 最大化
hs.hotkey.bind(mash2, "c", withWin(function(w) w:centerOnScreen() end))
hs.hotkey.bind(mash2, "Return", withWin(function(w) w:maximize() end))
-- 別ディスプレイへ移動
hs.hotkey.bind(mash2, "n", withWin(function(w) w:moveToScreen(w:screen():next()) end))

-- 設定リロード
hs.hotkey.bind(mash, "r", hs.reload)
hs.alert.show("Hammerspoon: AppGrid + Rectangle 互換設定をロード")
