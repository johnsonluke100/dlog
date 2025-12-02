package com.dlog.bridge;

import org.bukkit.Bukkit;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.World;
import org.bukkit.entity.ArmorStand;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;
import org.bukkit.scheduler.BukkitRunnable;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Minimal bridge: sends player snapshots to a Rust sidecar and mirrors responses onto armor stands.
 *
 * Protocol (text/plain):
 *  - Plugin → Rust on POST body:
 *      TICK <tick>\n
 *      PLAYER <uuid> <name> <x> <y> <z> <yaw> <pitch> <vx> <vy> <vz>\n
 *      ... (one per online player)
 *      END\n
 *
 *  - Rust → Plugin reply body:
 *      MOVE <uuid> <x> <y> <z> <yaw> <pitch>\n
 *      (optional) VEL <uuid> <vx> <vy> <vz>\n
 *      Lines unknown to us are ignored.
 *
 * Config (config.yml, auto-generated on first run):
 *   endpoint-url: http://127.0.0.1:7070/tick
 *   auth-token: change-me
 *   tick-interval-ticks: 10
 *   set-spectator: false
 */
public final class OmegaBridgePlugin extends JavaPlugin {

    private String endpointUrl;
    private String authToken;
    private int tickInterval;
    private boolean setSpectator;
    private final Map<UUID, ArmorStand> puppets = new HashMap<>();

    @Override
    public void onEnable() {
        saveDefaultConfig();
        loadConfigValues();

        // Clean up any puppets if server reloaded
        Bukkit.getOnlinePlayers().forEach(this::ensurePuppet);

        // Schedule periodic bridge tick
        new BukkitRunnable() {
            private long tickCounter = 0;
            @Override
            public void run() {
                try {
                    tickOnce(tickCounter++);
                } catch (Exception e) {
                    getLogger().warning("bridge tick failed: " + e.getMessage());
                }
            }
        }.runTaskTimer(this, tickInterval, tickInterval);

        getLogger().info("OmegaBridge enabled. Endpoint: " + endpointUrl);
    }

    @Override
    public void onDisable() {
        puppets.values().forEach(ArmorStand::remove);
        puppets.clear();
    }

    private void loadConfigValues() {
        endpointUrl = getConfig().getString("endpoint-url", "http://127.0.0.1:7070/tick");
        authToken = getConfig().getString("auth-token", "change-me");
        tickInterval = getConfig().getInt("tick-interval-ticks", 10);
        setSpectator = getConfig().getBoolean("set-spectator", false);
    }

    private void ensurePuppet(Player player) {
        if (puppets.containsKey(player.getUniqueId())) {
            return;
        }
        Location loc = player.getLocation();
        ArmorStand stand = spawnPuppet(loc);
        puppets.put(player.getUniqueId(), stand);
        if (setSpectator && player.getGameMode() != GameMode.SPECTATOR) {
            player.setGameMode(GameMode.SPECTATOR);
        }
    }

    private ArmorStand spawnPuppet(Location loc) {
        World world = loc.getWorld();
        ArmorStand stand = world.spawn(loc, ArmorStand.class);
        stand.setVisible(false);
        stand.setGravity(true);
        stand.setSmall(true);
        stand.setBasePlate(false);
        stand.setArms(false);
        stand.setMarker(false);
        stand.setCustomNameVisible(false);
        return stand;
    }

    private void tickOnce(long tick) throws IOException {
        // Build payload
        StringBuilder sb = new StringBuilder();
        sb.append("TICK ").append(tick).append('\n');
        for (Player p : Bukkit.getOnlinePlayers()) {
            ensurePuppet(p);
            Location l = p.getLocation();
            double vx = p.getVelocity().getX();
            double vy = p.getVelocity().getY();
            double vz = p.getVelocity().getZ();
            sb.append("PLAYER ")
              .append(p.getUniqueId()).append(' ')
              .append(p.getName()).append(' ')
              .append(fmt(l.getX())).append(' ')
              .append(fmt(l.getY())).append(' ')
              .append(fmt(l.getZ())).append(' ')
              .append(fmt(l.getYaw())).append(' ')
              .append(fmt(l.getPitch())).append(' ')
              .append(fmt(vx)).append(' ')
              .append(fmt(vy)).append(' ')
              .append(fmt(vz)).append('\n');
        }
        sb.append("END\n");
        byte[] body = sb.toString().getBytes(StandardCharsets.UTF_8);

        // Send to Rust
        HttpURLConnection conn = (HttpURLConnection) new URL(endpointUrl).openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setRequestProperty("Content-Type", "text/plain; charset=utf-8");
        conn.setRequestProperty("X-Auth-Token", authToken);
        conn.setConnectTimeout(2000);
        conn.setReadTimeout(2000);
        try (OutputStream os = conn.getOutputStream()) {
            os.write(body);
        }

        int code = conn.getResponseCode();
        if (code != 200) {
            conn.disconnect();
            return;
        }

        try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) {
                handleCommand(line.trim());
            }
        } finally {
            conn.disconnect();
        }
    }

    private void handleCommand(String line) {
        if (line.isEmpty()) return;
        String[] parts = line.split("\\s+");
        if (parts.length < 2) return;
        String cmd = parts[0].toUpperCase();
        if ("MOVE".equals(cmd) && parts.length >= 7) {
            UUID uuid = safeUUID(parts[1]);
            if (uuid == null) return;
            double x = safeDouble(parts[2]);
            double y = safeDouble(parts[3]);
            double z = safeDouble(parts[4]);
            float yaw = (float) safeDouble(parts[5]);
            float pitch = (float) safeDouble(parts[6]);
            ArmorStand stand = puppets.get(uuid);
            if (stand == null || stand.isDead()) {
                Player p = Bukkit.getPlayer(uuid);
                if (p == null) return;
                stand = spawnPuppet(p.getLocation());
                puppets.put(uuid, stand);
            }
            Location loc = stand.getLocation();
            loc.setX(x);
            loc.setY(y);
            loc.setZ(z);
            loc.setYaw(yaw);
            loc.setPitch(pitch);
            stand.teleport(loc);
        } else if ("VEL".equals(cmd) && parts.length >= 5) {
            UUID uuid = safeUUID(parts[1]);
            if (uuid == null) return;
            double vx = safeDouble(parts[2]);
            double vy = safeDouble(parts[3]);
            double vz = safeDouble(parts[4]);
            ArmorStand stand = puppets.get(uuid);
            if (stand != null && !stand.isDead()) {
                stand.setVelocity(new org.bukkit.util.Vector(vx, vy, vz));
            }
        }
    }

    private static String fmt(double d) {
        return String.format(java.util.Locale.US, "%.4f", d);
    }

    private static UUID safeUUID(String s) {
        try {
            return UUID.fromString(s);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static double safeDouble(String s) {
        try {
            return Double.parseDouble(s);
        } catch (NumberFormatException e) {
            return 0.0;
        }
    }
}
