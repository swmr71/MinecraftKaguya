package com.example.bgmplugin;

import net.kyori.adventure.key.Key;
import net.kyori.adventure.sound.Sound;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.event.player.PlayerResourcePackStatusEvent;
import org.bukkit.scheduler.BukkitTask;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

public class BgmManager implements Listener {

    private final BgmPlugin plugin;

    // プレイヤーごとのループタスク
    private final Map<UUID, BukkitTask> loopTasks = new ConcurrentHashMap<>();

    // 設定キャッシュ
    private String soundKey;
    private int durationTicks;
    private float volume;
    private float pitch;

    public BgmManager(BgmPlugin plugin) {
        this.plugin = plugin;
        reload();
    }

    public void reload() {
        soundKey      = plugin.getConfig().getString("sound-key", "custom.bgm");
        int durationSec = plugin.getConfig().getInt("bgm-duration-seconds", 235);
        durationTicks = durationSec * 20; // 1秒 = 20tick
        volume        = (float) plugin.getConfig().getDouble("volume", 1.0);
        pitch         = (float) plugin.getConfig().getDouble("pitch", 1.0);

        // リロード時は全プレイヤーのループを再起動
        for (Player p : plugin.getServer().getOnlinePlayers()) {
            restartLoop(p);
        }
    }

    // -------------------------------------------------------
    // イベントハンドラ
    // -------------------------------------------------------

    @EventHandler(priority = EventPriority.MONITOR)
    public void onJoin(PlayerJoinEvent event) {
        Player player = event.getPlayer();
        // 参加時にリソースパックを送信
        // （パック適用完了後にBGMを開始するため、ここではまだ再生しない）
        plugin.getServer().getScheduler().runTaskLater(plugin, () -> {
            plugin.getResourcePackUtil().sendPack(player);
        }, 20L); // 1秒後に送信（接続安定化のため）
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onQuit(PlayerQuitEvent event) {
        cancelLoop(event.getPlayer().getUniqueId());
    }

    /**
     * リソースパック適用状態を監視してBGM再生を開始する。
     */
    @EventHandler(priority = EventPriority.MONITOR)
    public void onResourcePackStatus(PlayerResourcePackStatusEvent event) {
        Player player = event.getPlayer();
        switch (event.getStatus()) {
            case SUCCESSFULLY_LOADED -> {
                // パック適用成功 → BGMループ開始
                plugin.getLogger().info(player.getName() + " がリソースパックを適用しました。BGMを開始します。");
                plugin.getServer().getScheduler().runTaskLater(plugin, () -> startLoop(player), 10L);
            }
            case DECLINED -> {
                // 拒否された場合はループを停止（適用しなかった人には流さない）
                plugin.getLogger().info(player.getName() + " がリソースパックを拒否しました。");
                cancelLoop(player.getUniqueId());
            }
            case FAILED_DOWNLOAD, DISCARDED -> {
                plugin.getLogger().warning(player.getName() + " のリソースパック適用に失敗しました: " + event.getStatus());
                cancelLoop(player.getUniqueId());
            }
            default -> { /* ACCEPTED(ダウンロード中) などは無視 */ }
        }
    }

    // -------------------------------------------------------
    // BGM再生ループ管理
    // -------------------------------------------------------

    /**
     * プレイヤーのBGMループを開始する。
     * durationTicks ごとに playsound を発火することでループを擬似実現する。
     */
    private void startLoop(Player player) {
        cancelLoop(player.getUniqueId()); // 既存タスクがあればキャンセル

        // 即時1回再生してから、durationTicks間隔で繰り返す
        playSound(player);

        BukkitTask task = plugin.getServer().getScheduler().runTaskTimer(
                plugin,
                () -> {
                    if (player.isOnline()) {
                        playSound(player);
                    } else {
                        cancelLoop(player.getUniqueId());
                    }
                },
                durationTicks,  // 最初の遅延（曲の長さ後に次を再生）
                durationTicks   // 繰り返し間隔
        );

        loopTasks.put(player.getUniqueId(), task);
    }

    private void restartLoop(Player player) {
        // パック適用済みの人のみ再起動（再適用不要）
        if (loopTasks.containsKey(player.getUniqueId())) {
            startLoop(player);
        }
    }

    private void cancelLoop(UUID uuid) {
        BukkitTask task = loopTasks.remove(uuid);
        if (task != null && !task.isCancelled()) {
            task.cancel();
        }
    }

    /**
     * Adventure API でサウンドを再生。
     * MASTER チャンネルで再生することでクライアント側のミュート設定に関わらず流れる。
     * （musicカテゴリにしたい場合は Sound.Source.MUSIC に変更）
     */
    private void playSound(Player player) {
        try {
            Sound sound = Sound.sound(
                    Key.key(soundKey),        // 例: "custom:bgm" または "custom.bgm"
                    Sound.Source.MUSIC,
                    volume,
                    pitch
            );
            player.playSound(sound);
        } catch (Exception e) {
            plugin.getLogger().warning("サウンド再生エラー (" + player.getName() + "): " + e.getMessage());
        }
    }

    /** サーバー停止時に全タスクをキャンセル */
    public void cancelAll() {
        loopTasks.values().forEach(task -> {
            if (!task.isCancelled()) task.cancel();
        });
        loopTasks.clear();
    }

    public boolean isLooping(UUID uuid) {
        return loopTasks.containsKey(uuid);
    }
}
