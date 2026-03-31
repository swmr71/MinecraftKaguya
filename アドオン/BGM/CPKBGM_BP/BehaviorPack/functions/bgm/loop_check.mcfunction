# BGMループチェック関数
# scoreboard objective "bgm_timer" がなければ初期化
# ※初回はワールドに入ったとき手動で /function bgm/init を実行すること

# タイマーをカウントアップ
scoreboard players add @a bgm_timer 1

# 6000tick (= 5分) ごとに music play を再実行してループを維持
# OGGの長さに合わせて 6000 の数値を変更してください
execute as @a[scores={bgm_timer=6000..}] run music play music.custom_bgm @s 1 6 loop
execute as @a[scores={bgm_timer=6000..}] run scoreboard players set @s bgm_timer 0
