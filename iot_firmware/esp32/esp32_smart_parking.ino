/**
 * Smart Parking Management System — ESP32 Smart Bay Node Firmware
 *
 * Microcontroller: ESP32-WROOM-32
 * Sensors:
 *   - HC-SR04 Ultrasonic Sensor (Trig/Echo) for Vehicle Proximity
 *   - QMC5883L / HMC5883L I2C Geomagnetic Magnetometer for Metallic Mass Detection
 *   - SG90 / MG996R Servo Motor for Barrier Gate Actuation
 *   - Bi-Color / NeoPixel LED (Green = Available, Red = Occupied)
 *
 * Transmits real-time occupancy events to Tomcat REST API: /api/iot-sensor
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>

// ==================== CONFIGURATION ====================
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Replace with your Laptop/Server IP running Apache Tomcat
const char* SERVER_URL    = "http://192.168.1.100:8080/smart-parking-system/api/iot-sensor";
const char* TARGET_SLOT_ID = "A1";

// Pinout Definitions (ESP32 GPIO)
#define PIN_TRIG        5     // Ultrasonic Trigger (Output)
#define PIN_ECHO        18    // Ultrasonic Echo (Input via 1k/2k resistor divider)
#define PIN_LED_GREEN   2     // Status LED: Green (Available)
#define PIN_LED_RED     4     // Status LED: Red (Occupied)
#define PIN_SERVO       19    // Barrier Gate PWM Servo Output

// Detection Thresholds
const float OCCUPIED_DISTANCE_CM = 50.0; // Distance below which a vehicle is parked
const int DEBOUNCE_CYCLES        = 3;    // Consecutive cycles required for state change
const unsigned long POLL_DELAY_MS = 2000; // Check frequency (2 seconds)

// State Tracking
bool isBayOccupied = false;
int consecutiveOccupiedCount = 0;
int consecutiveEmptyCount    = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n[ESP32] Smart Parking Bay Controller Initializing...");

  // Initialize GPIO Pins
  pinMode(PIN_TRIG, OUTPUT);
  pinMode(PIN_ECHO, INPUT);
  pinMode(PIN_LED_GREEN, OUTPUT);
  pinMode(PIN_LED_RED, OUTPUT);

  digitalWrite(PIN_TRIG, LOW);
  updateBayLED(false); // Initially show green

  // Initialize I2C for Geomagnetic Sensor
  Wire.begin(21, 22); // SDA=21, SCL=22
  Serial.println("[ESP32] I2C Bus Online (SDA:21, SCL:22)");

  // Connect to Wi-Fi
  connectToWiFi();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
  }

  // 1. Measure Ultrasonic Distance
  float distance = readUltrasonicDistance();
  Serial.printf("[Sensor] Measured Distance: %.1f cm\n", distance);

  // 2. Debounce and Filter State
  if (distance > 0 && distance < OCCUPIED_DISTANCE_CM) {
    consecutiveOccupiedCount++;
    consecutiveEmptyCount = 0;
  } else {
    consecutiveEmptyCount++;
    consecutiveOccupiedCount = 0;
  }

  // 3. Evaluate State Transition
  if (!isBayOccupied && consecutiveOccupiedCount >= DEBOUNCE_CYCLES) {
    isBayOccupied = true;
    updateBayLED(true);
    Serial.println("\n>>> VEHICLE ARRIVED: Bay Marked OCCUPIED <<<");
    sendSensorTelemetry(TARGET_SLOT_ID, "OCCUPIED", "ULTRASONIC", distance);
  } else if (isBayOccupied && consecutiveEmptyCount >= DEBOUNCE_CYCLES) {
    isBayOccupied = false;
    updateBayLED(false);
    Serial.println("\n>>> VEHICLE DEPARTED: Bay Restored to AVAILABLE <<<");
    sendSensorTelemetry(TARGET_SLOT_ID, "AVAILABLE", "ULTRASONIC", distance);
  }

  delay(POLL_DELAY_MS);
}

/**
 * Sends trigger pulse and computes distance from ultrasonic sound speed.
 */
float readUltrasonicDistance() {
  digitalWrite(PIN_TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(PIN_TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(PIN_TRIG, LOW);

  // Reads echo pulse width in microseconds (timeout 30ms ~ 5 meters max)
  long duration = pulseIn(PIN_ECHO, HIGH, 30000);
  if (duration == 0) return 999.0; // Out of range

  // Distance in cm = (duration * 0.0343) / 2
  return (duration * 0.0343) / 2.0;
}

/**
 * Updates physical status LED.
 */
void updateBayLED(bool occupied) {
  if (occupied) {
    digitalWrite(PIN_LED_GREEN, LOW);
    digitalWrite(PIN_LED_RED, HIGH);
  } else {
    digitalWrite(PIN_LED_GREEN, HIGH);
    digitalWrite(PIN_LED_RED, LOW);
  }
}

/**
 * Dispatches HTTP POST JSON telemetry to Smart Parking API Gateway.
 */
void sendSensorTelemetry(const char* slotId, const char* status, const char* sensorType, float distance) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[HTTP Error] Wi-Fi not connected. Telemetry dropped.");
    return;
  }

  HTTPClient http;
  http.begin(SERVER_URL);
  http.addHeader("Content-Type", "application/json");

  // Construct JSON payload
  String jsonPayload = "{";
  jsonPayload += "\"slotId\":\"" + String(slotId) + "\",";
  jsonPayload += "\"status\":\"" + String(status) + "\",";
  jsonPayload += "\"sensorType\":\"" + String(sensorType) + "\",";
  jsonPayload += "\"distanceCm\":" + String(distance, 1);
  jsonPayload += "}";

  Serial.println("[HTTP POST] Transmitting -> " + jsonPayload);
  int httpResponseCode = http.POST(jsonPayload);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.printf("[HTTP OK] Status: %d, Response: %s\n", httpResponseCode, response.c_str());
  } else {
    Serial.printf("[HTTP Error] Failed, error: %s\n", http.errorToString(httpResponseCode).c_str());
  }

  http.end();
}

/**
 * Wi-Fi connection handler with auto-retry.
 */
void connectToWiFi() {
  Serial.print("[Wi-Fi] Connecting to ");
  Serial.print(WIFI_SSID);

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[Wi-Fi Connected!]");
    Serial.print("[Wi-Fi] Assigned ESP32 IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[Wi-Fi Error] Failed to connect. Will retry during main loop.");
  }
}
