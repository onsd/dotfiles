---
name: gh-ralph-loop
description: >-
  GitHub PR の CI 完了待ち、失敗チェック収集、未解決レビュー thread の観測を
  `gh` ベースで行い、Codex が修正を反復するためのスキル。Use when PR の CI や
  AI review コメントを見ながら、修正 -> push -> 再観測のループを回したいとき。
---

# GitHub Ralph Loop

GitHub PR の状態観測はシェルに寄せ、コメント解釈とコード修正は Codex に寄せる。

## 目的
- `gh pr checks --watch` で CI 完了を待つ
- required checks の失敗一覧を機械可読で取る
- review decision と未解決 thread を機械可読で取る
- その結果をもとに Codex が修正を入れて反復する

## 前提
- `gh auth status` が通ること
- `jq` が入っていること
- current branch に対応する PR があること
- `gh` を使うコマンドは network 権限付きで実行すること

## まず使うコマンド
```bash
bash .agents/skills/gh-ralph-loop/scripts/observe_pr.sh --wait-for-checks --required-only
```

このコマンドは JSON を stdout に出し、以下の exit code を返す。

- `0`: required checks が通過し、未解決 thread も change request もない
- `20`: failing checks がある
- `30`: checks は通ったが、未解決 thread または `CHANGES_REQUESTED` がある

## ループ手順
1. `.agents/skills/gh-ralph-loop/scripts/observe_pr.sh --wait-for-checks --required-only` を実行する。
2. exit code が `20` の場合:
   - failing checks を確認する
   - ログや差分から原因を特定し、必要な修正を入れる
   - 必要なローカル検証を行う
3. exit code が `30` の場合:
   - unresolved review threads を確認する
   - コメント解釈が必要なら `github:gh-address-comments` の流儀で thread 単位に束ねる
   - 実装修正または返信案作成を行う
4. 修正後に必要なら commit / push する。
5. 再度 Step 1 を実行する。
6. exit code `0` になったらループ完了。

## 運用ルール
- shell script は「観測」と「待機」に限定し、何を直すかの判断は Codex が行う。
- `CHANGES_REQUESTED` でも、resolved thread が空なら blanket request の可能性がある。レビュー本文も確認する。
- outdated unresolved thread は自動 close せず、人が読む価値があるので残す。
- top-level PR comments はこの script では扱わない。必要なら追加で `gh api` か GitHub skill を使う。
- thread 数が 100 を超える巨大 PR は GraphQL pagination を追加する。

## 使い分け
- 状態観測と待機: この skill
- thread の意味解釈と修正対象のクラスタリング: `github:gh-address-comments`
- PR 本文の整形: `rewrite-pr-description`

## 最終出力
ループ中の応答は以下を短くまとめる。
- 今回の観測結果
- 今から直す対象
- 実施した修正
- まだ残っている check / thread
