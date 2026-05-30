/**
 * ESP32 Safety Glasses – WebSocket server
 *
 * Runs a WebSocket server on:8080 so the Ishara Flutter app can connect.
 * Sends JSON messages to the app:
 *   - sensor_update  : ultrasonic distance every 500 ms
 *   - event / sos    : SOS button pressed
 *   - audio_data     : base64-encoded 16-bit PCM chunks while recording
 *   - audio_start / audio_stop : recording state transitions
 *
 * Receives JSON commands from the app:
 *   - { "type":"command", "payload":{ "action":"vibrate", "pattern":"short_pulse" } }
 *   - { "type":"command", "payload":{ "action":"start_recording" } }
 *   - { "type":"command", "payload":{ "action":"stop_recording" } }
 *
 * Requires libraries (install via Arduino Library Manager):
 *   - arduinoWebSockets by Markus Sattler (Links2004)
 *   - ArduinoJson >= 7.x
 *   - ArduinoBase64 by Linar Yusupov  (provides base64::encode)
 */

#include <WiFi.h>
#include <WebSocketsServer.h>   // arduinoWebSockets by Links2004
#include <ArduinoJson.h>        // ArduinoJson >= 7.x
#include <driver/i2s.h>         // ESP32 legacy I2S driver (Arduino core 2.x)
#include <base64.h>             // ArduinoBase64 by Linar Yusupov

// ==================== CONFIGURATION ====================
// WiFi — set USE_AP_MODE to true to create the glasses' own network,
// or false to join an existing WiFi / phone hotspot.
const bool USE_AP_MODE = true;   // change to false to join existing WiFi

// Station mode credentials (only used when USE_AP_MODE = false)
const char* WIFI_SSID     = "Mohamed's Note10+";
const char* WIFI_PASSWORD = "themostpowerful";

// AP mode credentials (only used when USE_AP_MODE = true)
// Phone must join this network, then connect to 192.168.4.1:8080
const char* AP_SSID     = "Ishara-Glasses";
const char* AP_PASSWORD = "ishara1234";

// WebSocket server port (app connects to ws://<glasses-ip>:8080)
const int WS_PORT = 8080;

// Pins
#define PIN_TRIGGER       5
#define PIN_ECHO          18
#define PIN_BUZZER        23
#define PIN_SOS_BUTTON    4    // Active LOW (INPUT_PULLUP)
#define PIN_RECORD_BUTTON 2    // Active LOW (INPUT_PULLUP)

// INMP441 I2S Pins
#define I2S_SCK_PIN       33   // BCLK
#define I2S_WS_PIN        25   // LRCL
#define I2S_SD_PIN        32   // DOUT

// Audio settings
const int AUDIO_SAMPLE_RATE = 16000;
const int AUDIO_BIT_DEPTH   = 32;    // 24-bit data packed in 32-bit frame
const int AUDIO_BUFFER_SIZE = 512;   // DMA buffer length (samples)
const int STREAM_CHUNK_SIZE = 512;   // PCM int16 samples per WebSocket frame

// Ultrasonic proximity thresholds
const int ULTRASONIC_THRESHOLD_CM = 40;
const int BUZZER_MAX_DELAY_MS     = 500;
const int BUZZER_MIN_DELAY_MS     = 70;

// ==================== GLOBAL STATE ====================
WebSocketsServer ws(WS_PORT);

bool          isRecording         = false;
unsigned long recordStart         = 0;
unsigned long lastBeepMs          = 0;
int           currentBeepDelay    = BUZZER_MAX_DELAY_MS;
unsigned long lastSensorBroadcast = 0;

int16_t streamBuffer[STREAM_CHUNK_SIZE];
size_t  bufferPos = 0;

// ==================== FORWARD DECLARATIONS ====================
void connectToWiFi();
void initializeI2S();
void onWsEvent(uint8_t clientNum, WStype_t type, uint8_t* payload, size_t length);
void broadcast(const String& json);
void doVibrate(const char* pattern);
void triggerSOS();
long measureDistance();
void updateProximityBuzzer(long distance, unsigned long now);
void toggleRecording();
void startRecording();
void stopRecording();
void streamAudioChunk();

// ==================== HELPERS ====================
void broadcast(const String& json) {
  ws.broadcastTXT(json);
}

String sensorJson(long distCm) {
  return String("{\"type\":\"sensor_update\",\"payload\":{\"distance_cm\":") +
         String(distCm) + String(",\"timestamp\":") +
         String(millis()) + String("}}");
}

// ==================== WEBSOCKET EVENTS ====================
void onWsEvent(uint8_t clientNum, WStype_t type, uint8_t* payload, size_t length) {
  switch (type) {
    case WStype_CONNECTED:
      Serial.printf("[WS] Client %u connected\n", clientNum);
      break;
    case WStype_DISCONNECTED:
      Serial.printf("[WS] Client %u disconnected\n", clientNum);
      break;
    case WStype_TEXT: {
      // ArduinoJson 7.x: use JsonDocument instead of StaticJsonDocument
      JsonDocument doc;
      DeserializationError err = deserializeJson(doc, payload, length);
      if (err) break;
      const char* msgType = doc["type"] | "";
      if (strcmp(msgType, "command") == 0) {
        const char* action = doc["payload"]["action"] | "";
        if (strcmp(action, "vibrate") == 0) {
          const char* pattern = doc["payload"]["pattern"] | "short_pulse";
          doVibrate(pattern);
        } else if (strcmp(action, "start_recording") == 0) {
          startRecording();
        } else if (strcmp(action, "stop_recording") == 0) {
          stopRecording();
        }
      }
      break;
    }
    default:
      break;
  }
}

