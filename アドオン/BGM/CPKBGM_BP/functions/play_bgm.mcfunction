# タイマーを進める（1秒間に20カウント進みます）
scoreboard players add @a bgm_timer 1

# タイマーが0（または未設定）なら音を鳴らす
execute as @a[scores={bgm_timer=0..1}] at @s run playsound my_custom.music @s

# 曲の長さ（秒数 × 20）になったらタイマーをリセット
# 例：3分の曲なら 180秒 × 20 = 3600
execute as @a[scores={bgm_timer=3600..}] at @s run scoreboard players set @s bgm_timer 0