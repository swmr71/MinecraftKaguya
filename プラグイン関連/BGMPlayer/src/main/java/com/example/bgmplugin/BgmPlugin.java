package com.example.bgmplugin;

import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;

public class BgmPlugin extends JavaPlugin {

    private BgmManager bgmManager;
    private ResourcePackUtil resourcePackUtil;

    @Override
    public void onEnable() {
        saveDefaultConfig();
        resourcePackUtil = new ResourcePackUtil(this);
        bgmManager = new BgmManager(this);

        getServer().getPluginManager().registerEvents(bgmManager, this);
        getLogger().info("BgmPlugin enabled!");
    }

    @Override
    public void onDisable() {
        if (bgmManager != null) {
            bgmManager.cancelAll();
        }
        getLogger().info("BgmPlugin disabled.");
    }

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        switch (command.getName().toLowerCase()) {
            case "bgmreload" -> {
                reloadConfig();
                resourcePackUtil.reload();
                bgmManager.reload();
                sender.sendMessage("§a[BGM] 設定をリロードしました。");
                return true;
            }
            case "bgmresend" -> {
                if (args.length == 0) {
                    if (sender instanceof Player p) {
                        resourcePackUtil.sendPack(p);
                        sender.sendMessage("§a[BGM] リソースパックを再送信しました。");
                    } else {
                        sender.sendMessage("§c[BGM] プレイヤー名を指定してください。");
                    }
                } else {
                    Player target = getServer().getPlayer(args[0]);
                    if (target == null) {
                        sender.sendMessage("§c[BGM] プレイヤーが見つかりません: " + args[0]);
                    } else {
                        resourcePackUtil.sendPack(target);
                        sender.sendMessage("§a[BGM] " + target.getName() + " にリソースパックを再送信しました。");
                    }
                }
                return true;
            }
        }
        return false;
    }

    public BgmManager getBgmManager() {
        return bgmManager;
    }

    public ResourcePackUtil getResourcePackUtil() {
        return resourcePackUtil;
    }
}
