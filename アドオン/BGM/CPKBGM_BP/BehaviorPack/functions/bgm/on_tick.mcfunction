# メインtick処理

# --- 参加検知 ---
# bgm_joined タグを持っていないプレイヤーを参加者として扱い、BGMを開始
execute as @a[tag=!bgm_joined] run function bgm/join

# --- ループ維持 ---
# タイマーをカウントアップ（bgm_joined タグを持つプレイヤーのみ）
scoreboard players add @a[tag=bgm_joined] bgm_timer 1

# ★★ここの 6000 をOGGファイルの長さ(tick換算)に合わせて変更 ★★
# 1秒 = 20tick  例: 3分の曲なら 3600tick
execute as @a[tag=bgm_joined, scores={bgm_timer=6000..}] run music play music.custom_bgm @s 1 6 loop
execute as @a[tag=bgm_joined, scores={bgm_timer=6000..}] run scoreboard players set @s bgm_timer 0
