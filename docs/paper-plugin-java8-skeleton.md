# Java 8 Paper plugin skeleton (MC 1.8.8 → Cloud Run)

Minimal Paper/Spigot 1.8.8 plugin (Java 8) that:
- Registers `/dlogtip <player> <amount>` and a join event.
- Posts JSON to a Cloud Run endpoint with `HttpURLConnection`.
- Uses only Java 8 standard library (no extra deps).

## File layout
```
plugin-src/
  pom.xml
  src/main/java/com/dlog/omega/DlogPlugin.java
  src/main/resources/plugin.yml
```

## `pom.xml` (Java 8)
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.dlog</groupId>
  <artifactId>dlog-paper-plugin</artifactId>
  <version>0.1.0</version>
  <name>dlog-paper-plugin</name>
  <properties>
    <maven.compiler.source>1.8</maven.compiler.source>
    <maven.compiler.target>1.8</maven.compiler.target>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.spigotmc</groupId>
      <artifactId>spigot-api</artifactId>
      <version>1.8.8-R0.1-SNAPSHOT</version>
      <scope>provided</scope>
    </dependency>
  </dependencies>
</project>
```

## `plugin.yml`
```yaml
name: DlogPlugin
main: com.dlog.omega.DlogPlugin
version: 0.1.0
description: Minimal DLOG → Cloud Run bridge (Java 8, MC 1.8.8)
commands:
  dlogtip:
    description: Send a DLOG tip via Cloud Run
    usage: /dlogtip <player> <amount>
```

## `DlogPlugin.java`
```java
package com.dlog.omega;

import org.bukkit.Bukkit;
import org.bukkit.ChatColor;
import org.bukkit.command.Command;
import org.bukkit.command.CommandExecutor;
import org.bukkit.command.CommandSender;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.plugin.java.JavaPlugin;

import javax.net.ssl.HttpsURLConnection;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

public class DlogPlugin extends JavaPlugin implements Listener, CommandExecutor {
    // TODO: set these via config.yml or env
    private static final String API_BASE = "https://dlog-api-xxx-yyy.run.app";
    private static final String FRONTEND_TOKEN = "replace-with-shared-secret";

    @Override
    public void onEnable() {
        // Register events and command
        Bukkit.getPluginManager().registerEvents(this, this);
        getCommand("dlogtip").setExecutor(this);
        getLogger().info("[dlog] plugin enabled (Java 8, MC 1.8.8)");
    }

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (!command.getName().equalsIgnoreCase("dlogtip")) {
            return false;
        }
        if (!(sender instanceof Player)) {
            sender.sendMessage(ChatColor.RED + "Players only.");
            return true;
        }
        if (args.length != 2) {
            sender.sendMessage(ChatColor.YELLOW + "Usage: /dlogtip <player> <amount>");
            return true;
        }
        Player from = (Player) sender;
        Player to = Bukkit.getPlayerExact(args[0]);
        if (to == null) {
            from.sendMessage(ChatColor.RED + "Target not online.");
            return true;
        }
        String amount = args[1];
        String payload = buildTipJson(from.getUniqueId(), to.getUniqueId(), amount, from.getWorld().getName());

