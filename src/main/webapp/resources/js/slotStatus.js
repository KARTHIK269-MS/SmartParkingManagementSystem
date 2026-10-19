/**
 * Smart Parking Management System — Real-time Slot Polling & Selection
 * Periodically polls ZoneServlet?action=slotStatusJson to refresh bay status live
 * without page reload, reflecting background IoT sensor events.
 * 
 * Supports both:
 * 1. Lot Vulture 2D Architectural Visual Deck Map
 * 2. Classic Card Grid View (with toggle and floor filtering)
 */

(function () {
    let selectedSlotId = null;
    let selectedZoneId = null;
    let selectedRate = 30;
    let currentFloor = 1;
    let pollInterval = null;

    document.addEventListener('DOMContentLoaded', function () {
        const grid = document.getElementById('parkingGrid');
        if (!grid) return;

        selectedZoneId = grid.dataset.zoneId || 'A';
        selectedRate = parseFloat(grid.dataset.hourlyRate || '30');

        initVisualLotMap();
        initViewModeToggle();
        initFloorTabs();
        initSlotClicks();
        startPolling();
    });

    /**
     * Initializes the Lot Vulture 2D Visual Map on the Driver Portal.
     */
    function initVisualLotMap() {
        const mapContainer = document.getElementById('driverLotMapContainer');
        const grid = document.getElementById('parkingGrid');
        if (!mapContainer) return;

        try {
            if (typeof window.LotMap === 'undefined') {
                throw new Error('LotMap library is not available in browser scope.');
            }

            const slotsData = (typeof initialDriverSlots !== 'undefined' && Array.isArray(initialDriverSlots)) ? initialDriverSlots : [];
            const zoneInfo = (typeof driverZoneInfo !== 'undefined') ? driverZoneInfo : {
                zoneId: selectedZoneId,
                name: 'Facility Deck',
                location: 'Metropolitan Corridor',
                hourlyRate: selectedRate
            };

            window.driverLotMapInstance = window.LotMap.create({
                containerId: 'driverLotMapContainer',
                zoneId: selectedZoneId,
                zoneName: zoneInfo.name,
                location: zoneInfo.location,
                hourlyRate: zoneInfo.hourlyRate,
                mode: 'driver',
                slots: slotsData,
                currentFloor: currentFloor,
                contextPath: (typeof contextPath !== 'undefined') ? contextPath : '',
                onSlotSelect: function (slotId, slot) {
                    syncSelectionFromMap(slotId, slot);
                }
            });

            if (!window.driverLotMapInstance) {
                throw new Error('LotMap.create failed to return an instance.');
            }
        } catch (err) {
            console.error('[LotMap Driver] Map initialization issue:', err);
            fallbackToGridMode(mapContainer, grid, err.message);
        }
    }

    function fallbackToGridMode(mapContainer, grid, reason) {
        if (mapContainer) {
            mapContainer.innerHTML = `
                <div class="alert alert-warning" style="margin-bottom: 20px; border-left: 4px solid #f59e0b;">
                    <strong>ℹ️ Visual Map Notice:</strong> The architectural deck map is loading or unavailable. The interactive bay grid below is active for booking.
                </div>
            `;
            mapContainer.style.display = 'block';
        }
        if (grid) grid.style.display = 'grid';

        const toggle = document.getElementById('driverViewModeToggle');
        if (toggle) {
            toggle.querySelectorAll('.view-mode-btn').forEach(b => {
                if (b.dataset.view === 'grid') b.classList.add('active');
                else b.classList.remove('active');
            });
        }
    }

    /**
     * Synchronizes slot selection made inside the Visual Map to the sticky action bar & grid.
     */
    function syncSelectionFromMap(slotId, slot) {
        selectedSlotId = slotId;

        // Sync grid selection styling
        document.querySelectorAll('.slot-box').forEach(b => {
            if (slotId && b.dataset.slotId === slotId) {
                b.classList.add('selected');
            } else {
                b.classList.remove('selected');
            }
        });

        // Update sticky action bar
        updateActionBar(slotId);
    }

    /**
     * Handles switching between Grid View and Visual Lot Map.
     */
    function initViewModeToggle() {
        const toggle = document.getElementById('driverViewModeToggle');
        if (!toggle) return;

        const grid = document.getElementById('parkingGrid');
        const mapContainer = document.getElementById('driverLotMapContainer');
        const btns = toggle.querySelectorAll('.view-mode-btn');

        // Check stored preference or default to Visual Map
        const savedMode = sessionStorage.getItem('sp_driver_view_mode') || 'map';
        applyViewMode(savedMode);

        btns.forEach(btn => {
            btn.addEventListener('click', function () {
                const mode = this.dataset.view;
                sessionStorage.setItem('sp_driver_view_mode', mode);
                applyViewMode(mode);
            });
        });

        function applyViewMode(mode) {
            btns.forEach(b => {
                if (b.dataset.view === mode) b.classList.add('active');
                else b.classList.remove('active');
            });

            if (mode === 'grid') {
                if (grid) grid.style.display = 'grid';
                if (mapContainer) mapContainer.style.display = 'none';
            } else {
                if (grid) grid.style.display = 'none';
                if (mapContainer) mapContainer.style.display = 'block';
                if (window.driverLotMapInstance) {
                    window.driverLotMapInstance.renderMap();
                } else {
                    initVisualLotMap();
                }
            }
        }
    }

    function initFloorTabs() {
        const tabs = document.querySelectorAll('.floor-tab-btn');
        tabs.forEach(tab => {
            tab.addEventListener('click', function () {
                tabs.forEach(t => t.classList.remove('active'));
                this.classList.add('active');
                currentFloor = parseInt(this.dataset.floor || '1', 10);
                filterSlotsByFloor(currentFloor);

                // Sync floor to Visual Map instance
                if (window.driverLotMapInstance) {
                    window.driverLotMapInstance.switchFloor(currentFloor);
                }
            });
        });
        filterSlotsByFloor(currentFloor);
    }

    function filterSlotsByFloor(floor) {
        const slotBoxes = document.querySelectorAll('.slot-box');
        slotBoxes.forEach(box => {
            const slotFloor = parseInt(box.dataset.floor || '1', 10);
            box.style.display = (slotFloor === floor) ? 'flex' : 'none';
        });
    }

    function initSlotClicks() {
        const grid = document.getElementById('parkingGrid');
        grid.addEventListener('click', function (e) {
            const box = e.target.closest('.slot-box');
            if (!box) return;

            const status = box.dataset.status;
            if (status !== 'AVAILABLE') {
                return; // cannot select booked or blocked slots
            }

            const slotId = box.dataset.slotId;
            selectSlot(slotId, box);
        });
    }

    function selectSlot(slotId, boxElement) {
        document.querySelectorAll('.slot-box').forEach(b => b.classList.remove('selected'));

        if (selectedSlotId === slotId) {
            // Deselect
            selectedSlotId = null;
            updateActionBar(null);
            if (window.driverLotMapInstance) {
                window.driverLotMapInstance.config.selectedSlotId = null;
                window.driverLotMapInstance.renderMap();
                window.driverLotMapInstance.renderInspectorEmpty();
            }
        } else {
            selectedSlotId = slotId;
            if (boxElement) boxElement.classList.add('selected');
            updateActionBar(slotId);

            // Sync selection into Visual Map
            if (window.driverLotMapInstance) {
                window.driverLotMapInstance.selectSlot(slotId);
            }
        }
    }

    function updateActionBar(slotId) {
        const actionBar = document.getElementById('slotActionBar');
        const displayBay = document.getElementById('actionBarBay');
        const bookBtn = document.getElementById('actionBarBookBtn');

        if (!actionBar) return;

        const ctx = (typeof contextPath !== 'undefined') ? contextPath : '';

        if (slotId) {
            displayBay.textContent = slotId;
            bookBtn.href = `${ctx}/booking?action=book&slotId=${encodeURIComponent(slotId)}&zone=${encodeURIComponent(selectedZoneId)}`;
            actionBar.style.display = 'flex';
        } else {
            actionBar.style.display = 'none';
        }
    }

    function startPolling() {
        // Poll every 3 seconds for responsive live updates
        pollInterval = setInterval(fetchLiveStatus, 3000);
    }

    async function fetchLiveStatus() {
        try {
            const ctx = (typeof contextPath !== 'undefined') ? contextPath : '';
            const response = await fetch(`${ctx}/zones?action=slotStatusJson&zone=${encodeURIComponent(selectedZoneId)}`);
            if (!response.ok) return;

            const slots = await response.json();
            updateGridDOM(slots);

            // Live update the visual lot map
            if (window.driverLotMapInstance) {
                window.driverLotMapInstance.updateStatuses(slots);
            }
        } catch (err) {
            console.warn('[Slot Polling] Connection error:', err);
        }
    }

    function updateGridDOM(slots) {
        let availableCount = 0;

        slots.forEach(slot => {
            const box = document.querySelector(`.slot-box[data-slot-id="${slot.slotId}"]`);
            if (!box) return;

            const oldStatus = box.dataset.status;
            const newStatus = slot.status;

            if (oldStatus !== newStatus) {
                // Remove old classes
                box.classList.remove('available', 'booked', 'occupied', 'reserved', 'blocked', 'maintenance');
                box.classList.add(newStatus.toLowerCase());
                box.dataset.status = newStatus;

                // Update text badge
                const statusPill = box.querySelector('.slot-status-pill');
                if (statusPill) {
                    statusPill.textContent = newStatus;
                }

                // Update vehicle icon
                const iconEl = box.querySelector('.slot-vehicle-icon');
                if (iconEl) {
                    if (newStatus === 'BOOKED' || newStatus === 'OCCUPIED') {
                        iconEl.textContent = '🚗';
                        iconEl.style.color = '';
                    } else if (newStatus === 'RESERVED') {
                        iconEl.textContent = '⏱️';
                        iconEl.style.color = '';
                    } else {
                        iconEl.textContent = '🅿️';
                        iconEl.style.color = '#34d399';
                    }
                }

                // If currently selected slot became unavailable, deselect it
                if (selectedSlotId === slot.slotId && newStatus !== 'AVAILABLE') {
                    selectedSlotId = null;
                    box.classList.remove('selected');
                    updateActionBar(null);
                    showToastNotification(`Bay ${slot.slotId} is no longer available. Please choose another bay.`, 'warning');
                }
            }

            if (newStatus === 'AVAILABLE') {
                availableCount++;
            }
        });

        // Update top counter
        const counterEl = document.getElementById('liveAvailableCount');
        if (counterEl) {
            counterEl.textContent = availableCount;
        }
    }

    function showToastNotification(message, type = 'info') {
        let toast = document.getElementById('spToast');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'spToast';
            toast.className = 'sp-toast';
            document.body.appendChild(toast);
        }
        toast.textContent = message;
        toast.className = `sp-toast show ${type}`;
        setTimeout(() => {
            toast.className = 'sp-toast';
        }, 4000);
    }

    // Stop polling if user navigates away
    window.addEventListener('beforeunload', function () {
        if (pollInterval) clearInterval(pollInterval);
    });
})();
