#!/usr/bin/env python3
"""
Smart Parking Management System — Raspberry Pi Gate Barrier & ANPR Camera Controller

Components:
  - Raspberry Pi 4 / 5 / Zero 2W
  - USB Webcam or Raspberry Pi Camera Module (v2 / v3)
  - HC-SR04 Ultrasonic Distance Sensor (Vehicle Arrival Detector)
  - SG90 / MG996R Servo Motor (Gate Boom Barrier Actuator)
  - Interfacing with Smart Parking REST API: /api/iot-sensor
"""

import os
import sys
import time
import json
import urllib.request
import urllib.parse
from pathlib import Path

# Add anpr_service to Python path
sys.path.append(str(Path(__file__).parent.parent.parent / "anpr_service"))
from anpr_pipeline import ANPRPipeline

# GPIO Hardware Setup (Only active on actual Raspberry Pi hardware)
try:
    import RPi.GPIO as GPIO
    HAS_RPI_HARDWARE = True
except ImportError:
    HAS_RPI_HARDWARE = False
    print("[WARN] RPi.GPIO not detected. Running in Raspberry Pi Emulation Mode.")

# Pin Configuration (BCM numbering)
PIN_TRIG  = 23  # Ultrasonic Trigger Pin
PIN_ECHO  = 24  # Ultrasonic Echo Pin (via 1k/2k voltage divider)
PIN_SERVO = 18  # Hardware PWM for Boom Barrier Servo

# System Settings
SERVER_URL = "http://192.168.1.100:8080/smart-parking-system/api/iot-sensor"
GATE_ZONE_ID = "A"
DEFAULT_SLOT_ID = "A1"
PROXIMITY_THRESHOLD_CM = 45.0  # Vehicle at gate distance threshold


class PiGateController:

    def __init__(self, server_url=SERVER_URL):
        self.server_url = server_url
        self.anpr = ANPRPipeline(backend_url=server_url)
        self.servo = None
        self._init_hardware()

    def _init_hardware(self):
        if HAS_RPI_HARDWARE:
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)
            GPIO.setup(PIN_TRIG, GPIO.OUT)
            GPIO.setup(PIN_ECHO, GPIO.IN)
            GPIO.setup(PIN_SERVO, GPIO.OUT)

            # 50Hz PWM for Servo (SG90 / MG996R)
            self.servo = GPIO.PWM(PIN_SERVO, 50)
            self.servo.start(2.5)  # 0 degrees: Barrier Closed
            print("[RPi] Hardware GPIO Initialized (Servo: GPIO18, Trig: 23, Echo: 24)")
        else:
            print("[RPi Emulator] Hardware GPIO virtualized.")

    def read_distance_cm(self):
        """Measures distance to approaching vehicle via HC-SR04 ultrasonic sensor."""
        if not HAS_RPI_HARDWARE:
            # Emulated proximity check
            return 30.0

        GPIO.output(PIN_TRIG, False)
        time.sleep(0.05)

        # 10us trigger pulse
        GPIO.output(PIN_TRIG, True)
        time.sleep(0.00001)
        GPIO.output(PIN_TRIG, False)

        pulse_start = time.time()
        pulse_end = time.time()

        timeout = time.time() + 0.04
        while GPIO.input(PIN_ECHO) == 0:
            pulse_start = time.time()
            if pulse_start > timeout:
                return 999.0

        while GPIO.input(PIN_ECHO) == 1:
            pulse_end = time.time()
            if pulse_end > timeout:
                return 999.0

        pulse_duration = pulse_end - pulse_start
        distance = pulse_duration * 17150
        return round(distance, 2)

    def set_barrier_angle(self, angle):
        """Controls boom barrier servo angle (0 deg = Closed/Horizontal, 90 deg = Open/Vertical)."""
        duty_cycle = 2.5 + (angle / 18.0)
        print(f"[Actuator] Setting Boom Barrier Angle: {angle}° (Duty: {duty_cycle:.1f}%)")
        if HAS_RPI_HARDWARE and self.servo:
            self.servo.ChangeDutyCycle(duty_cycle)
            time.sleep(0.4)
            self.servo.ChangeDutyCycle(0) # Stop PWM signal jitter
        else:
            print(f"[RPi Emulator] Barrier Arm: {'OPEN (Vertical)' if angle > 45 else 'CLOSED (Horizontal)'}")

    def capture_camera_frame(self, output_path="gate_capture.jpg"):
        """Captures frame from physical webcam or PiCamera."""
        try:
            import cv2
            cap = cv2.VideoCapture(0)
            if not cap.isOpened():
                print("[!] Could not open camera. Using synthetic plate for demonstration.")
                from anpr_pipeline import generate_synthetic_hsrp_plate
                return generate_synthetic_hsrp_plate("KA01AB1234", output_path)

            ret, frame = cap.read()
            cap.release()
            if ret:
                cv2.imwrite(output_path, frame)
                print(f"[Camera] Optical frame saved: {output_path}")
                return output_path
        except Exception as e:
            print(f"[Camera Error] {e}")

        from anpr_pipeline import generate_synthetic_hsrp_plate
        return generate_synthetic_hsrp_plate("KA01AB1234", output_path)

    def run_gate_loop(self):
        """Main loop monitoring approaching vehicles, scanning plates, and opening barrier."""
        print("==================================================")
        print(" Raspberry Pi Smart Parking Barrier Gate System  ")
        print("==================================================")
        print(f"Monitoring vehicle arrival zone... Target Server: {self.server_url}")

        try:
            while True:
                dist = self.read_distance_cm()
                if dist < PROXIMITY_THRESHOLD_CM:
                    print(f"\n[DETECTED] Vehicle detected at gate entry ({dist} cm)!")
                    time.sleep(0.5)

                    # 1. Snap camera photo
                    photo_path = self.capture_camera_frame("vehicle_at_gate.jpg")

                    # 2. Run ANPR OCR
                    plate = self.anpr.process_image_file(photo_path)
                    if not plate:
                        plate = "KA01AB1234" # Fallback if dark/obscured
                        print(f"[*] Fallback simulated plate: {plate}")

                    print(f"[ANPR] Extracted VRN: {plate}")

                    # 3. Transmit to backend
                    resp = self.anpr.send_to_backend(DEFAULT_SLOT_ID, plate)

                    # 4. If verified, open physical barrier
                    if resp and resp.get("success"):
                        print("\n>>> ACCESS GRANTED: Opening Barrier Arm <<<")
                        self.set_barrier_angle(90) # Open

                        print("[Gate] Holding open for 7 seconds for vehicle transit...")
                        time.sleep(7.0)

                        print(">>> Vehicle Cleared: Lowering Barrier Arm <<<")
                        self.set_barrier_angle(0)  # Close
                    else:
                        print("[Access Denied] Plate not registered or bay full.")

                    time.sleep(3.0)

                time.sleep(1.0)

        except KeyboardInterrupt:
            print("\n[RPi] Shutting down gate controller...")
        finally:
            if HAS_RPI_HARDWARE:
                if self.servo:
                    self.servo.stop()
                GPIO.cleanup()


if __name__ == "__main__":
    controller = PiGateController()
    controller.run_gate_loop()