        Bukkit.getScheduler().runTaskAsynchronously(this, () -> {
            try {
                String body = postJson("/v1/events/tip", payload);
                from.sendMessage(ChatColor.GREEN + "Tip sent. Cloud Run says: " + body);
            } catch (IOException e) {
                from.sendMessage(ChatColor.RED + "Tip failed: " + e.getMessage());
                getLogger().warning("[dlog] tip post failed: " + e.getMessage());
            }
        });
        return true;
    }

    @EventHandler
    public void onJoin(PlayerJoinEvent event) {
        Player p = event.getPlayer();
        String payload = "{\"type\":\"join\",\"player_uuid\":\"" + p.getUniqueId() + "\",\"world\":\"" + p.getWorld().getName() + "\"}";
        Bukkit.getScheduler().runTaskAsynchronously(this, () -> {
            try {
                postJson("/v1/events/join", payload);
            } catch (IOException e) {
                getLogger().warning("[dlog] join post failed: " + e.getMessage());
            }
        });
    }

    private String buildTipJson(UUID from, UUID to, String amount, String world) {
        // Minimal manual JSON to avoid extra deps on Java 8
        return "{"
                + "\"type\":\"tip\","
                + "\"from_player_uuid\":\"" + from.toString() + "\","
                + "\"to_player_uuid\":\"" + to.toString() + "\","
                + "\"amount\":\"" + amount + "\","
                + "\"world\":\"" + world + "\","
                + "\"server_label\":\"paper-188-1\""
                + "}";
    }

    private String postJson(String path, String payload) throws IOException {
        URL url = new URL(API_BASE + path);
        HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("X-Frontend-Token", FRONTEND_TOKEN);
        conn.setConnectTimeout(4000);
        conn.setReadTimeout(6000);
        conn.setDoOutput(true);

        byte[] bytes = payload.getBytes(StandardCharsets.UTF_8);
        conn.setFixedLengthStreamingMode(bytes.length);
        try (OutputStream os = conn.getOutputStream()) {
            os.write(bytes);
        }

        int code = conn.getResponseCode();
        InputStream is = (code >= 200 && code < 300) ? conn.getInputStream() : conn.getErrorStream();
        String body = readAll(is);
        conn.disconnect();

        if (code < 200 || code >= 300) {
            throw new IOException("HTTP " + code + " body=" + body);
        }
        return body;
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
}
```

## Build and run
```
cd plugin-src
mvn package
cp target/dlog-paper-plugin-0.1.0.jar /path/to/paper-1.8.8/plugins/
```
Configure `API_BASE` and `FRONTEND_TOKEN` in the Java source (or wire a `config.yml` if desired). Then start Paper 1.8.8; use `/dlogtip <player> <amount>` to exercise the Cloud Run POST. Join events also POST to `/v1/events/join`. All network calls run async to keep the main thread unblocked.***

## Bonus: “Ω tick” tester to a Clear Linux engine
Add this command to ping a Clear Linux Ω engine stub (e.g., `PUBLIC_IP:4400` DNAT → `engine0:4433`):
```java
if (command.getName().equalsIgnoreCase("omegatick")) {
    if (!(sender instanceof Player)) {
        sender.sendMessage(ChatColor.RED + "Players only.");
        return true;
    }
    if (args.length != 2) {
        sender.sendMessage(ChatColor.YELLOW + "Usage: /omegatick <host> <port>");
        return true;
    }
    String host = args[0];
    int port = Integer.parseInt(args[1]);
    Player p = (Player) sender;
    Bukkit.getScheduler().runTaskAsynchronously(this, () -> {
        try (Socket s = new Socket()) {
            s.connect(new InetSocketAddress(host, port), 2000);
            s.getOutputStream().write(("tick from " + p.getName() + "\n").getBytes("UTF-8"));
            byte[] buf = new byte[512];
            int n = s.getInputStream().read(buf);
            String resp = n > 0 ? new String(buf, 0, n, "UTF-8") : "(no reply)";
            p.sendMessage(ChatColor.GREEN + "Ω tick ok: " + resp.trim());
        } catch (Exception e) {
            p.sendMessage(ChatColor.RED + "Ω tick failed: " + e.getMessage());
        }
    });
    return true;
}
```

Register it in `plugin.yml`:
```yaml
commands:
  dlogtip:
    description: Send a DLOG tip via Cloud Run
    usage: /dlogtip <player> <amount>
  omegatick:
    description: Send a raw Ω tick to an engine TCP port
    usage: /omegatick <host> <port>
```

Import required classes:
```java
import java.net.InetSocketAddress;
import java.net.Socket;
```
