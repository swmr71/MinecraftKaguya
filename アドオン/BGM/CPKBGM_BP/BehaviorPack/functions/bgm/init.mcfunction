# 初期化関数 - ワールド初回参加時に一度だけ実行
# /function bgm/init

# スコアボード作成（すでにある場合はエラーが出るが無視してOK）
scoreboard objectives add bgm_timer dummy "BGM Timer"

# 全プレイヤーのタイマーをリセット
scoreboard players set @a bgm_timer 0

# BGMをすぐに再生開始（loopオプション付き）
music play music.custom_bgm @s 1 6 loop

tellraw @a {"rawtext":[{"text":"§a[BGM] カスタムBGMを開始しました"}]}
