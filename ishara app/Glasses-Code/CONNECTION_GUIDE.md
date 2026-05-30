# Ishara Smart Glasses – Connection Guide

This guide walks you through setting up the ESP32 safety glasses and connecting them to the Ishara Flutter app over WiFi.

---

## Hardware Requirements

| Component | Description |
|---|---|
| **ESP32 Dev Board** | Any ESP32 module (e.g. ESP32-WROOM-32) |
| **INMP441 I2S Microphone** | Digital MEMS mic for speech-to-text |
| **HC-SR04 Ultrasonic Sensor** | Obstacle detection (2–400 cm range) |
| **Buzzer** | Proximity alert beeps + feedback tones |
| **SOS Button** | Momentary push-button for emergency |
| **Record Button** | Momentary push-button to toggle mic recording |
| **Power Supply** | 3.3 V regulated or USB power bank |

### Wiring Diagram

```
ESP32 Pin    Component         Pin
─────────    ─────────         ───
GPIO 5       HC-SR04           TRIG
GPIO 18      HC-SR04           ECHO
GPIO 23      Buzzer            Signal (+)
GPIO 4       SOS Button        One leg (other leg → GND)
GPIO 2       Record Button     One leg (other leg → GND)
GPIO 33      INMP441           BCLK (SCK)
GPIO 25      INMP441           LRCL (WS)
GPIO 32      INMP441           DOUT (SD)
3V3          All modules       VCC / VDD
GND          All modules       GND
```

> Both buttons use `INPUT_PULLUP`, so connect one leg to the GPIO pin and the other leg to **GND**. No external resistor needed.

---

## Step 1 — Install Arduino IDE & Libraries

1. Install [Arduino IDE 2.x](https://www.arduino.cc/en/software).
2. Add the ESP32 board package:
   - Go to **File → Preferences → Additional Board Manager URLs** and add:
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Open **Tools → Board → Boards Manager**, search for `esp32`, and install **esp32 by Espressif Systems**.
3. Install required libraries via **Sketch → Include Library → Manage Libraries**:
   - **WebSockets** by Markus Sattler (provides `WebSocketsServer.h`)
   - **ArduinoJson** by Benoît Blanchon (version 6.x or 7.x)

---

## Step 2 — Configure WiFi Credentials

Open `glasses.ino` and update lines 30–31 with your WiFi network name and password:

```cpp
const char* WIFI_SSID     = "MyHomeWiFi";      // ← your WiFi name
const char* WIFI_PASSWORD = "MyPassword123";    // ← your WiFi password
```

> **Important:** The phone running the Ishara app and the ESP32 glasses **must be on the same WiFi network** (same router / hotspot).

---

## Step 3 — Upload Firmware to ESP32

1. Connect the ESP32 to your computer via USB.
2. In Arduino IDE, select:
   - **Board:** ESP32 Dev Module (or your specific board)
   - **Port:** The COM port that appeared when you plugged in the USB
   - **Upload Speed:** 921600
   - **Partition Scheme:** Default 4 MB with spiffs
3. Click **Upload** (→ button).
4. Open **Serial Monitor** (baud rate: **115200**) to see boot output.

### Expected Serial Output

```
=== ESP32 Safety Glasses (WebSocket) ===
Connecting to WiFi: MyHomeWiFi
.....
WiFi connected – IP: 192.168.1.50
Initializing I2S Microphone...
I2S Microphone initialized
WebSocket server started on port 8080
Connect from app: ws://192.168.1.50:8080
```

**Write down the IP address** shown (e.g. `192.168.1.50`) — you'll need it in the next step.

---

## Step 4 — Connect from the Ishara App

1. Open the Ishara app on your phone.
2. Go to **Profile → Hardware Pairing** (or tap the glasses icon if visible).
3. Enter the connection details:
   - **IP Address:** The IP shown in Serial Monitor (e.g. `192.168.1.50`)
   - **Port:** `8080` (default, pre-filled)
4. Tap **Connect**.

Once connected you will see:
- **Status** changes to "Connected" (green).
- **Live sensor data** appears showing the ultrasonic distance in cm.
- **Mic controls** become available (Start / Stop recording).
- A **Vibration Test** button to verify the buzzer works.

---

## Step 5 — Using the Features

### Obstacle Detection (Automatic)

Once connected, the glasses send ultrasonic distance readings every 500 ms. These appear in two places:

- **Hardware Pairing screen** — live distance readout.
- **Safety tab** — the obstacle card switches from "Simulated" to "Live" and displays real readings. When an obstacle is closer than 40 cm, the glasses buzzer beeps faster and the app shows a warning.

### SOS Button

Press the **SOS button** (GPIO 4) on the glasses. This:
1. Plays 5 rapid beeps on the buzzer.
2. Sends an SOS event to the app.
3. The app automatically arms and starts the SOS countdown in the Safety tab.

### Microphone / Speech-to-Text

You can use the glasses microphone instead of the phone mic for voice input:

**From the Hardware Pairing screen:**
- Tap **Start Recording** → glasses mic begins streaming audio.
- Tap **Stop Recording** → streaming stops.

**From the Communicate (Talk) screen:**
1. When glasses are connected, a **Mic source** toggle appears above the Translate/Microphone buttons.
2. Select **Glasses** to use the glasses mic, or **Phone** for the phone's built-in mic.
3. Tap **Microphone** to start listening — the selected source will be used.

### Vibration / Buzzer Commands

The app can trigger buzzer patterns on the glasses:
- **Short pulse:** Two quick beeps (default).
- **Long pulse:** One 400 ms beep.

These are sent from the Hardware Pairing screen's **Test Vibration** button and automatically during obstacle warnings.

---

## Troubleshooting

| Problem | Solution |
|---|---|
| **WiFi won't connect** | Double-check SSID and password in `glasses.ino`. Ensure the network is 2.4 GHz (ESP32 doesn't support 5 GHz). |
| **App can't connect** | Verify both devices are on the same WiFi. Check the IP and port match. Make sure no firewall blocks port 8080. |
| **Serial shows "I2S driver install failed"** | Check INMP441 wiring. Ensure VDD is connected to 3.3 V (not 5 V). |
| **No sensor readings** | Check HC-SR04 wiring. TRIG → GPIO 5, ECHO → GPIO 18. Ensure the sensor has 5 V power (some HC-SR04 need 5 V VCC but ESP32 ECHO tolerates the 5 V return signal). |
| **Buzzer doesn't beep** | Verify buzzer signal wire is on GPIO 23. Some passive buzzers need a transistor driver. Use an active buzzer for simplest setup. |
| **Audio sounds distorted** | The INMP441 outputs 24-bit audio in a 32-bit frame. The firmware converts to 16-bit. Ensure SD (data out) is on GPIO 32 and the mic isn't being powered by 5 V. |
| **Connection drops** | The ESP32 WebSocket server supports reconnection — just tap Connect again in the app. Check that the ESP32 is within WiFi range. |
| **App shows "Simulated" on Safety tab** | The glasses are not connected. Go to Hardware Pairing and connect first. Once connected, the badge switches to "Live". |

