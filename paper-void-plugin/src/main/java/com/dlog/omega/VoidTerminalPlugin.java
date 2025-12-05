package com.dlog.omega;

import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.block.Block;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;

public class VoidTerminalPlugin extends JavaPlugin implements CommandExecutor {
    private static final int PLATFORM_Y = 64;
    private static final int PLATFORM_RADIUS = 1; // 3x3 pad

    @Override
    public void onEnable() {
        if (getCommand("recenter") != null) {
            getCommand("recenter").setExecutor(this);
        }
        // Build the platform once the default world is fully loaded.
        Bukkit.getScheduler().runTask(this, this::ensureSpawnPlatform);
        getLogger().info("[void] void-terminal enabled");
    }

    private void ensureSpawnPlatform() {
        World world = Bukkit.getWorlds().isEmpty() ? null : Bukkit.getWorlds().get(0);
        ensureSpawnPlatform(world);
    }

    private void ensureSpawnPlatform(World world) {
        if (world == null) {
            getLogger().warning("[void] no world loaded; cannot build spawn platform");
            return;
        }
        Location spawn = world.getSpawnLocation();
        int centerX = spawn.getBlockX();
        int centerZ = spawn.getBlockZ();

        for (int dx = -PLATFORM_RADIUS; dx <= PLATFORM_RADIUS; dx++) {
            for (int dz = -PLATFORM_RADIUS; dz <= PLATFORM_RADIUS; dz++) {
                Block block = world.getBlockAt(centerX + dx, PLATFORM_Y, centerZ + dz);
                if (block.getType() != Material.BEDROCK) {
                    block.setType(Material.BEDROCK);
                }
            }
        }
        world.setSpawnLocation(centerX, PLATFORM_Y + 1, centerZ);
    }

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (!"recenter".equalsIgnoreCase(command.getName())) {
            return false;
        }
        if (!(sender instanceof Player)) {
            sender.sendMessage(ChatColor.RED + "Players only.");
            return true;
        }
        Player player = (Player) sender;
        World world = player.getWorld();
        ensureSpawnPlatform(world);
        Location spawn = world.getSpawnLocation();
        player.teleport(new Location(world, spawn.getX() + 0.5, spawn.getY(), spawn.getZ() + 0.5));
        player.sendMessage(ChatColor.GREEN + "Back to void spawn.");
        return true;
    }
}
