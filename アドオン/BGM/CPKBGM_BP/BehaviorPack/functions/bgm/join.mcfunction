# プレイヤー参加検知用（tick.json から毎tick呼ぶのではなく、
# 参加イベント的に使う場合は scoreboard tag で管理する）

# bgm_joined タグがないプレイヤー（=新規参加者）にBGMを流す
music play music.custom_bgm @s 1 6 loop
scoreboard players set @s bgm_timer 0
tag @s add bgm_joined