---

## Using a Phone Hotspot (No Router)

If you don't have a shared WiFi router:

1. Enable **Mobile Hotspot** on your phone (Settings → Hotspot & Tethering).
2. Set the SSID and password in `glasses.ino` to your hotspot's name and password.
3. Upload the firmware and power on the glasses — they'll connect to your phone's hotspot.
4. Open Ishara and connect using the IP shown in Serial Monitor.

> On Android, the hotspot IP for connected devices is typically in the `192.168.43.x` range.

---

## Pin Reference Summary

| GPIO | Function | Notes |
|------|----------|-------|
| 5 | Ultrasonic TRIG | Output |
| 18 | Ultrasonic ECHO | Input |
| 23 | Buzzer | Output (active buzzer recommended) |
| 4 | SOS Button | Input, active LOW, internal pull-up |
| 2 | Record Button | Input, active LOW, internal pull-up |
| 33 | INMP441 BCLK | I2S serial clock |
| 25 | INMP441 LRCL | I2S word select |
| 32 | INMP441 DOUT | I2S data in |

---

## Communication Protocol

The glasses and app communicate via **WebSocket** using JSON text frames.

### Glasses → App

| Message Type | Example | When |
|---|---|---|
| `sensor_update` | `{"type":"sensor_update","payload":{"distance_cm":35,"timestamp":12345}}` | Every 500 ms |
| `event` (SOS) | `{"type":"event","payload":{"event":"sos","timestamp":12345}}` | SOS button pressed |
| `audio_start` | `{"type":"audio_start","payload":{"sample_rate":16000,"bits":16,"channels":1}}` | Recording begins |
| `audio_data` | `{"type":"audio_data","payload":{"b64":"base64-encoded-pcm..."}}` | While recording (continuous) |
| `audio_stop` | `{"type":"audio_stop","payload":{"duration_ms":5200}}` | Recording ends |

### App → Glasses

| Command | JSON | Effect |
|---|---|---|
| Vibrate | `{"type":"command","payload":{"action":"vibrate","pattern":"short_pulse"}}` | Buzzer beeps |
| Start recording | `{"type":"command","payload":{"action":"start_recording"}}` | Glasses begin streaming audio |
| Stop recording | `{"type":"command","payload":{"action":"stop_recording"}}` | Glasses stop streaming audio |