void doVibrate(const char* pattern) {
  if (strcmp(pattern, "long_pulse") == 0) {
    digitalWrite(PIN_BUZZER, HIGH); delay(400);
    digitalWrite(PIN_BUZZER, LOW);
  } else {
    // short_pulse default
    for (int i = 0; i < 2; i++) {
      digitalWrite(PIN_BUZZER, HIGH); delay(80);
      digitalWrite(PIN_BUZZER, LOW);  delay(80);
    }
  }
}

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n=== ESP32 Safety Glasses (WebSocket) ===");

  // Pins
  pinMode(PIN_TRIGGER,       OUTPUT);
  pinMode(PIN_ECHO,          INPUT);
  pinMode(PIN_BUZZER,        OUTPUT);
  pinMode(PIN_SOS_BUTTON,    INPUT_PULLUP);
  pinMode(PIN_RECORD_BUTTON, INPUT_PULLUP);
  digitalWrite(PIN_TRIGGER, LOW);
  digitalWrite(PIN_BUZZER,  LOW);

  // WiFi
  connectToWiFi();

  // I2S microphone
  initializeI2S();

  // Start WebSocket server
  ws.begin();
  ws.onEvent(onWsEvent);
  Serial.printf("WebSocket server started on port %d\n", WS_PORT);
  Serial.print("Connect from app: ws://");
  Serial.print(WiFi.localIP());
  Serial.printf(":%d\n", WS_PORT);
}

// ==================== MAIN LOOP ====================
void loop() {
  ws.loop();
  unsigned long now = millis();

  // 1. SOS button
  if (digitalRead(PIN_SOS_BUTTON) == LOW) {
    triggerSOS();
    delay(1000);  // debounce
  }

  // 2. Ultrasonic proximity sensing
  long distance = measureDistance();
  updateProximityBuzzer(distance, now);

  // Broadcast sensor reading every 500 ms
  if (now - lastSensorBroadcast >= 500UL && distance > 0) {
    broadcast(sensorJson(distance));
    lastSensorBroadcast = now;
  }

  // 3. Record button toggle (debounced edge detection)
  static bool lastBtn = true;  // HIGH = true (pull-up, not pressed)
  bool curBtn = (digitalRead(PIN_RECORD_BUTTON) == HIGH);
  if (lastBtn && !curBtn) {    // falling edge (button pressed)
    delay(50);                 // debounce
    if (digitalRead(PIN_RECORD_BUTTON) == LOW) {
      toggleRecording();
    }
  }
  lastBtn = curBtn;

  // 4. Stream audio if recording
  if (isRecording) {
    streamAudioChunk();
  }

  delay(5);
}

// ==================== ULTRASONIC ====================
long measureDistance() {
  digitalWrite(PIN_TRIGGER, LOW);
  delayMicroseconds(2);
  digitalWrite(PIN_TRIGGER, HIGH);
  delayMicroseconds(10);
  digitalWrite(PIN_TRIGGER, LOW);
  long dur = pulseIn(PIN_ECHO, HIGH, 30000UL);
  if (dur == 0) return -1;
  return (long)((dur * 0.0343f) / 2.0f);  // explicit cast: double → long
}

void updateProximityBuzzer(long distance, unsigned long now) {
  if (distance > 0 && distance <= ULTRASONIC_THRESHOLD_CM) {
    int d = (int)map(distance, 2L, (long)ULTRASONIC_THRESHOLD_CM,
                     (long)BUZZER_MIN_DELAY_MS, (long)BUZZER_MAX_DELAY_MS);
    currentBeepDelay = constrain(d, BUZZER_MIN_DELAY_MS, BUZZER_MAX_DELAY_MS);
    if (now - lastBeepMs >= (unsigned long)currentBeepDelay) {
      digitalWrite(PIN_BUZZER, HIGH); delay(50);
      digitalWrite(PIN_BUZZER, LOW);
      lastBeepMs = now;
    }
  } else {
    digitalWrite(PIN_BUZZER, LOW);
  }
}

// ==================== SOS ====================
void triggerSOS() {
  Serial.println("SOS BUTTON PRESSED");
  for (int i = 0; i < 5; i++) {
    digitalWrite(PIN_BUZZER, HIGH); delay(100);
    digitalWrite(PIN_BUZZER, LOW);  delay(100);
  }
  broadcast("{\"type\":\"event\",\"payload\":{\"event\":\"sos\",\"timestamp\":" +
            String(millis()) + "}}");
}

