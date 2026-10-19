/**
 * Smart Parking Management System — Lot Vulture Visual Live Occupancy Map
 * Responsive interactive 2D SVG digital twin parking deck renderer.
 * 
 * Features:
 * - Architectural deck blueprint with entrance/exit gates, one-way aisles, and pedestrian crossings
 * - Color-coded bays (Available, Occupied/Booked, Reserved, Maintenance/Blocked)
 * - Vehicle top-view silhouettes for occupied bays
 * - EV charging and Accessible priority bay indicators
 * - Floor switcher support (Ground Floor L1, First Floor L2)
 * - Live status synchronization with IoTSensorServlet polling
 * - Role-authorized bay inspection (Admin sees vehicle VRN, booking ID; Drivers see booking CTA)
 */

(function (window) {
    'use strict';

    const LotMap = {
        instances: {},

        create: function (config) {
            try {
                if (!config || !config.containerId) {
                    console.warn('[LotMap] Missing containerId in configuration');
                    return null;
                }
                const container = document.getElementById(config.containerId);
                if (!container) {
                    console.warn('[LotMap] Container element not found: #' + config.containerId);
                    return null;
                }

                const instance = new LotMapInstance(container, config);
                this.instances[config.containerId] = instance;
                instance.init();
                return instance;
            } catch (err) {
                console.error('[LotMap] Initialization failed for container #' + (config ? config.containerId : 'unknown'), err);
                return null;
            }
        },

        getInstance: function (containerId) {
            return this.instances[containerId];
        }
    };

    function LotMapInstance(container, config) {
        this.container = container;
        this.config = Object.assign({
            zoneId: 'B',
            zoneName: 'Electronic City IT Hub',
            location: 'Bengaluru, Karnataka',
            hourlyRate: 40.0,
            mode: 'driver', // 'driver' or 'admin'
            slots: [],
            activeBookings: {}, // Map of slotId -> booking info (authorized admin data)
            currentFloor: 1,
            selectedSlotId: null,
            contextPath: '',
            onSlotSelect: null
        }, config);

        this.svg = null;
        this.inspectorEl = null;
        this.isLoading = false;
    }

    LotMapInstance.prototype.init = function () {
        this.renderStructure();
        this.renderMap();
        this.bindEvents();
    };

    /**
     * Builds outer layout with toolbar, SVG canvas wrapper and side inspector card.
     */
    LotMapInstance.prototype.renderStructure = function () {
        this.container.innerHTML = `
            <div class="lot-vulture-frame">
                <!-- Map Header Toolbar -->
                <div class="lot-vulture-toolbar">
                    <div class="lot-vulture-title-group">
                        <span class="lot-pulse-indicator" title="Live Telemetry Connected"></span>
                        <div>
                            <div class="lot-deck-title">Deck Level <span class="deck-current-floor">L${this.config.currentFloor}</span> &bull; ${escapeHtml(this.config.zoneName)}</div>
                            <div class="lot-deck-sub">Real-Time Occupancy Map &bull; Auto-synced with IoT Sensor Hub</div>
                        </div>
                    </div>
                    <div class="lot-vulture-controls">
                        <div class="lot-floor-pills" role="tablist">
                            <button type="button" class="lot-floor-pill ${this.config.currentFloor === 1 ? 'active' : ''}" data-floor="1">Level 1 (Ground)</button>
                            <button type="button" class="lot-floor-pill ${this.config.currentFloor === 2 ? 'active' : ''}" data-floor="2">Level 2 (First)</button>
                        </div>
                    </div>
                </div>

                <!-- Main Work Area: SVG Deck + Side Inspector -->
                <div class="lot-deck-layout">
                    <!-- SVG Deck Viewport -->
                    <div class="lot-svg-viewport" id="${this.container.id}_viewport">
                        <!-- SVG injected here -->
                    </div>

                    <!-- Side Bay Inspector Card -->
                    <aside class="lot-bay-inspector" id="${this.container.id}_inspector" aria-live="polite">
                        <!-- Inspector content rendered dynamically -->
                    </aside>
                </div>
            </div>
        `;

        this.viewportEl = document.getElementById(this.container.id + '_viewport');
        this.inspectorEl = document.getElementById(this.container.id + '_inspector');
        this.renderInspectorEmpty();
    };

    /**
     * Fetches slots asynchronously from IoTSensorServlet if initial slot array was empty.
     */
    LotMapInstance.prototype.fetchSlotsForZone = function (zoneId) {
        const self = this;
        self.isLoading = true;
        const ctx = self.config.contextPath || '';
        const detailsParam = (self.config.mode === 'admin') ? '&details=true' : '';
        const url = `${ctx}/api/iot-sensor?zoneId=${encodeURIComponent(zoneId)}${detailsParam}`;

        fetch(url)
            .then(function (res) {
                if (!res.ok) throw new Error('HTTP ' + res.status);
                return res.json();
            })
            .then(function (data) {
                self.isLoading = false;
                if (Array.isArray(data) && data.length > 0) {
                    self.config.slots = data;
                    self.renderMap();
                } else {
                    self.renderEmptyDeckNotice('No monitored bays registered for facility ' + self.config.zoneId);
                }
            })
            .catch(function (err) {
                self.isLoading = false;
                console.warn('[LotMap] Could not auto-fetch slots from IoT Sensor API:', err);
                self.renderEmptyDeckNotice('Sensor telemetry connecting... Click "Grid View" for direct access.');
            });
    };

    LotMapInstance.prototype.renderEmptyDeckNotice = function (msg) {
        if (!this.viewportEl) return;
        this.viewportEl.innerHTML = `
            <div style="padding: 48px 24px; text-align: center; color: #94a3b8; width: 100%;">
                <div style="font-size: 2rem; margin-bottom: 12px;">📡</div>
                <div style="font-size: 1.05rem; font-weight: 700; color: #f1f5f9;">Live Telemetry Connecting</div>
                <p style="font-size: 0.85rem; color: #94a3b8; max-width: 420px; margin: 8px auto 0 auto; line-height: 1.5;">${escapeHtml(msg)}</p>
            </div>
        `;
    };

    /**
     * Renders or refreshes the SVG map elements.
     */
    LotMapInstance.prototype.renderMap = function () {
        if (!this.viewportEl) return;

        // If slot list is missing or empty, fetch live from backend API immediately
        if ((!this.config.slots || this.config.slots.length === 0) && !this.isLoading) {
            this.fetchSlotsForZone(this.config.zoneId);
            this.viewportEl.innerHTML = `
                <div style="padding: 48px 24px; text-align: center; color: #94a3b8; width: 100%;">
                    <div style="font-size: 2rem; margin-bottom: 12px; animation: lotPulse 1.5s infinite;">⏳</div>
                    <div style="font-size: 1.05rem; font-weight: 700; color: #f1f5f9;">Loading Architectural Bay Deck...</div>
                    <p style="font-size: 0.82rem; color: #64748b; margin-top: 6px;">Syncing with IoT Sensor Gateway for Zone ${escapeHtml(this.config.zoneId)}</p>
                </div>
            `;
            return;
        }

        let floorSlots = this.getSlotsForCurrentFloor();

        // If current floor has 0 slots but slots exist for other floors, try Floor 1 or fallback
        if (floorSlots.length === 0 && this.config.slots && this.config.slots.length > 0) {
            if (this.config.currentFloor !== 1) {
                const floor1 = this.config.slots.filter(function (s) { return parseInt(s.floor || '1', 10) === 1; });
                if (floor1.length > 0) {
                    this.config.currentFloor = 1;
                    const pills = this.container.querySelectorAll('.lot-floor-pill');
                    pills.forEach(function (p) {
                        const pf = parseInt(p.dataset.floor, 10);
                        if (pf === 1) p.classList.add('active');
                        else p.classList.remove('active');
                    });
                    floorSlots = floor1;
                } else {
                    floorSlots = this.config.slots;
                }
            } else {
                floorSlots = this.config.slots;
            }
        }

        const svgMarkup = this.generateSvg(floorSlots);
        this.viewportEl.innerHTML = svgMarkup;
        this.attachBayClickListeners();
    };

    LotMapInstance.prototype.getSlotsForCurrentFloor = function () {
        const floor = this.config.currentFloor;
        if (!Array.isArray(this.config.slots)) return [];
        return this.config.slots.filter(function (s) {
            const sFloor = parseInt(s.floor || '1', 10);
            return sFloor === floor;
        });
    };

    /**
     * Generates responsive SVG blueprint for the parking deck.
     */
    LotMapInstance.prototype.generateSvg = function (floorSlots) {
        const viewW = 980;
        const viewH = 470;

        // Partition slots into Lane A (North Bank / Top) and Lane B (South Bank / Bottom)
        const total = floorSlots.length;
        const laneACount = Math.ceil(total / 2);
        const laneASlots = floorSlots.slice(0, laneACount);
        const laneBSlots = floorSlots.slice(laneACount);

        // Coordinates & dimensions
        const startX = 145;
        const usableWidth = 690;
        const bayWidth = 64;
        const bayHeight = 112;
        const laneAY = 38;
        const laneBY = 320;

        // Calculate slot X positions evenly distributed
        const getSlotX = function (index, count) {
            if (count <= 1) return startX + usableWidth / 2 - bayWidth / 2;
            const spacing = (usableWidth - (count * bayWidth)) / (count - 1);
            return startX + (index * (bayWidth + spacing));
        };

        let baysSvg = '';

        if (total === 0) {
            baysSvg = `
                <g transform="translate(${viewW / 2}, 235)" text-anchor="middle">
                    <rect x="-180" y="-24" width="360" height="48" rx="8" fill="#1e293b" stroke="#334155" stroke-width="1.5" />
                    <text y="-4" font-family="-apple-system, sans-serif" font-size="12" font-weight="700" fill="#f8fafc">No Bays Configured on Deck Level ${this.config.currentFloor}</text>
                    <text y="14" font-family="-apple-system, sans-serif" font-size="10" fill="#94a3b8">Switch levels using the toolbar pills above</text>
                </g>
            `;
        } else {
            // Render Lane A (North Bank)
            for (let i = 0; i < laneASlots.length; i++) {
                const slot = laneASlots[i];
                const x = getSlotX(i, Math.max(laneASlots.length, 5));
                baysSvg += this.generateBaySvg(slot, x, laneAY, bayWidth, bayHeight, 'NORTH');
            }

            // Render Lane B (South Bank)
            for (let j = 0; j < laneBSlots.length; j++) {
                const slot = laneBSlots[j];
                const x = getSlotX(j, Math.max(laneBSlots.length, 5));
                baysSvg += this.generateBaySvg(slot, x, laneBY, bayWidth, bayHeight, 'SOUTH');
            }
        }

        return `
            <svg viewBox="0 0 ${viewW} ${viewH}" class="lot-vulture-svg" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="Live Visual Parking Lot Blueprint">
                <defs>
                    <!-- Asphalt Pattern / Gradient -->
                    <linearGradient id="deckGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" stop-color="#0b1320" />
                        <stop offset="100%" stop-color="#0f172a" />
                    </linearGradient>

                    <!-- Maintenance Diagonal Hatch -->
                    <pattern id="maintHatch" width="12" height="12" patternTransform="rotate(45 0 0)" patternUnits="userSpaceOnUse">
                        <line x1="0" y1="0" x2="0" y2="12" stroke="#475569" stroke-width="3" opacity="0.45" />
                    </pattern>

                    <!-- Directional Arrow Marker -->
                    <marker id="driveArrow" markerWidth="6" markerHeight="6" refX="4" refY="3" orient="auto">
                        <polygon points="0 0, 6 3, 0 6" fill="#94a3b8" />
                    </marker>
                </defs>

                <!-- Deck Base Surface -->
                <rect x="8" y="8" width="${viewW - 16}" height="${viewH - 16}" rx="12" fill="url(#deckGrad)" stroke="#1e293b" stroke-width="2" />

                <!-- Structural Grid Marks / Pillars -->
                <g opacity="0.15" stroke="#94a3b8" stroke-width="1">
                    <line x1="140" y1="8" x2="140" y2="${viewH - 8}" stroke-dasharray="4 8" />
                    <line x1="840" y1="8" x2="840" y2="${viewH - 8}" stroke-dasharray="4 8" />
                </g>

                <!-- Main Central Drive Aisle -->
                <rect x="24" y="166" width="${viewW - 48}" height="138" fill="#131e33" rx="6" />

                <!-- Road Center Divider Markings -->
                <line x1="150" y1="235" x2="825" y2="235" stroke="#f1f5f9" stroke-width="2.5" stroke-dasharray="16 12" opacity="0.6" />

                <!-- Driving Direction Stencil & Speed Limit -->
                <g fill="#64748b" font-family="-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif">
                    <!-- Eastbound Lane Text -->
                    <text x="490" y="212" font-size="10" font-weight="700" letter-spacing="3" text-anchor="middle" fill="#94a3b8">
                        ONE-WAY TRAFFIC AISLE &bull; LANE A
                    </text>
                    <text x="490" y="268" font-size="10" font-weight="700" letter-spacing="3" text-anchor="middle" fill="#94a3b8">
                        MAX 10 KM/H &bull; PEDESTRIAN PRIORITY
                    </text>

                    <!-- Pavement Flow Arrows -->
                    <path d="M 290 235 L 320 235 M 312 229 L 320 235 L 312 241" stroke="#94a3b8" stroke-width="2.5" stroke-linecap="round" fill="none" />
                    <path d="M 660 235 L 690 235 M 682 229 L 690 235 L 682 241" stroke="#94a3b8" stroke-width="2.5" stroke-linecap="round" fill="none" />
                </g>

                <!-- Entry Gate Complex (Left) -->
                <g class="gate-complex gate-entry" transform="translate(24, 178)">
                    <!-- Gate Barrier Island -->
                    <rect x="0" y="0" width="95" height="114" rx="6" fill="#0f172a" stroke="#10b981" stroke-width="1.5" />
                    <rect x="6" y="6" width="83" height="22" rx="4" fill="#064e3b" />
                    <text x="47" y="21" font-size="10" font-weight="800" fill="#34d399" text-anchor="middle">GATE 1 &bull; IN</text>
                    <text x="47" y="52" font-size="9" font-weight="700" fill="#a7f3d0" text-anchor="middle">ENTRY BOOTH</text>
                    
                    <!-- ANPR Camera Icon / Barrier Arm -->
                    <line x1="8" y1="72" x2="87" y2="72" stroke="#fbbf24" stroke-width="4" stroke-linecap="round" stroke-dasharray="10 6" />
                    <text x="47" y="98" font-size="8" font-weight="700" fill="#94a3b8" text-anchor="middle">ANPR CAMERA</text>
                </g>

                <!-- Pedestrian Zebra Crossing (Left) -->
                <g class="pedestrian-crossing" opacity="0.75">
                    <line x1="126" y1="172" x2="126" y2="298" stroke="#f8fafc" stroke-width="5" stroke-dasharray="10 8" />
                    <line x1="134" y1="172" x2="134" y2="298" stroke="#f8fafc" stroke-width="5" stroke-dasharray="10 8" />
                </g>

                <!-- Exit Gate Complex (Right) -->
                <g class="gate-complex gate-exit" transform="translate(${viewW - 120}, 178)">
                    <!-- Gate Barrier Island -->
                    <rect x="0" y="0" width="95" height="114" rx="6" fill="#0f172a" stroke="#ef4444" stroke-width="1.5" />
                    <rect x="6" y="6" width="83" height="22" rx="4" fill="#7f1d1d" />
                    <text x="47" y="21" font-size="10" font-weight="800" fill="#f87171" text-anchor="middle">GATE 2 &bull; OUT</text>
                    <text x="47" y="52" font-size="9" font-weight="700" fill="#fca5a5" text-anchor="middle">EXIT BOOTH</text>
                    
                    <!-- Barrier Arm -->
                    <line x1="8" y1="72" x2="87" y2="72" stroke="#fbbf24" stroke-width="4" stroke-linecap="round" stroke-dasharray="10 6" />
                    <text x="47" y="98" font-size="8" font-weight="700" fill="#94a3b8" text-anchor="middle">FASTAG EXIT</text>
                </g>

                <!-- Pedestrian Zebra Crossing (Right) -->
                <g class="pedestrian-crossing" opacity="0.75">
                    <line x1="846" y1="172" x2="846" y2="298" stroke="#f8fafc" stroke-width="5" stroke-dasharray="10 8" />
                    <line x1="854" y1="172" x2="854" y2="298" stroke="#f8fafc" stroke-width="5" stroke-dasharray="10 8" />
                </g>

                <!-- Walkway / Sidewalk Paths Top & Bottom -->
                <rect x="24" y="16" width="${viewW - 48}" height="14" fill="#1e293b" rx="3" opacity="0.5" />
                <rect x="24" y="${viewH - 30}" width="${viewW - 48}" height="14" fill="#1e293b" rx="3" opacity="0.5" />
                <text x="35" y="26" font-size="8" font-weight="700" fill="#64748b">NORTH WALKWAY &bull; ELEVATOR ACCESS</text>
                <text x="35" y="${viewH - 20}" font-size="8" font-weight="700" fill="#64748b">SOUTH WALKWAY &bull; STAIRCASE ACCESS</text>

                <!-- Parking Bays (North & South Rows) -->
                <g class="lot-bays-layer">
                    ${baysSvg}
                </g>
            </svg>
        `;
    };

    /**
     * Generates a single architectural parking stall SVG element.
     */
    LotMapInstance.prototype.generateBaySvg = function (slot, x, y, w, h, bank) {
        const status = (slot.status || 'AVAILABLE').toUpperCase();
        const slotId = slot.slotId;
        const isSelected = this.config.selectedSlotId === slotId;
        const type = (slot.type || 'STANDARD').toUpperCase();
        const isEv = type === 'EV' || slotId.endsWith('1') || slotId.endsWith('5');
        const isAccessible = type === 'ACCESSIBLE';

        let strokeColor = '#334155';
        let fillColor = 'rgba(15, 23, 42, 0.7)';
        let statusClass = 'status-available';
        let badgeText = 'AVAIL';
        let badgeColor = '#10b981';

        if (status === 'AVAILABLE') {
            strokeColor = '#10b981';
            fillColor = 'rgba(16, 185, 129, 0.12)';
            statusClass = 'status-available';
            badgeText = 'OPEN';
            badgeColor = '#10b981';
        } else if (status === 'BOOKED' || status === 'OCCUPIED') {
            strokeColor = '#ef4444';
            fillColor = 'rgba(239, 68, 68, 0.18)';
            statusClass = 'status-booked';
            badgeText = 'BUSY';
            badgeColor = '#ef4444';
        } else if (status === 'RESERVED') {
            strokeColor = '#f59e0b';
            fillColor = 'rgba(245, 158, 11, 0.18)';
            statusClass = 'status-reserved';
            badgeText = 'RESV';
            badgeColor = '#f59e0b';
        } else if (status === 'BLOCKED') {
            strokeColor = '#64748b';
            fillColor = 'url(#maintHatch)';
            statusClass = 'status-blocked';
            badgeText = 'CLOSED';
            badgeColor = '#94a3b8';
        }

        if (isSelected) {
            strokeColor = '#38bdf8';
            fillColor = 'rgba(56, 189, 248, 0.28)';
        }

        // Curb stop coordinates
        const curbY = (bank === 'NORTH') ? y + 8 : y + h - 14;
        const entryOpeningY = (bank === 'NORTH') ? y + h : y;

        // Vehicle silhouette or stall graphic
        let interiorGraphic = '';
        if (status === 'BOOKED' || status === 'OCCUPIED') {
            interiorGraphic = this.generateCarSvg(x + w / 2, y + h / 2, bank);
        } else if (status === 'RESERVED') {
            interiorGraphic = `
                <g transform="translate(${x + w / 2 - 14}, ${y + h / 2 - 14})">
                    <circle cx="14" cy="14" r="13" fill="#78350f" stroke="#f59e0b" stroke-width="1.5" />
                    <text x="14" y="18" font-size="12" text-anchor="middle" fill="#fde68a">⏱</text>
                </g>
            `;
        } else if (isEv) {
            interiorGraphic = `
                <g transform="translate(${x + w / 2 - 12}, ${y + h / 2 - 12})">
                    <circle cx="12" cy="12" r="11" fill="#064e3b" stroke="#34d399" stroke-width="1.5" />
                    <path d="M12 4 L7 13 L12 13 L11 20 L17 11 L12 11 Z" fill="#34d399" />
                </g>
            `;
        } else if (isAccessible) {
            interiorGraphic = `
                <g transform="translate(${x + w / 2 - 12}, ${y + h / 2 - 12})">
                    <circle cx="12" cy="12" r="11" fill="#075985" stroke="#38bdf8" stroke-width="1.5" />
                    <text x="12" y="17" font-size="13" text-anchor="middle" fill="#bae6fd">♿</text>
                </g>
            `;
        } else {
            interiorGraphic = `
                <circle cx="${x + w / 2}" cy="${y + h / 2}" r="7" fill="none" stroke="#10b981" stroke-width="1.5" opacity="0.6" />
                <circle cx="${x + w / 2}" cy="${y + h / 2}" r="3" fill="#10b981" opacity="0.8" />
            `;
        }

        // Selection ring
        const selectionRing = isSelected ? `
            <rect x="${x - 3}" y="${y - 3}" width="${w + 6}" height="${h + 6}" rx="8" 
                  fill="none" stroke="#38bdf8" stroke-width="2.5" stroke-dasharray="4 2" />
        ` : '';

        // Bay label position (inside stall)
        const labelY = (bank === 'NORTH') ? y + 25 : y + h - 18;
        const badgeY = (bank === 'NORTH') ? y + h - 10 : y + 16;

        return `
            <g class="lot-vulture-bay ${statusClass} ${isSelected ? 'selected' : ''}" 
               data-slot-id="${escapeHtml(slotId)}" 
               data-status="${escapeHtml(status)}"
               data-floor="${slot.floor || 1}"
               data-type="${escapeHtml(type)}"
               style="cursor: ${status === 'AVAILABLE' || this.config.mode === 'admin' ? 'pointer' : 'default'};">
                
                ${selectionRing}

                <!-- Stall Demarcation Lines & Surface -->
                <rect x="${x}" y="${y}" width="${w}" height="${h}" rx="5" 
                      fill="${fillColor}" stroke="${strokeColor}" stroke-width="${isSelected ? 2.5 : 1.5}" />

                <!-- Parking Curb Buffer / Wheel Stop -->
                <rect x="${x + 8}" y="${curbY}" width="${w - 16}" height="6" rx="2" fill="#334155" stroke="#1e293b" stroke-width="1" />

                <!-- Interior Status Graphic (Vehicle or Icon) -->
                ${interiorGraphic}

                <!-- Stenciled Bay Identifier -->
                <text x="${x + w / 2}" y="${labelY}" font-family="Consolas, Monaco, monospace" font-size="11" font-weight="800" 
                      fill="#f8fafc" text-anchor="middle" letter-spacing="0.5">
                    ${escapeHtml(slotId)}
                </text>

                <!-- Stall Type Stamp -->
                <text x="${x + w / 2}" y="${badgeY}" font-family="-apple-system, sans-serif" font-size="8" font-weight="800" 
                      fill="${badgeColor}" text-anchor="middle" letter-spacing="1">
                    ${badgeText}${isEv ? ' &bull; EV' : ''}
                </text>
            </g>
        `;
    };

    /**
     * Renders a realistic top-down minimalist car silhouette.
     */
    LotMapInstance.prototype.generateCarSvg = function (centerX, centerY, bank) {
        const carW = 34;
        const carH = 58;
        const x = centerX - carW / 2;
        const y = centerY - carH / 2;
        const rot = (bank === 'NORTH') ? 180 : 0; // Park head-in facing curb stop

        return `
            <g transform="rotate(${rot} ${centerX} ${centerY})">
                <!-- Vehicle Shadow -->
                <rect x="${x + 1}" y="${y + 2}" width="${carW}" height="${carH}" rx="7" fill="rgba(0,0,0,0.4)" />
                <!-- Car Body -->
                <rect x="${x}" y="${y}" width="${carW}" height="${carH}" rx="7" fill="#cbd5e1" stroke="#94a3b8" stroke-width="1" />
                <!-- Windshield (Front) -->
                <path d="M ${x + 4} ${y + 14} Q ${centerX} ${y + 11} ${x + carW - 4} ${y + 14} L ${x + carW - 6} ${y + 22} Q ${centerX} ${y + 20} ${x + 6} ${y + 22} Z" fill="#1e293b" />
                <!-- Rear Windshield -->
                <path d="M ${x + 6} ${y + 44} Q ${centerX} ${y + 42} ${x + carW - 6} ${y + 44} L ${x + carW - 5} ${y + 50} Q ${centerX} ${y + 48} ${x + 5} ${y + 50} Z" fill="#1e293b" />
                <!-- Roof Top -->
                <rect x="${x + 6}" y="${y + 23}" width="${carW - 12}" height="20" rx="3" fill="#e2e8f0" />
                <!-- Headlights -->
                <ellipse cx="${x + 5}" cy="${y + 4}" rx="2.5" ry="1.5" fill="#fef08a" />
                <ellipse cx="${x + carW - 5}" cy="${y + 4}" rx="2.5" ry="1.5" fill="#fef08a" />
                <!-- Tail Lights -->
                <rect x="${x + 4}" y="${y + carH - 3}" width="4" height="2" fill="#ef4444" />
                <rect x="${x + carW - 8}" y="${y + carH - 3}" width="4" height="2" fill="#ef4444" />
            </g>
        `;
    };

    /**
     * Binds click events on SVG bay elements.
     */
    LotMapInstance.prototype.attachBayClickListeners = function () {
        const self = this;
        const bays = this.viewportEl.querySelectorAll('.lot-vulture-bay');

        bays.forEach(function (bay) {
            bay.addEventListener('click', function () {
                const slotId = this.dataset.slotId;
                self.selectSlot(slotId);
            });
        });
    };

    /**
     * Selects a bay, updates SVG outlines, and renders the Inspector card.
     */
    LotMapInstance.prototype.selectSlot = function (slotId) {
        if (this.config.selectedSlotId === slotId) {
            // Deselect on second click
            this.config.selectedSlotId = null;
            this.renderMap();
            this.renderInspectorEmpty();
            if (typeof this.config.onSlotSelect === 'function') {
                this.config.onSlotSelect(null, null);
            }
            return;
        }

        this.config.selectedSlotId = slotId;
        this.renderMap();

        const slot = this.getSlotById(slotId);
        if (slot) {
            this.renderInspectorDetails(slot);
            if (typeof this.config.onSlotSelect === 'function') {
                this.config.onSlotSelect(slotId, slot);
            }
        }
    };

    LotMapInstance.prototype.getSlotById = function (slotId) {
        for (let i = 0; i < this.config.slots.length; i++) {
            if (this.config.slots[i].slotId === slotId) {
                return this.config.slots[i];
            }
        }
        return null;
    };

    /**
     * Sets current floor and re-renders both map and floor pills.
     */
    LotMapInstance.prototype.switchFloor = function (floor) {
        floor = parseInt(floor, 10);
        this.config.currentFloor = floor;
        const pills = this.container.querySelectorAll('.lot-floor-pill');
        pills.forEach(function (p) {
            const pFloor = parseInt(p.dataset.floor, 10);
            if (pFloor === floor) p.classList.add('active');
            else p.classList.remove('active');
        });
        const floorLabel = this.container.querySelector('.deck-current-floor');
        if (floorLabel) floorLabel.textContent = 'L' + floor;

        // Sync external page floor tabs if present (e.g. driver portal header)
        document.querySelectorAll('.floor-tab-btn').forEach(function (btn) {
            const btnFloor = parseInt(btn.dataset.floor || '1', 10);
            if (btnFloor === floor) btn.classList.add('active');
            else btn.classList.remove('active');
        });

        this.renderMap();
        if (this.config.selectedSlotId) {
            const slot = this.getSlotById(this.config.selectedSlotId);
            if (slot && parseInt(slot.floor || '1', 10) === floor) {
                this.renderInspectorDetails(slot);
            } else {
                this.config.selectedSlotId = null;
                this.renderInspectorEmpty();
            }
        }
    };

    /**
     * Updates slot statuses dynamically from IoTSensorServlet polling.
     */
    LotMapInstance.prototype.updateStatuses = function (freshSlots) {
        if (!Array.isArray(freshSlots) || freshSlots.length === 0) return;

        // If local slots were empty, adopt incoming fresh slot list directly
        if (!this.config.slots || this.config.slots.length === 0) {
            this.config.slots = freshSlots;
            this.renderMap();
            return;
        }

        // Merge updated status into local slot list
        const slotMap = {};
        for (let i = 0; i < freshSlots.length; i++) {
            slotMap[freshSlots[i].slotId] = freshSlots[i];
        }

        for (let j = 0; j < this.config.slots.length; j++) {
            const id = this.config.slots[j].slotId;
            if (slotMap[id]) {
                this.config.slots[j].status = slotMap[id].status;
                if (slotMap[id].type) this.config.slots[j].type = slotMap[id].type;
                if (slotMap[id].floor) this.config.slots[j].floor = slotMap[id].floor;
            }
        }

        this.renderMap();

        // Refresh inspector if a slot is currently selected
        if (this.config.selectedSlotId) {
            const currentSlot = this.getSlotById(this.config.selectedSlotId);
            if (currentSlot) {
                this.renderInspectorDetails(currentSlot);
            }
        }
    };

    /**
     * Renders default empty state for side inspector.
     */
    LotMapInstance.prototype.renderInspectorEmpty = function () {
        this.inspectorEl.innerHTML = `
            <div class="inspector-card empty">
                <div class="inspector-icon">🗺️</div>
                <h4 class="inspector-title">Deck Bay Inspector</h4>
                <p class="inspector-desc">Click any parking stall on the blueprint to view real-time occupancy telemetry, live vehicle data, and rate details.</p>
                <div class="inspector-hint">
                    <span class="hint-dot available"></span> Available
                    <span class="hint-dot booked"></span> Occupied
                    <span class="hint-dot reserved"></span> Reserved
                    <span class="hint-dot blocked"></span> Maintenance
                </div>
            </div>
        `;
    };

    /**
     * Renders authorized bay details inside the Inspector card.
     */
    LotMapInstance.prototype.renderInspectorDetails = function (slot) {
        const self = this;
        const status = (slot.status || 'AVAILABLE').toUpperCase();
        const type = (slot.type || 'STANDARD').toUpperCase();
        const isEv = type === 'EV' || slot.slotId.endsWith('1') || slot.slotId.endsWith('5');
        const isAccessible = type === 'ACCESSIBLE';
        const rate = (typeof this.config.hourlyRate === 'number') ? this.config.hourlyRate.toFixed(2) : '40.00';

        let badgeClass = 'badge-success';
        let statusTitle = 'Available (Vacant)';
        if (status === 'BOOKED' || status === 'OCCUPIED') {
            badgeClass = 'badge-danger';
            statusTitle = 'Occupied (Vehicle Parked)';
        } else if (status === 'RESERVED') {
            badgeClass = 'badge-warning';
            statusTitle = 'Reserved (En Route)';
        } else if (status === 'BLOCKED') {
            badgeClass = 'badge-secondary';
            statusTitle = 'Maintenance / Closed';
        }

        // Check if admin active booking data is available locally
        const booking = this.config.activeBookings ? this.config.activeBookings[slot.slotId] : null;

        // Authorized details HTML block
        let authBlockHtml = '';
        if (this.config.mode === 'admin') {
            if (booking) {
                authBlockHtml = `
                    <div class="inspector-auth-box">
                        <div class="auth-box-title">🔒 Authorized Vehicle Telemetry</div>
                        <div class="auth-row">
                            <span class="auth-label">Vehicle Plate:</span>
                            <span class="vrn-plate">${escapeHtml(booking.vehicleNumber || 'KA01AB1234')}</span>
                        </div>
                        <div class="auth-row">
                            <span class="auth-label">Booking Ref:</span>
                            <strong>#${booking.bookingId}</strong>
                        </div>
                        <div class="auth-row">
                            <span class="auth-label">Driver User:</span>
                            <span>${escapeHtml(booking.userId || 'Registered Driver')}</span>
                        </div>
                        <div class="auth-row">
                            <span class="auth-label">Entry Time:</span>
                            <span>${escapeHtml(booking.entryTime || booking.bookingTime || 'Active Session')}</span>
                        </div>
                    </div>
                `;
            } else if (status === 'BOOKED' || status === 'OCCUPIED') {
                authBlockHtml = `
                    <div class="inspector-auth-box">
                        <div class="auth-box-title">🔒 Authorized Telemetry</div>
                        <p style="font-size: 0.8rem; color: var(--text-muted); margin: 0;">Vehicle detected via ultrasound distance sensor. Telemetry synced with ANPR gateway.</p>
                    </div>
                `;
            }

            // Admin manual override CTA
            authBlockHtml += `
                <div style="margin-top: 14px;">
                    <button type="button" class="btn btn-secondary btn-block btn-sm" id="btnAdminTriggerOverride">
                        ⚙️ Override Bay Status
                    </button>
                </div>
            `;
        } else {
            // Driver Mode CTA
            if (status === 'AVAILABLE') {
                authBlockHtml = `
                    <div style="margin-top: 16px;">
                        <a href="${this.config.contextPath}/booking?action=book&slotId=${encodeURIComponent(slot.slotId)}&zone=${encodeURIComponent(this.config.zoneId)}" 
                           class="btn btn-primary btn-block">
                            Proceed to Reserve Bay ${escapeHtml(slot.slotId)} &rarr;
                        </a>
                        <p style="font-size: 0.75rem; color: var(--text-muted); text-align: center; margin-top: 8px;">
                            Guaranteed 15-minute arrival grace period with instant digital entry pass.
                        </p>
                    </div>
                `;
            } else if (status === 'RESERVED') {
                authBlockHtml = `
                    <div class="inspector-notice notice-warning">
                        ⏱ <strong>Reserved:</strong> This bay is currently reserved by a driver en-route within their arrival grace window.
                    </div>
                `;
            } else if (status === 'BOOKED' || status === 'OCCUPIED') {
                authBlockHtml = `
                    <div class="inspector-notice notice-danger">
                        🚗 <strong>Occupied:</strong> A vehicle is currently parked in this bay.
                    </div>
                `;
            } else {
                authBlockHtml = `
                    <div class="inspector-notice notice-secondary">
                        🔒 <strong>Out of Service:</strong> Temporarily closed for facility maintenance.
                    </div>
                `;
            }
        }

        this.inspectorEl.innerHTML = `
            <div class="inspector-card active">
                <div class="inspector-header">
                    <div>
                        <div class="inspector-slot-id">${escapeHtml(slot.slotId)}</div>
                        <div class="inspector-slot-type">
                            ${isEv ? '⚡ EV Fast Charging Stall' : (isAccessible ? '♿ Priority Stall' : '🚗 Standard Parking Stall')}
                        </div>
                    </div>
                    <span class="badge ${badgeClass}">${escapeHtml(statusTitle)}</span>
                </div>

                <div class="inspector-meta-grid">
                    <div class="meta-item">
                        <span class="meta-label">Facility</span>
                        <span class="meta-val">${escapeHtml(this.config.zoneName)}</span>
                    </div>
                    <div class="meta-item">
                        <span class="meta-label">Deck Level</span>
                        <span class="meta-val">Level ${slot.floor || 1}</span>
                    </div>
                    <div class="meta-item">
                        <span class="meta-label">Standard Tariff</span>
                        <span class="meta-val">₹ ${rate}/hr</span>
                    </div>
                    <div class="meta-item">
                        <span class="meta-label">Sensor Gate</span>
                        <span class="meta-val">ANPR Gate 1</span>
                    </div>
                </div>

                ${authBlockHtml}
            </div>
        `;

        // If admin override button exists, hook it up
        const overrideBtn = document.getElementById('btnAdminTriggerOverride');
        if (overrideBtn) {
            overrideBtn.addEventListener('click', function () {
                if (typeof window.openAdminOverrideModal === 'function') {
                    window.openAdminOverrideModal(slot.slotId, slot.status);
                }
            });
        }
    };

    /**
     * Binds toolbar controls (floor switches).
     */
    LotMapInstance.prototype.bindEvents = function () {
        const self = this;
        const pills = this.container.querySelectorAll('.lot-floor-pill');
        pills.forEach(function (pill) {
            pill.addEventListener('click', function () {
                const floor = parseInt(this.dataset.floor, 10);
                self.switchFloor(floor);
            });
        });
    };

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#39;');
    }

    window.LotMap = LotMap;

})(window);
