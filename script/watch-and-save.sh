#!/bin/bash
# Watch Claude Code session and sync to Obsidian in real-time (append mode)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

OBSIDIAN_DIR="$HOME/workspace/github.com/onsd/obsidian/99_claude_code"
SESSION_PATTERNS=(
    "$HOME/.claude/projects/-Users-takamichi-omori-workspace-github-com-LayerXCom*"
    "$HOME/.claude/projects/-Users-takamichi-omori-workspace-github-com-onsd-dotfiles"
)  # 監視対象のプロジェクトディレクトリ
LAST_LINE_DIR="${DOTFILES_DIR}/logs/last-synced-lines"  # セッションごとの同期状態を保存
LOG_FILE="${DOTFILES_DIR}/logs/watch-and-save.log"

mkdir -p "$OBSIDIAN_DIR"
mkdir -p "$LAST_LINE_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

sync_session() {
    local session_file="$1"
    local TODAY=$(date +%Y年%-m月%-d日)
    local TODAY_DIR=$(date +%Y-%m-%d)
    local TODAY_START_UTC=$(TZ=UTC date -v-9H -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-%d) 00:00:00" +%Y-%m-%dT%H:%M:%S 2>/dev/null)

    # セッションファイルごとの識別子（パスをハッシュ化）
    local session_hash=$(echo "$session_file" | md5 | cut -c1-8)
    local OUTPUT_DIR="${OBSIDIAN_DIR}/${TODAY_DIR}"
    local OUTPUT_FILE="${OUTPUT_DIR}/${session_hash}.md"
    local LAST_LINE_FILE="${LAST_LINE_DIR}/${session_hash}"

    mkdir -p "$OUTPUT_DIR"

    # プロジェクトディレクトリ情報を抽出（.claude/projects/<encoded-path>/... からディレクトリ名を取得）
    local project_encoded=$(echo "$session_file" | sed 's|.*/\.claude/projects/\([^/]*\)/.*|\1|')
    # エンコードされたパスを復元（先頭の - を / に、残りの - を / に置換して存在確認）
    local project_dir=$(echo "$project_encoded" | sed 's/^-/\//' | sed 's/-/\//g')
    # 復元パスが存在しない場合はエンコード名をそのまま使用
    if [ ! -d "$project_dir" ]; then
        project_dir="$project_encoded"
    fi

    # プロジェクト名を抽出（エンコードパスの末尾部分）
    local project_name=$(echo "$project_encoded" | sed 's/.*-//')

    # モデル名をセッションファイルの最初のassistantメッセージから抽出
    local model=$(head -100 "$session_file" | jq -r 'select(.type == "assistant") | .model // empty' 2>/dev/null | head -1)
    model="${model:-unknown}"

    # Create file with frontmatter and header if it doesn't exist
    if [ ! -f "$OUTPUT_FILE" ]; then
        cat > "$OUTPUT_FILE" << EOF
---
directory: "${project_dir}"
project: ${project_name}
datetime: $(date '+%Y-%m-%d %H:%M:%S')
session: ${session_hash}
model: ${model}
tags:
  - claude-code
---
# ${TODAY} Claudeとの会話 (${session_hash})

EOF
    fi

    # Get last synced line number for this specific session
    local last_line=0
    if [ -f "$LAST_LINE_FILE" ]; then
        last_line=$(cat "$LAST_LINE_FILE" 2>/dev/null || echo 0)
    fi

    # Count current lines in session file
    local current_lines=$(wc -l < "$session_file" | tr -d ' ')

    # Only process new lines (append mode - no overwriting)
    if [ "$current_lines" -gt "$last_line" ]; then
        local new_content=$(tail -n +$((last_line + 1)) "$session_file" | jq -r --arg today_start "$TODAY_START_UTC" '
        select(.type == "user" or .type == "assistant") |
        select((.timestamp // "9999") >= $today_start) |
        if .type == "user" then
            (.message.content // .content // "") as $content |
            if ($content | type) == "string" then
                if ($content | test("<local-command|<command-name>|<system-reminder>|<task-notification>"; "i")) then
                    empty
                else
                    "**ユーザー**: " + $content
                end
            else
                empty
            end
        elif .type == "assistant" then
            if (.message.content | type) == "array" then
                (.message.content[] | select(.type == "text") |
                    if (.text | test("^No response requested"; "i")) then
                        empty
                    else
                        "**Claude**: " + .text
                    end
                )
            else
                empty
            end
        else
            empty
        end
        ' 2>/dev/null)

        # Append new content if any
        if [ -n "$new_content" ]; then
            echo "$new_content" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            echo "$current_lines" > "$LAST_LINE_FILE"
            return 0  # 新しいコンテンツあり
        fi

        # Update last synced line
        echo "$current_lines" > "$LAST_LINE_FILE"
    fi
    return 1  # 新しいコンテンツなし
}

# Find all active sessions across matching project directories (exclude subagents)
find_sessions() {
    for pattern in "${SESSION_PATTERNS[@]}"; do
        for dir in $pattern; do
            if [ -d "$dir" ]; then
                find "$dir" -path "*/subagents/*" -prune -o \
                    -name "*.jsonl" -type f -mmin -60 -size +1000c -print \
                    2>/dev/null
            fi
        done
    done
}

log "Started watching for Claude session changes (append mode)"
log "Monitoring: ${SESSION_PATTERNS[*]}"
echo "Watching for Claude session changes (append mode)..."
echo "Monitoring: ${SESSION_PATTERNS[*]}"
echo "Log file: $LOG_FILE"

while true; do
    start_time=$(date +%s.%N)
    synced_count=0

    # 全てのアクティブなセッションを処理
    while IFS= read -r session; do
        if [ -n "$session" ]; then
            if sync_session "$session"; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Synced: $session"
                ((synced_count++))
            fi
        fi
    done < <(find_sessions)

    end_time=$(date +%s.%N)
    elapsed=$(echo "$end_time - $start_time" | bc)

    if [ "$synced_count" -gt 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Synced $synced_count session(s) in ${elapsed}s"
        log "Synced $synced_count session(s) in ${elapsed}s"
    fi

    sleep 5
done