// ==================== AUDIO ====================
void initializeI2S() {
  Serial.println("Initializing I2S Microphone...");

  i2s_config_t i2sCfg = {};
  i2sCfg.mode              = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX);
  i2sCfg.sample_rate       = (uint32_t)AUDIO_SAMPLE_RATE;
  i2sCfg.bits_per_sample   = (i2s_bits_per_sample_t)AUDIO_BIT_DEPTH;
  i2sCfg.channel_format    = I2S_CHANNEL_FMT_ONLY_LEFT;
  i2sCfg.communication_format = I2S_COMM_FORMAT_STAND_I2S;
  i2sCfg.intr_alloc_flags  = ESP_INTR_FLAG_LEVEL1;
  i2sCfg.dma_buf_count     = 4;
  i2sCfg.dma_buf_len       = AUDIO_BUFFER_SIZE;
  i2sCfg.use_apll          = false;
  i2sCfg.tx_desc_auto_clear = false;
  i2sCfg.fixed_mclk        = 0;

  i2s_pin_config_t pinCfg = {};
  pinCfg.bck_io_num   = I2S_SCK_PIN;
  pinCfg.ws_io_num    = I2S_WS_PIN;
  pinCfg.data_out_num = I2S_PIN_NO_CHANGE;
  pinCfg.data_in_num  = I2S_SD_PIN;

  if (i2s_driver_install(I2S_NUM_0, &i2sCfg, 0, NULL) != ESP_OK) {
    Serial.println("I2S driver install failed");
    return;
  }
  if (i2s_set_pin(I2S_NUM_0, &pinCfg) != ESP_OK) {
    Serial.println("I2S pin config failed");
    return;
  }
  Serial.println("I2S Microphone initialized");
}

void toggleRecording() {
  isRecording ? stopRecording() : startRecording();
}

void startRecording() {
  if (isRecording) return;
  isRecording = true;
  recordStart = millis();
  bufferPos   = 0;
  for (int i = 0; i < 2; i++) {
    digitalWrite(PIN_BUZZER, HIGH); delay(100);
    digitalWrite(PIN_BUZZER, LOW);  delay(100);
  }
  broadcast("{\"type\":\"audio_start\",\"payload\":{\"sample_rate\":16000,\"bits\":16,\"channels\":1}}");
  Serial.println("Recording started - streaming audio to app");
}

void stopRecording() {
  if (!isRecording) return;
  isRecording = false;
  digitalWrite(PIN_BUZZER, HIGH); delay(300);
  digitalWrite(PIN_BUZZER, LOW);
  unsigned long elapsed = millis() - recordStart;
  broadcast("{\"type\":\"audio_stop\",\"payload\":{\"duration_ms\":" +
            String(elapsed) + "}}");
  Serial.printf("Recording stopped (%.1f s)\n", elapsed / 1000.0f);
}

void streamAudioChunk() {
  size_t  bytesRead = 0;
  int32_t rawBuf[AUDIO_BUFFER_SIZE];

  i2s_read(I2S_NUM_0, rawBuf, sizeof(rawBuf), &bytesRead, portMAX_DELAY);
  size_t samples = bytesRead / sizeof(int32_t);

  for (size_t i = 0; i < samples; i++) {
    // INMP441: 24-bit value left-justified in a 32-bit frame.
    // Right-shift 14 bits to get a centred 18-bit value, then keep 16 MSBs.
    streamBuffer[bufferPos++] = (int16_t)(rawBuf[i] >> 14);
    if (bufferPos >= (size_t)STREAM_CHUNK_SIZE) {
      String b64 = base64::encode(
        (uint8_t*)streamBuffer,
        (int)(bufferPos * sizeof(int16_t))
      );
      broadcast("{\"type\":\"audio_data\",\"payload\":{\"b64\":\"" + b64 + "\"}}");
      bufferPos = 0;
    }
  }
}

// ==================== NETWORK ====================
void connectToWiFi() {
  if (USE_AP_MODE) {
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID, AP_PASSWORD);
    delay(500);
    Serial.printf("AP mode - Network: %s  Password: %s\n", AP_SSID, AP_PASSWORD);
    Serial.printf("IP: %s\n", WiFi.softAPIP().toString().c_str());
    Serial.println("Connect your phone to this WiFi network first!");
    return;
  }

  // Station mode - join existing network
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(200);

  for (int retry = 0; retry < 3; retry++) {
    Serial.printf("Connecting to WiFi: %s (attempt %d/3)\n", WIFI_SSID, retry + 1);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 40) {
      delay(500);
      Serial.print(".");
      attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.printf("\nWiFi connected - IP: %s\n", WiFi.localIP().toString().c_str());
      return;
    }

    Serial.println("\nRetrying...");
    WiFi.disconnect();
    delay(1000);
  }

  // Fallback to AP mode
  Serial.println("WiFi failed - falling back to AP mode...");
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASSWORD);
  delay(500);
  Serial.printf("AP mode - Network: %s  Password: %s\n", AP_SSID, AP_PASSWORD);
  Serial.printf("IP: %s\n", WiFi.softAPIP().toString().c_str());
  Serial.println("Connect your phone to this WiFi network first!");
}
