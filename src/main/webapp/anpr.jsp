<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.parkingsystem.model.User" %>
<%
    User currentUser = (User) session.getAttribute("driverUser");
    if (currentUser == null) {
        currentUser = (User) session.getAttribute("user");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Simulated ANPR license plate camera scanner and IoT gate barrier demonstration terminal.">
    <title>SmartParking | ANPR Camera Scanner</title>
    <link rel="icon" type="image/svg+xml" href="<%= request.getContextPath() %>/resources/images/favicon.svg">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/resources/css/style.css">
    <style>
        .anpr-container {
            display: grid;
            grid-template-columns: 1.2fr 1fr;
            gap: 28px;
            margin-top: 24px;
        }
        @media (max-width: 900px) {
            .anpr-container { grid-template-columns: 1fr; }
        }
        .camera-card {
            background: #0f172a;
            border-radius: var(--border-radius-lg);
            padding: 20px;
            color: #ffffff;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
            position: relative;
            overflow: hidden;
        }
        .camera-viewport {
            width: 100%;
            height: 340px;
            background: #020617;
            border-radius: 12px;
            position: relative;
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: center;
            border: 2px dashed #334155;
        }
        .camera-video {
            width: 100%;
            height: 100%;
            object-fit: cover;
            display: none;
        }
        .camera-overlay {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 100%;
            pointer-events: none;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .anpr-crosshair {
            width: 70%;
            height: 90px;
            border: 2px solid rgba(16, 185, 129, 0.8);
            border-radius: 8px;
            position: relative;
            box-shadow: 0 0 20px rgba(16, 185, 129, 0.4);
        }
        .anpr-crosshair::before {
            content: "ALIGN LICENSE PLATE HERE";
            position: absolute;
            top: -24px;
            left: 50%;
            transform: translateX(-50%);
            font-size: 0.72rem;
            color: #10b981;
            font-weight: 800;
            letter-spacing: 1px;
            background: rgba(15, 23, 42, 0.8);
            padding: 2px 8px;
            border-radius: 4px;
        }
        .scan-radar {
            position: absolute;
            top: 0; left: 0; width: 100%; height: 3px;
            background: linear-gradient(90deg, transparent, #10b981, transparent);
            box-shadow: 0 0 12px #10b981;
            animation: radarSweep 2s ease-in-out infinite;
        }
        @keyframes radarSweep {
            0% { top: 10%; opacity: 0.4; }
            50% { top: 90%; opacity: 1; }
            100% { top: 10%; opacity: 0.4; }
        }
        /* Barrier Gate Graphic */
        .barrier-container {
            display: flex;
            align-items: center;
            gap: 16px;
            background: #ffffff;
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius-md);
            padding: 18px 22px;
            margin-top: 20px;
        }
        .barrier-pillar {
            width: 32px;
            height: 70px;
            background: #475569;
            border-radius: 6px 6px 0 0;
            position: relative;
        }
        .barrier-pivot {
            width: 16px;
            height: 16px;
            background: #f59e0b;
            border-radius: 50%;
            position: absolute;
            top: 10px;
            left: 8px;
        }
        .barrier-arm {
            width: 140px;
            height: 8px;
            background: repeating-linear-gradient(45deg, #dc2626, #dc2626 12px, #ffffff 12px, #ffffff 24px);
            border-radius: 4px;
            transform-origin: 8px 4px;
            transform: rotate(0deg);
            transition: transform 0.6s cubic-bezier(0.34, 1.56, 0.64, 1);
            position: absolute;
            top: 14px;
            left: 16px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.25);
        }
        .barrier-arm.open {
            transform: rotate(-65deg);
        }
        .status-pill {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 800;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .status-pill.closed { background: #fee2e2; color: #991b1b; }
        .status-pill.open { background: #dcfce7; color: #166534; }
    </style>
</head>
<body>

    <!-- Navigation -->
    <nav class="navbar">
        <a href="<%= request.getContextPath() %>/zones" class="navbar-brand">
            <div class="brand-icon">P</div>
            <span>SmartParking<span class="brand-tag">SYSTEM</span></span>
        </a>
        <ul class="nav-links">
            <li><a href="<%= request.getContextPath() %>/zones" class="nav-link">Parking Zones</a></li>
            <li><a href="<%= request.getContextPath() %>/booking?action=myBookings" class="nav-link">My Bookings</a></li>
            <li><a href="<%= request.getContextPath() %>/anpr.jsp" class="nav-link active">ANPR Gate Simulation</a></li>
        </ul>
        <div class="nav-actions">
            <% if (currentUser != null) { %>
                <div class="user-badge">
                    <div class="user-avatar"><%= currentUser.getName().substring(0, 1).toUpperCase() %></div>
                    <span><%= currentUser.getName() %></span>
                </div>
            <% } else { %>
                <a href="<%= request.getContextPath() %>/login" class="btn btn-secondary btn-sm">Sign In</a>
            <% } %>
        </div>
    </nav>

    <main class="container" style="max-width: 1100px;">
        <div style="margin-bottom: 20px; display: flex; justify-content: space-between; align-items: flex-end; flex-wrap: wrap; gap: 12px;">
            <div>
                <h1 style="font-size: 1.8rem; font-weight: 900; color: var(--color-primary); display: flex; align-items: center; gap: 10px;">
                    <span>📷</span> Simulated ANPR Camera &amp; Gate Barrier Terminal (Prototype Demo)
                </h1>
                <p style="color: var(--text-muted); font-size: 0.9rem; margin-top: 4px;">
                    Simulated optical number plate detection and automated barrier gate for academic demonstration.
                </p>
            </div>
            <a href="<%= request.getContextPath() %>/booking?action=myBookings" class="btn btn-secondary btn-sm">
                &larr; Back to My Bookings
            </a>
        </div>

        <div class="anpr-container">
            <!-- Left Column: Camera Viewport -->
            <div class="camera-card">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <span class="pulse-dot" style="background: #10b981;"></span>
                        <strong style="font-size: 0.92rem; letter-spacing: 0.5px;">ENTRANCE GATE CAMERA</strong>
                    </div>
                    <span style="font-size: 0.75rem; background: #1e293b; padding: 4px 10px; border-radius: 6px; color: #94a3b8;">
                        30 FPS
                    </span>
                </div>

                <div class="camera-viewport" id="viewport">
                    <video id="videoFeed" class="camera-video" autoplay playsinline muted></video>
                    <canvas id="snapshotCanvas" style="display: none;"></canvas>
                    <img id="staticPreview" alt="Uploaded vehicle plate preview" style="max-width: 100%; max-height: 100%; display: none; object-fit: contain;">

                    <div id="cameraPlaceholder" style="text-align: center; padding: 20px;">
                        <div style="font-size: 2.4rem; margin-bottom: 10px;">📷</div>
                        <div style="font-weight: 700; font-size: 1rem; color: #cbd5e1;">Live Camera Feed Offline</div>
                        <div style="font-size: 0.8rem; color: #64748b; margin-top: 4px;">
                            Click "Open Web Camera" or "Upload Plate Image" below to start scanning
                        </div>
                    </div>

                    <div class="camera-overlay" id="overlay" style="display: none;">
                        <div class="anpr-crosshair">
                            <div class="scan-radar"></div>
                        </div>
                    </div>
                </div>

                <!-- Camera Controls -->
                <div style="margin-top: 18px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
                    <button type="button" id="btnToggleCam" onclick="toggleWebcam()" class="btn btn-primary" style="background: #2563eb; border: none; font-weight: 700;">
                        <span>📹</span> Open Web Camera
                    </button>
                    <label class="btn btn-secondary" style="margin: 0; display: flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer; font-weight: 700;">
                        <span>📁</span> Upload Plate Image
                        <input type="file" id="fileUpload" accept="image/*" style="display: none;" onchange="handleFileUpload(event)">
                    </label>
                </div>

                <div style="margin-top: 10px; display: flex; gap: 8px;">
                    <button type="button" id="btnScanPlate" onclick="captureAndProcessANPR()" class="btn btn-primary btn-block" style="background: #059669; border: none; font-weight: 800; font-size: 1rem; padding: 12px;" disabled>
                        <span>📷</span> Scan Plate &amp; Check-In &rarr;
                    </button>
                </div>
            </div>

            <!-- Right Column: Recognition Result & Gate Controller -->
            <div>
                <!-- Barrier Box -->
                <div class="card" style="padding: 24px; margin-bottom: 20px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px;">
                        <span style="font-weight: 800; color: var(--color-primary); font-size: 0.95rem;">
                            🚧 ENTRANCE BOOM BARRIER
                        </span>
                        <span id="barrierStatusBadge" class="status-pill closed">
                            <span>🔴</span> Barrier Lowered (Closed)
                        </span>
                    </div>

                    <div class="barrier-container">
                        <div class="barrier-pillar">
                            <div class="barrier-pivot"></div>
                            <div id="barrierArm" class="barrier-arm"></div>
                        </div>
                        <div style="flex: 1; font-size: 0.82rem; color: var(--text-muted); line-height: 1.4;">
                            Controls entrance barrier arm via servo motor upon vehicle number plate verification.
                        </div>
                    </div>
                </div>

                <!-- Recognition Result Card -->
                <div class="card" style="padding: 24px;">
                    <h3 style="font-size: 1.1rem; font-weight: 800; color: var(--color-primary); margin-bottom: 16px;">
                        🎯 Live Recognition &amp; Allocation
                    </h3>

                    <div class="form-group" style="margin-bottom: 16px;">
                        <label class="form-label" for="targetSlotId">Target Parking Bay ID</label>
                        <input type="text" id="targetSlotId" class="form-control" value="A1" style="font-weight: 800; font-family: monospace;" required>
                    </div>

                    <div class="form-group" style="margin-bottom: 16px;">
                        <label class="form-label" for="manualPlateInput">Vehicle Plate Number (Manual Entry or Auto-Scan)</label>
                        <input type="text" id="manualPlateInput" class="form-control" value="KA01AB1234" placeholder="e.g. KA01AB1234" style="font-weight: 800; font-family: monospace; text-transform: uppercase;">
                    </div>

                    <div style="margin-bottom: 16px;">
                        <span class="form-label">Recognized License Plate (HSRP)</span>
                        <div class="hsrp-plate-preview" style="margin-top: 6px;">
                            <div class="hsrp-ind-badge">
                                <div class="hsrp-chakra"></div>
                                <span class="hsrp-ind-text">IND</span>
                            </div>
                            <div class="hsrp-vrn-text" id="anprVrnDisplay">WAITING FOR SCAN</div>
                        </div>
                    </div>

                    <div id="scanConsole" style="background: #0f172a; color: #10b981; font-family: monospace; font-size: 0.8rem; padding: 12px 14px; border-radius: 8px; min-height: 100px; max-height: 140px; overflow-y: auto;">
                        > ANPR Station Initialized.<br>
                        > Ready for camera snapshot or plate image upload...
                    </div>

                    <div id="successBanner" style="display: none; margin-top: 16px; background: #f0fdf4; border: 1.5px solid #86efac; border-radius: var(--border-radius-md); padding: 14px; color: #166534; font-size: 0.88rem;">
                        <strong>✓ Vehicle Checked-In:</strong> Bay is now <strong>OCCUPIED</strong>. Barrier open. Live parking meter started!
                    </div>
                    <div id="errorBanner" style="display: none; margin-top: 16px; background: #fef2f2; border: 1.5px solid #fca5a5; border-radius: var(--border-radius-md); padding: 14px; color: #991b1b; font-size: 0.88rem;">
                        <strong>⛔ Access Denied:</strong> <span id="errorMessageText">Entry rejected.</span>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script>
        let stream = null;
        const video = document.getElementById('videoFeed');
        const canvas = document.getElementById('snapshotCanvas');
        const placeholder = document.getElementById('cameraPlaceholder');
        const overlay = document.getElementById('overlay');
        const btnToggleCam = document.getElementById('btnToggleCam');
        const btnScan = document.getElementById('btnScanPlate');
        const consoleEl = document.getElementById('scanConsole');
        const barrierArm = document.getElementById('barrierArm');
        const barrierBadge = document.getElementById('barrierStatusBadge');
        const vrnDisplay = document.getElementById('anprVrnDisplay');
        const staticPreview = document.getElementById('staticPreview');

        function logConsole(msg) {
            consoleEl.innerHTML += '<br>> ' + msg;
            consoleEl.scrollTop = consoleEl.scrollHeight;
        }

        async function toggleWebcam() {
            if (stream) {
                // Stop camera
                stream.getTracks().forEach(track => track.stop());
                stream = null;
                video.style.display = 'none';
                overlay.style.display = 'none';
                placeholder.style.display = 'block';
                btnToggleCam.innerHTML = '<span>📹</span> Open Web Camera';
                btnScan.disabled = true;
                logConsole('Webcam stream disconnected.');
            } else {
                try {
                    logConsole('Requesting camera permissions (getUserMedia)...');
                    stream = await navigator.mediaDevices.getUserMedia({
                        video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } }
                    });
                    video.srcObject = stream;
                    video.style.display = 'block';
                    placeholder.style.display = 'none';
                    staticPreview.style.display = 'none';
                    overlay.style.display = 'flex';
                    btnToggleCam.innerHTML = '<span>⏹️</span> Stop Camera';
                    btnScan.disabled = false;
                    logConsole('Camera online. Video stream locked at 30 FPS.');
                } catch (err) {
                    logConsole('Camera access failed: ' + err.message);
                    alert('Camera could not be accessed. You can also use the "Upload Plate Image" option.');
                }
            }
        }

        function handleFileUpload(event) {
            const file = event.target.files[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = function(e) {
                if (stream) {
                    stream.getTracks().forEach(track => track.stop());
                    stream = null;
                    btnToggleCam.innerHTML = '<span>📹</span> Open Web Camera';
                }
                video.style.display = 'none';
                placeholder.style.display = 'none';
                overlay.style.display = 'flex';
                staticPreview.src = e.target.result;
                staticPreview.style.display = 'block';
                btnScan.disabled = false;
                logConsole('Loaded plate image file: ' + file.name + ' (' + Math.round(file.size / 1024) + ' KB)');
            };
            reader.readAsDataURL(file);
        }

        async function captureAndProcessANPR() {
            const slotId = document.getElementById('targetSlotId').value.trim().toUpperCase() || 'A1';
            logConsole('Capturing high-resolution optical frame...');

            let imageBlob = null;
            if (staticPreview.style.display === 'block') {
                // Image file uploaded
                imageBlob = staticPreview.src;
            } else {
                // Web camera snapshot
                canvas.width = video.videoWidth || 640;
                canvas.height = video.videoHeight || 480;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                imageBlob = canvas.toDataURL('image/jpeg');
            }

            logConsole('Processing frame and reading license plate...');
            btnScan.disabled = true;

            // Extract plate: Prioritize manual plate input if entered, otherwise sample or webcam
            const manualPlateVal = document.getElementById('manualPlateInput') ? document.getElementById('manualPlateInput').value.trim().toUpperCase() : '';
            let recognizedPlate = "";
            if (manualPlateVal) {
                recognizedPlate = manualPlateVal.replace(/[^A-Za-z0-9]/g, '');
            } else {
                const samplePlates = ['KA01AB1234', 'MH12DE5678', 'DL04C4321', 'HR26DQ5551', 'KA04EF1234'];
                recognizedPlate = samplePlates[Math.floor(Math.random() * samplePlates.length)];
            }

            setTimeout(async () => {
                vrnDisplay.textContent = recognizedPlate.replace(/(.{2})(.{2})(.{2})(.{4})/, '$1 $2 $3 $4');
                logConsole('Plate Recognized / Entered: ' + recognizedPlate);
                logConsole('Sending check-in request to /api/iot-sensor...');

                try {
                    const formData = new URLSearchParams();
                    formData.append('slotId', slotId);
                    formData.append('status', 'OCCUPIED');
                    formData.append('sensorType', 'ANPR_CAMERA');
                    formData.append('vehicleNumber', recognizedPlate);
                    formData.append('apiKey', 'DEMO_IOT_KEY_2026'); // Academic prototype API key

                    const resp = await fetch('<%= request.getContextPath() %>/api/iot-sensor', {
                        method: 'POST',
                        headers: { 
                            'Content-Type': 'application/x-www-form-urlencoded',
                            'X-API-KEY': 'DEMO_IOT_KEY_2026'
                        },
                        body: formData.toString()
                    });

                    const data = await resp.json();
                    logConsole('Server Response: ' + JSON.stringify(data));

                    if (resp.ok && data.success) {
                        // Actuate Physical Servo Barrier
                        barrierArm.classList.add('open');
                        barrierBadge.className = 'status-pill open';
                        barrierBadge.innerHTML = '<span>🟢</span> Barrier Open (Passed)';
                        document.getElementById('successBanner').style.display = 'block';
                        if (document.getElementById('errorBanner')) document.getElementById('errorBanner').style.display = 'none';

                        logConsole('✓ Gate authorized. Vehicle entering Bay ' + slotId);

                        setTimeout(() => {
                            barrierArm.classList.remove('open');
                            barrierBadge.className = 'status-pill closed';
                            barrierBadge.innerHTML = '<span>🔴</span> Barrier Lowered (Closed)';
                            logConsole('Vehicle passed. Barrier lowered.');
                        }, 6000);
                    } else {
                        // Access Denied / Entry Rejected
                        barrierArm.classList.remove('open');
                        barrierBadge.className = 'status-pill closed';
                        barrierBadge.innerHTML = '<span>🔴</span> Barrier Lowered (Access Denied)';
                        document.getElementById('successBanner').style.display = 'none';
                        const errMessage = data.error || data.message || 'Access Denied: Invalid reservation or unknown plate.';
                        if (document.getElementById('errorBanner')) {
                            document.getElementById('errorMessageText').textContent = errMessage;
                            document.getElementById('errorBanner').style.display = 'block';
                        }
                        logConsole('⛔ ACCESS REJECTED: ' + errMessage);
                    }

                } catch (e) {
                    logConsole('Network communication warning: ' + e.message);
                } finally {
                    btnScan.disabled = false;
                }
            }, 900);
        }
    </script>

        <!-- Standardized Academic Footer -->
    <footer class="footer" role="contentinfo">
        <div class="footer-container">
            <div>
                <div class="footer-brand">SmartParking</div>
                <div class="footer-sub">Smart Parking Management System • Academic Mini Project</div>
                <div class="footer-sub" style="margin-top: 4px;">Developed with Java 17, JSP, Servlets, JDBC & MySQL</div>
            </div>
            <div style="text-align: right;">
                <div class="footer-links" style="margin-bottom: 6px; justify-content: flex-end;">
                    <a href="<%= request.getContextPath() %>/privacy.jsp">Privacy Policy</a>
                    <a href="<%= request.getContextPath() %>/terms.jsp">Terms &amp; Conditions</a>
                    <a href="<%= request.getContextPath() %>/cookies.jsp">Cookie Policy</a>
                    <a href="<%= request.getContextPath() %>/refund.jsp">Refund Policy</a>
                </div>
                <div class="footer-sub">&copy; 2026 SmartParking. For Academic Demonstration.</div>
            </div>
        </div>
    </footer>

    <script src="<%= request.getContextPath() %>/resources/js/cookieConsent.js"></script>
</body>
</html>
