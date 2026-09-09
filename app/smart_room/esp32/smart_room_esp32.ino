/*
  Smart Room -- ESP32 Firmware

  Aufgabe: WLAN verbinden, einen WebSocket-Server öffnen und mit der
  Flutter-App über JSON kommunizieren (siehe lib/services/esp32_service.dart).

  Nachrichten-Protokoll (muss zur App passen):
  - ESP32 -> App (alle paar Sekunden):
      {"temperature": 22.5, "humidity": 45.0, "persons": 2, "airQuality": "Gut"}
  - App -> ESP32 (bei Knopfdruck):
      {"device": "light", "state": true}

  Benötigte Bibliotheken (über den Arduino Library Manager installieren):
  - "WebSockets" von Markus Sattler (Links2004)
  - "ArduinoJson" von Benoit Blanchon
  Für die echten Sensoren (aktuell auskommentiert, siehe unten):
  - "DHT sensor library" + "Adafruit Unified Sensor" (Temperatur/Luftfeuchtigkeit)

  WICHTIG: Da wir aktuell noch keine Sensoren zum Testen haben, sendet dieser
  Sketch simulierte Messwerte. Die echten Sensor-Aufrufe stehen weiter unten
  auskommentiert bereit -- sobald Hardware angeschlossen ist, einfach den
  jeweiligen Block einkommentieren und den simulierten Ersatz entfernen.
*/

#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

// // Für echte Temperatur-/Luftfeuchtigkeitsmessung (Hardware nötig):
// #include <DHT.h>
// #define DHT_PIN 4
// #define DHT_TYPE DHT22
// DHT dht(DHT_PIN, DHT_TYPE);

// --- WLAN-Zugangsdaten ---
const char *WIFI_SSID = "DEIN_WLAN_NAME";
const char *WIFI_PASSWORD = "DEIN_WLAN_PASSWORT";

// --- Pins für die Aktoren (Relais) ---
const int PIN_LIGHT = 16;
const int PIN_FAN = 17;
const int PIN_PARTY = 18;

WebSocketsServer webSocket = WebSocketsServer(81);

bool lightState = false;
bool fanState = false;
bool partyState = false;

unsigned long lastSensorSend = 0;
const unsigned long SENSOR_INTERVAL_MS = 5000;

void setup() {
  Serial.begin(115200);

  pinMode(PIN_LIGHT, OUTPUT);
  pinMode(PIN_FAN, OUTPUT);
  pinMode(PIN_PARTY, OUTPUT);

  // dht.begin(); // aktivieren, sobald der DHT-Sensor angeschlossen ist

  connectToWifi();

  webSocket.begin();
  webSocket.onEvent(onWebSocketEvent);
}

void loop() {
  webSocket.loop();

  unsigned long now = millis();
  if (now - lastSensorSend >= SENSOR_INTERVAL_MS) {
    lastSensorSend = now;
    sendSensorData();
  }
}

void connectToWifi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Verbinde mit WLAN");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.print("Verbunden, IP-Adresse: ");
  Serial.println(WiFi.localIP());
}

// Wird bei jeder eingehenden WebSocket-Nachricht (von der App) aufgerufen.
void onWebSocketEvent(uint8_t clientId, WStype_t type, uint8_t *payload, size_t length) {
  if (type != WStype_TEXT) return;

  JsonDocument doc;
  DeserializationError error = deserializeJson(doc, payload, length);
  if (error) return;

  String device = doc["device"] | "";
  bool state = doc["state"] | false;

  if (device == "light") {
    lightState = state;
    digitalWrite(PIN_LIGHT, lightState ? HIGH : LOW);
  } else if (device == "fan") {
    fanState = state;
    digitalWrite(PIN_FAN, fanState ? HIGH : LOW);
  } else if (device == "party") {
    partyState = state;
    digitalWrite(PIN_PARTY, partyState ? HIGH : LOW);
  }
}

// Baut die Sensor-Nachricht und schickt sie an alle verbundenen Clients.
void sendSensorData() {
  float temperature;
  float humidity;
  int persons;
  String airQuality;

  // --- Simulierte Werte (aktiv, solange keine Sensoren angeschlossen sind) ---
  temperature = 20.0 + (random(0, 80) / 10.0); // 20.0 - 28.0 °C
  humidity = 30.0 + (random(0, 400) / 10.0);   // 30.0 - 70.0 %
  persons = random(0, 5);
  airQuality = (temperature > 26) ? "Schlecht" : "Gut";

  // --- Echte Sensorwerte (einkommentieren, sobald Hardware angeschlossen ist) ---
  // temperature = dht.readTemperature();
  // humidity = dht.readHumidity();
  // persons = readPersonCountFromPirSensor(); // eigene Funktion, je nach Sensor
  // airQuality = readAirQualityFromMQ135();    // eigene Funktion, je nach Sensor

  JsonDocument doc;
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["persons"] = persons;
  doc["airQuality"] = airQuality;

  String json;
  serializeJson(doc, json);
  webSocket.broadcastTXT(json);
}
