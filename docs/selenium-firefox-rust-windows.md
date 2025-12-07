# Firefox + Selenium + Rust (Windows/PowerShell)

Short path to drive Firefox from Rust using Selenium (Java server) on Windows.

## Prereqs
- JDK 17 (Temurin recommended). Verify: `java -version`. If missing: `winget install --id EclipseAdoptium.Temurin.17.JDK` then restart PowerShell. Set `JAVA_HOME` if needed: `setx JAVA_HOME "C:\\Program Files\\Eclipse Adoptium\\jdk-17"`.
- Firefox (release or ESR) installed.
- Rust toolchain already in this repo.

## Install geckodriver
```powershell
$version = "v0.35.0"           # bump to the latest from https://github.com/mozilla/geckodriver/releases
$dest    = "C:\\tools\\geckodriver"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest "https://github.com/mozilla/geckodriver/releases/download/$version/geckodriver-$version-win64.zip" -OutFile "$dest\\geckodriver.zip"
Expand-Archive "$dest\\geckodriver.zip" -DestinationPath $dest -Force
setx PATH "$Env:PATH;$dest"   # restart PowerShell afterwards
# validate
geckodriver --version
```

## Install Selenium Server (standalone)
Pick a 4.x release (example below uses 4.23.0).
```powershell
$selVersion = "4.23.0"
$selDir     = "C:\\tools\\selenium"
New-Item -ItemType Directory -Force -Path $selDir | Out-Null
Invoke-WebRequest "https://github.com/SeleniumHQ/selenium/releases/download/selenium-$selVersion/selenium-server-$selVersion.jar" -OutFile "$selDir\\selenium-server-$selVersion.jar"
```
Start the server (keep this window open):
```powershell
java -jar C:\\tools\\selenium\\selenium-server-4.23.0.jar standalone --port 4444
```
If you prefer driver-only, run `geckodriver --port 4444` instead of the Java server.

## Rust client setup
Add the WebDriver client and Tokio runtime (use `-p <crate>` if running from the workspace root):
```powershell
cargo add thirtyfour
cargo add tokio --features rt-multi-thread,macros
```
Example client (place in `examples/selenium_firefox.rs` in your crate):
```rust
use thirtyfour::prelude::*;
use tokio;

#[tokio::main]
async fn main() -> WebDriverResult<()> {
    let caps = DesiredCapabilities::firefox();
    let driver = WebDriver::new("http://localhost:4444", caps).await?;
    driver.goto("https://example.com").await?;
    println!("Title: {}", driver.title().await?);
    driver.quit().await?;
    Ok(())
}
```
Run it while the server/driver is up:
```powershell
cargo run --example selenium_firefox
```

## WSL notes
- If your code lives in WSL, you can still run the Windows Firefox + Selenium Server on the host and point to `http://localhost:4444` from WSL.
- If you prefer everything inside WSL, install Firefox/Geckodriver there and start `geckodriver --port 4444` inside WSL; the Rust client points to the same URL.
