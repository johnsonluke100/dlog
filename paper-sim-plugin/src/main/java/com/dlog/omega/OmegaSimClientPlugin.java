package com.dlog.omega;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.command.Command;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.ArmorStand;
import org.bukkit.entity.Entity;
import org.bukkit.entity.Player;
import org.bukkit.plugin.java.JavaPlugin;
import org.bukkit.scheduler.BukkitRunnable;
import org.bukkit.util.Vector;
import net.md_5.bungee.api.ChatMessageType;
import net.md_5.bungee.api.chat.TextComponent;

import javax.net.ssl.HttpsURLConnection;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

public class OmegaSimClientPlugin extends JavaPlugin {
    private final Gson gson = new Gson();
    private final Map<String, ArmorStand> tracked = new HashMap<>();
    private final Map<UUID, Set<String>> lastBarriers = new HashMap<>();
    private String apiBase;
    private String authToken;
    private long lastUiMs = 0L;
    private int intervalTicks;

    @Override
    public void onEnable() {
        saveDefaultConfig();
        this.apiBase = getConfig().getString("api_base", "http://localhost:8888");
        this.authToken = getConfig().getString("auth_token", "");
        this.intervalTicks = getConfig().getInt("tick_interval_ticks", 10);

        new BukkitRunnable() {
            @Override
            public void run() {
                tickPlayers();
            }
        }.runTaskTimerAsynchronously(this, 40L, intervalTicks);

        getLogger().info("[omega-sim] client enabled; posting to " + apiBase);
    }

