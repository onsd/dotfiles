# .hammerspoon

## display.lua: 外部ディスプレイの自動レイアウト

外部ディスプレイをつなぐと、解像度と配置を自動で揃える。

- **解像度**: HiDPI (@2x) のモードで一番広いものにする。同じ広さならリフレッシュレートが高い方。
  HiDPI のモードが無いディスプレイだけは、全モードで一番広いものにする。
  - 例: DELL S2722QC (27" 4K) は `3360x1890@2x 60Hz`
  - @1x は選ばない。4K の @1x (3840x2160) だと文字が小さすぎるため
- **配置**: 外部ディスプレイを上、Laptop (内蔵ディスプレイ) をその真下に置く。左右は中央揃え
- **タイミング**: ディスプレイの抜き差しで自動実行。`⌃⌘D` で手動実行もできる
  - スクリプト自身の解像度・配置変更でも watcher が発火するので、
    接続しているディスプレイの組み合わせ (UUID の集合) が変わったときだけ動く
- 外部ディスプレイが複数あるときは、最初に見つかった 1 台だけを対象にする

`init.lua` から `displayLayout = require("display")` で読み込んでいる。

### モードを固定する

自動で選ばれた解像度が合わないディスプレイは、名前ごとにモードを固定できる。

1. 外部ディスプレイをつないだ状態で、HiDPI の候補を広い順に出す

   ```sh
   hs -c 'for _,s in ipairs(hs.screen.allScreens()) do if not s:name():match("Built%-in") then print(s:name()) local t={} for k,m in pairs(s:availableModes()) do if m.scale>=2 then table.insert(t,{k=k,a=m.w*m.h,f=m.freq}) end end table.sort(t,function(a,b) if a.a~=b.a then return a.a>b.a end return a.f>b.f end) for _,x in ipairs(t) do print("  "..x.k) end end end'
   ```

   1 行目がディスプレイ名、その下がモードの一覧 (`3360x1890@2x 60Hz 8bpp` の形式)。

2. 試したいモードに一時的に切り替えて、文字の大きさを確かめる (幅, 高さ, scale, Hz, bpp)

   ```sh
   hs -c 'hs.screen.find("<ディスプレイ名>"):setMode(3008, 1692, 2, 60, 8)'
   ```

   配置がずれたら `⌃⌘D` で直る (ただし自動選択のモードに戻る)。

3. 決めたモードを `display.lua` の `M.overrides` に書く。キーはディスプレイ名、値は一覧の表記そのまま

   ```lua
   M.overrides = {
     ["LG HDR WQHD+"] = "3008x1269@2x 60Hz 8bpp",
   }
   ```

4. `⌃⌘R` で設定をリロードし、`⌃⌘D` で適用する

値が一覧に無い (表記違いなど) ときは無視され、自動選択になる。
