# Smart Parking System — IoT Hardware & Sensor Wiring Guide

This guide provides complete circuit schematics, pin mappings, and step-by-step assembly instructions for integrating physical microcontrollers (ESP32), microcomputers (Raspberry Pi), ultrasonic sensors, geomagnetic sensors, and automatic barrier servos with the Smart Parking Management System.

---

## 🧰 1. Bill of Materials (BOM)

| Component | Quantity | Specification / Model | Purpose |
| :--- | :---: | :--- | :--- |
| **ESP32 Dev Board** | 1 | ESP32-WROOM-32 (30/38 pin) | Bay sensor microcontroller with built-in Wi-Fi |
| **Raspberry Pi** | 1 | RPi 4 / 5 / Zero 2W (with Raspberry Pi OS) | Entry gate controller & camera ANPR host |
| **Ultrasonic Sensor** | 2 | HC-SR04 (5V Operating Voltage) | Detects vehicle proximity in parking bay & gate |
| **Geomagnetic Sensor** | 1 | QMC5883L / HMC5883L (I2C 3.3V) | Detects vehicle metal mass disturbance |
| **Servo Motor** | 1 | TowerPro SG90 (9g) or MG996R | Physical barrier boom arm actuator |
| **USB / Pi Camera** | 1 | 1080p USB Webcam or PiCamera v2/v3 | License plate optical image capture |
| **Bi-Color LEDs** | 1 each | 5mm Diffused Red & Green LEDs | Real-time physical bay availability indicator |
| **Resistors** | 4 | 2x 220Ω (LEDs), 1x 1kΩ, 1x 2kΩ (Divider) | Current limiting & 5V to 3.3V logic protection |
| **External Power** | 1 | 5V 2A DC Power Supply / Breadboard Module | Prevents servo voltage dropouts on MCU |

---

## 🔌 2. ESP32 Circuit Schematic & Pin Mapping

### Pin Connection Table

| ESP32 Pin | Connected Component | Function / Notes |
| :--- | :--- | :--- |
| **VIN / 5V** | HC-SR04 `VCC`, Servo `VCC` | External 5V rail |
| **GND** | Sensor `GND`, LED Cathodes, Servo `GND` | Common Ground |
| **GPIO 5** | HC-SR04 `TRIG` | Trigger output pulse (10µs) |
| **GPIO 18** | HC-SR04 `ECHO` (via 1kΩ/2kΩ divider) | Safe 3.3V logic pulse input |
| **GPIO 2** | Green LED (via 220Ω resistor) | Bay Available Indicator |
| **GPIO 4** | Red LED (via 220Ω resistor) | Bay Occupied Indicator |
| **GPIO 19** | Servo Motor `PWM Signal` (Orange wire) | Barrier arm angle control |
| **GPIO 21** | QMC5883L `SDA` | I2C Data line |
| **GPIO 22** | QMC5883L `SCL` | I2C Clock line |

---

### ⚠️ Critical: HC-SR04 Voltage Divider Protection
The HC-SR04 operates at 5V and its `ECHO` pin outputs a 5V signal. However, ESP32 GPIO pins are **3.3V tolerant only**. To prevent damaging the ESP32, wire a simple voltage divider between the Echo pin and the ESP32:

```
HC-SR04 ECHO (5V)
       │
      [1kΩ Resistor]
       │
       ├───> Connected to ESP32 GPIO 18 (Safe 3.3V Level)
       │
      [2kΩ Resistor]
       │
      GND (Common Ground)
```

---

## 🍓 3. Raspberry Pi Gate Controller Pin Mapping

| Raspberry Pi Pin (BCM) | Physical Header Pin | Connected Component | Function |
| :--- | :---: | :--- | :--- |
| **5V (Power)** | Pin 2 / 4 | HC-SR04 `VCC` & External Servo VCC | 5V Power rail |
| **GND (Ground)** | Pin 6 / 9 / 14 | Sensor Ground & Servo Ground | Common Ground |
| **GPIO 23** | Pin 16 | HC-SR04 `TRIG` | Gate vehicle arrival trigger |
| **GPIO 24** | Pin 18 | HC-SR04 `ECHO` (via 1kΩ/2kΩ divider) | Pulse measurement |
| **GPIO 18** | Pin 12 (PWM0) | Servo Motor Signal (Orange) | Barrier gate actuation |
| **USB Port / CSI** | USB / CSI Ribbon | USB Webcam or PiCamera | ANPR camera feed |

---

## 💻 4. Firmware Flashing & Software Setup

### Step A: Flashing the ESP32
1. Install [Arduino IDE](https://www.arduino.cc/en/software).
2. Open **File > Preferences** and add the ESP32 board manager URL:
   `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. Go to **Tools > Board > Boards Manager**, search for `esp32` and install the package.
4. Open [`esp32_smart_parking.ino`](file:///C:/Users/LENOVO/smart-parking-system/iot_firmware/esp32/esp32_smart_parking.ino).
5. Edit line 18 & 19 with your Wi-Fi SSID, Password, and your computer's IP address:
   ```cpp
   const char* WIFI_SSID     = "MyHomeWiFi";
   const char* WIFI_PASSWORD = "Password123";
   const char* SERVER_URL    = "http://192.168.1.50:8080/smart-parking-system/api/iot-sensor";
   ```
6. Connect your ESP32 via Micro-USB, select the appropriate COM Port, and click **Upload** (Ctrl + U).
7. Open Serial Monitor at **115200 baud** to view real-time ultrasonic telemetry and Wi-Fi sync.

---

### Step B: Running the Raspberry Pi Gate Controller
1. On your Raspberry Pi terminal, clone or copy the project files.
2. Install Python dependencies:
   ```bash
   sudo apt update
   sudo apt install -y python3-opencv python3-pip python3-pil
   pip3 install -r anpr_service/requirements.txt
   ```
3. Run the gate barrier loop:
   ```bash
   python3 iot_firmware/raspberry_pi/pi_gate_controller.py
   ```
4. As a car drives up (within 45 cm):
   * The ultrasonic sensor triggers the optical camera.
   * The ANPR pipeline localizes the license plate and runs character recognition.
   * A check-in request is transmitted via HTTP to Tomcat.
   * The servo barrier raises automatically, allows passage, and lowers after 7 seconds.

---

## 📡 5. Testing Without Physical Hardware (Software Simulator)
If physical microcontrollers are not currently plugged in, the system provides full simulation parity:
1. **IoT Sensor REST API**:
   You can send simulated sensor pulses directly from PowerShell or cURL:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:8080/smart-parking-system/api/iot-sensor" -Method Post -Body @{ slotId="A1"; status="OCCUPIED"; sensorType="ULTRASONIC" }
   ```
2. **Interactive Web Camera Terminal**:
   Open [`http://localhost:8080/smart-parking-system/anpr.jsp`](http://localhost:8080/smart-parking-system/anpr.jsp) in your browser to test live optical scanning with your laptop webcam or vehicle photo uploads!