    @Override
    public void onDisable() {
        // Clean up armor stands we spawned.
        Bukkit.getScheduler().runTask(this, () -> {
            for (ArmorStand stand : tracked.values()) {
                if (stand != null && !stand.isDead()) {
                    stand.remove();
                }
            }
            tracked.clear();
        });
    }

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (!"simtick".equalsIgnoreCase(command.getName())) {
            return false;
        }
        if (!(sender instanceof Player)) {
            sender.sendMessage(ChatColor.RED + "Players only.");
            return true;
        }
        Player player = (Player) sender;
        Bukkit.getScheduler().runTaskAsynchronously(this, () -> doSimTick(player));
        return true;
    }

    private void tickPlayers() {
        for (Player player : Bukkit.getOnlinePlayers()) {
            doSimTick(player);
        }
    }

    private void doSimTick(Player player) {
        try {
            SimTickResponse resp = postTick(player);
            if (resp == null || resp.view == null) {
                return;
            }
            Bukkit.getScheduler().runTask(this, () -> applyView(player, resp));
        } catch (IOException e) {
            getLogger().warning("[omega-sim] tick failed: " + e.getMessage());
        }
    }

    private SimTickResponse postTick(Player player) throws IOException {
        URL url = new URL(apiBase + "/v1/sim/tick");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        if (conn instanceof HttpsURLConnection) {
            ((HttpsURLConnection) conn).setSSLSocketFactory((HttpsURLConnection.getDefaultSSLSocketFactory()));
        }
        conn.setRequestMethod("POST");
        conn.setConnectTimeout(3000);
        conn.setReadTimeout(4000);
        conn.setRequestProperty("Content-Type", "application/json");
        if (authToken != null && !authToken.isEmpty()) {
            conn.setRequestProperty("X-Auth-Token", authToken);
        }
        conn.setDoOutput(true);

        String payload = buildPayload(player);
        byte[] bytes = payload.getBytes(StandardCharsets.UTF_8);
        conn.setFixedLengthStreamingMode(bytes.length);
        try (OutputStream os = conn.getOutputStream()) {
            os.write(bytes);
        }

        int code = conn.getResponseCode();
        InputStream body = (code >= 200 && code < 300) ? conn.getInputStream() : conn.getErrorStream();
        String responseBody = readAll(body);
        conn.disconnect();

        if (code < 200 || code >= 300) {
            throw new IOException("HTTP " + code + " body=" + responseBody);
        }

        return gson.fromJson(responseBody, SimTickResponse.class);
    }

    private String buildPayload(Player player) {
        Location loc = player.getLocation();
        Vector vel = player.getVelocity();

        JsonObject root = new JsonObject();
        root.addProperty("player_id", player.getUniqueId().toString());

        JsonObject pose = new JsonObject();
        JsonObject pos = new JsonObject();
        pos.addProperty("x", loc.getX());
        pos.addProperty("y", loc.getY());
        pos.addProperty("z", loc.getZ());
        pose.add("pos", pos);
        pose.addProperty("yaw", loc.getYaw());
        pose.addProperty("pitch", loc.getPitch());
        root.add("pose", pose);

        JsonObject inputs = new JsonObject();
        inputs.addProperty("forward", player.isSprinting());
        inputs.addProperty("back", false);
        inputs.addProperty("left", false);
        inputs.addProperty("right", false);
        inputs.addProperty("jump", !player.isOnGround());
        inputs.addProperty("sneak", player.isSneaking());
        root.add("inputs", inputs);

        root.addProperty("client_time_ms", System.currentTimeMillis());

        return gson.toJson(root);
    }

    private void applyView(Player player, SimTickResponse resp) {
        World world = player.getWorld();
        if (resp.view == null) {
            return;
        }

        Set<String> seen = new HashSet<>();
        if (resp.view.entities != null) {
            for (RenderEntity entity : resp.view.entities) {
                if (entity == null || entity.id == null) {
                    continue;
                }
                seen.add(entity.id);
                ArmorStand stand = tracked.get(entity.id);
                if (stand == null || stand.isDead() || !stand.isValid()) {
                    stand = world.spawn(world.getSpawnLocation(), ArmorStand.class);
                    stand.setVisible(false);
                    stand.setGravity(false);
                    stand.setCanPickupItems(false);
                    stand.setBasePlate(false);
                    stand.setMarker(true);
                    stand.setCustomNameVisible(true);
                    stand.setCustomName(ChatColor.AQUA + entity.kind + ChatColor.GRAY + " " + entity.id);
                    tracked.put(entity.id, stand);
                }
                Location target = new Location(world, entity.pos.x, entity.pos.y, entity.pos.z, entity.yaw, entity.pitch);
                stand.teleport(target);
            }
        }

        // Remove armor stands that no longer exist in the view.
        Set<String> toRemove = new HashSet<>(tracked.keySet());
        toRemove.removeAll(seen);
        for (String id : toRemove) {
            ArmorStand stand = tracked.remove(id);
            if (stand != null && !stand.isDead()) {
                stand.remove();
            }
        }

        applyBarriers(player, resp);
        maybeSendUi(player, resp);
    }

    private void applyBarriers(Player player, SimTickResponse resp) {
        if (resp.view == null || resp.view.barriers == null) {
            return;
        }

        Set<String> current = lastBarriers.computeIfAbsent(player.getUniqueId(), k -> new HashSet<>());
        Set<String> next = new HashSet<>();

        for (Barrier b : resp.view.barriers) {
            if (b == null || b.min == null || b.max == null) {
                continue;
            }
            int minX = (int) Math.floor(Math.min(b.min.x, b.max.x));
            int maxX = (int) Math.floor(Math.max(b.min.x, b.max.x));
            int minY = (int) Math.floor(Math.min(b.min.y, b.max.y));
            int maxY = (int) Math.floor(Math.max(b.min.y, b.max.y));
            int minZ = (int) Math.floor(Math.min(b.min.z, b.max.z));
            int maxZ = (int) Math.floor(Math.max(b.min.z, b.max.z));

            for (int x = minX; x <= maxX; x++) {
                for (int y = minY; y <= maxY; y++) {
                    for (int z = minZ; z <= maxZ; z++) {
                        next.add(key(x, y, z));
                    }
                }
            }
        }

        // Add new barriers (client-side only).
        for (String key : next) {
            if (!current.contains(key)) {
                String[] parts = key.split(":");
                int x = Integer.parseInt(parts[0]);
                int y = Integer.parseInt(parts[1]);
                int z = Integer.parseInt(parts[2]);
                Location loc = new Location(player.getWorld(), x, y, z);
                player.sendBlockChange(loc, Material.BARRIER, (byte) 0);
            }
        }

        // Remove old barriers that disappeared.
        for (String key : current) {
            if (!next.contains(key)) {
                String[] parts = key.split(":");
                int x = Integer.parseInt(parts[0]);
                int y = Integer.parseInt(parts[1]);
                int z = Integer.parseInt(parts[2]);
                Location loc = new Location(player.getWorld(), x, y, z);
                player.sendBlockChange(loc, Material.AIR, (byte) 0);
            }
        }

        lastBarriers.put(player.getUniqueId(), next);
    }

    private String key(int x, int y, int z) {
        return x + ":" + y + ":" + z;
    }

    private void maybeSendUi(Player player, SimTickResponse resp) {
        long now = System.currentTimeMillis();
        if (resp.view != null && resp.view.ui != null && resp.view.ui.hotbar != null && now - lastUiMs > 2000) {
            String first = resp.view.ui.hotbar.isEmpty() ? "" : resp.view.ui.hotbar.get(0);
            if (!first.isEmpty()) {
                player.spigot().sendMessage(ChatMessageType.ACTION_BAR, new TextComponent(first));
            }
            for (String line : resp.view.ui.hotbar) {
                player.sendMessage(ChatColor.GREEN + "[Ω] " + ChatColor.WHITE + line);
            }
            lastUiMs = now;
        }
    }

    private String readAll(InputStream is) throws IOException {
        if (is == null) {
            return "";
        }
        try (BufferedReader br = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) {
                sb.append(line);
            }
            return sb.toString();
        }
    }

    // DTOs for parsing the API response.
    private static class SimTickResponse {
        long tick;
        String state_version;
        long server_time_ms;
        SimView view;
    }

    private static class SimView {
        JsonArray anchors;
        RenderEntity[] entities;
        Barrier[] barriers;
        UiOverlay ui;
    }

    private static class RenderEntity {
        String id;
        String kind;
        Vec3 pos;
        float yaw;
        float pitch;
    }

    private static class Barrier {
        Vec3 min;
        Vec3 max;
    }

    private static class UiOverlay {
        String title;
        java.util.List<String> hotbar;
    }

    private static class Vec3 {
        double x;
        double y;
        double z;
    }
}
