#!/bin/bash

# ============================================================================
# Restic バックアップスクリプト
# バージョン: 2.0
# 説明: Paper サーバーのバックアップを Restic で管理
# ============================================================================

set -euo pipefail

# ============================================================================
# 設定
# ============================================================================

# バックアップ対象
SOURCE_DIR="/root/paper/"

# Restic リポジトリ
REPO="/root/ms_backup/restic-repo"

# Restic パスワード（環境変数から読み込むか、ここに設定）
export RESTIC_PASSWORD="ここに暗号化パスワードを生成して入力"

# Discord webhook URL（こちらに Discord webhook URL を設定）
DISCORD_WEBHOOK_URL="こ↑こ↓"

# ログファイル
BACKUP_LOG="/tmp/restic_backup_$(date +%Y%m%d_%H%M%S).log"

# ============================================================================
# 関数定義
# ============================================================================

# ログ出力関数
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$BACKUP_LOG"
}

# エラーハンドリング
error_exit() {
    log "❌ エラー: $1"
    send_discord_notification "fail" "$1"
    exit 1
}

# Discord に通知を送信
send_discord_notification() {
    local status="$1"
    local message="$2"
    
    if [ -z "$DISCORD_WEBHOOK_URL" ]; then
        return
    fi
    
    local color="16711680"  # 赤
    local title="バックアップ失敗"
    
    if [ "$status" = "success" ]; then
        color="65280"  # 緑
        title="バックアップ成功"
    fi
    
    # ログ内容を取得（最後の20行）
    local log_content=$(tail -20 "$BACKUP_LOG" | sed 's/"/\\"/g' | sed 's/$/\\n/g' | tr -d '\n')
    
    # Discord Embed メッセージを作成
    local payload=$(cat <<EOF
{
    "embeds": [
        {
            "title": "$title",
            "description": "$message",
            "color": $color,
            "fields": [
                {
                    "name": "ログファイル",
                    "value": "$BACKUP_LOG",
                    "inline": false
                }
            ],
            "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        }
    ]
}
EOF
)
    
    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$payload" > /dev/null 2>&1 || true
}

# ============================================================================
# 初期化とチェック
# ============================================================================

log "=========================================="
log "Restic バックアップスクリプト開始"
log "=========================================="

# Restic がインストールされているか確認
if ! command -v restic &> /dev/null; then
    error_exit "restic がインストールされていません。apt install restic を実行してください。"
fi

log "✓ Restic バージョン: $(restic version)"

# パスワードが設定されているか確認
if [ -z "$RESTIC_PASSWORD" ]; then
    error_exit "RESTIC_PASSWORD 環境変数が設定されていません。"
fi

# バックアップ対象ディレクトリが存在するか確認
if [ ! -d "$SOURCE_DIR" ]; then
    error_exit "バックアップ対象ディレクトリが見つかりません: $SOURCE_DIR"
fi

log "✓ バックアップ対象: $SOURCE_DIR"
log "✓ Restic リポジトリ: $REPO"

# ============================================================================
# Restic リポジトリの初期化
# ============================================================================

if [ ! -d "$REPO" ]; then
    log "Restic リポジトリを初期化中..."
    mkdir -p "$REPO"
    restic init --repo "$REPO" >> "$BACKUP_LOG" 2>&1 || error_exit "リポジトリの初期化に失敗しました。"
    log "✓ Restic リポジトリを初期化しました。"
else
    log "✓ Restic リポジトリが存在します。"
fi

# ============================================================================
# バックアップの実行
# ============================================================================

log "バックアップを開始中..."
log "コマンド: restic -r $REPO backup $SOURCE_DIR"

if restic -r "$REPO" backup "$SOURCE_DIR" >> "$BACKUP_LOG" 2>&1; then
    log "✓ バックアップが正常に完了しました。"
else
    error_exit "バックアップの実行に失敗しました。"
fi

# ============================================================================
# バックアップ統計を取得
# ============================================================================

log "バックアップ統計を取得中..."
BACKUP_STATS=$(restic -r "$REPO" snapshots --latest 1 2>> "$BACKUP_LOG" || true)
log "最新スナップショット情報:"
log "$BACKUP_STATS"

# ============================================================================
# リテンションポリシーを適用（古いバックアップを削除）
# ============================================================================

log "リテンションポリシーを適用中..."
log "ポリシー: 最後の 7日間、4週間、1年を保持"

if restic -r "$REPO" forget --keep-daily 7 --keep-weekly 4 --keep-yearly 1 --prune >> "$BACKUP_LOG" 2>&1; then
    log "✓ リテンションポリシーを適用しました。"
else
    log "⚠ リテンションポリシーの適用で警告が発生しました。（重大なエラーではありません）"
fi

# ============================================================================
# リポジトリの整合性チェック（オプション）
# ============================================================================

log "リポジトリの整合性を確認中..."
if restic -r "$REPO" check >> "$BACKUP_LOG" 2>&1; then
    log "✓ リポジトリの整合性チェックが完了しました。"
else
    log "⚠ リポジトリの整合性チェックで警告が発生しました。"
fi

# ============================================================================
# 完了
# ============================================================================

log "=========================================="
log "✓ バックアップスクリプトが正常に完了しました。"
log "=========================================="

# 成功を Discord に通知
send_discord_notification "success" "Paper サーバーのバックアップが正常に完了しました。"

# ログファイルをクリーンアップ（オプション：古いログを削除）
find /tmp -name "restic_backup_*.log" -mtime +7 -delete 2>/dev/null || true

exit 0
