/**
 * Smart Parking Management System — Real-time Slot Polling & Selection
 * Periodically polls ZoneServlet?action=slotStatusJson to refresh bay status live
 * without page reload, reflecting background IoT sensor events.
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

        initFloorTabs();
        initSlotClicks();
        startPolling();
    });

    function initFloorTabs() {
        const tabs = document.querySelectorAll('.floor-tab-btn');
        tabs.forEach(tab => {
            tab.addEventListener('click', function () {
                tabs.forEach(t => t.classList.remove('active'));
                this.classList.add('active');
                currentFloor = parseInt(this.dataset.floor || '1');
                filterSlotsByFloor(currentFloor);
            });
        });
        filterSlotsByFloor(currentFloor);
    }

    function filterSlotsByFloor(floor) {
        const slotBoxes = document.querySelectorAll('.slot-box');
        slotBoxes.forEach(box => {
            const slotFloor = parseInt(box.dataset.floor || '1');
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
        } else {
            selectedSlotId = slotId;
            boxElement.classList.add('selected');
            updateActionBar(slotId);
        }
    }

    function updateActionBar(slotId) {
        const actionBar = document.getElementById('slotActionBar');
        const displayBay = document.getElementById('actionBarBay');
        const bookBtn = document.getElementById('actionBarBookBtn');

        if (!actionBar) return;

        if (slotId) {
            displayBay.textContent = slotId;
            bookBtn.href = `${contextPath}/booking?action=book&slotId=${encodeURIComponent(slotId)}&zone=${encodeURIComponent(selectedZoneId)}`;
            actionBar.style.display = 'flex';
        } else {
            actionBar.style.display = 'none';
        }
    }

    function startPolling() {
        // Poll every 5 seconds
        pollInterval = setInterval(fetchLiveStatus, 5000);
    }

    async function fetchLiveStatus() {
        try {
            const response = await fetch(`${contextPath}/zones?action=slotStatusJson&zone=${encodeURIComponent(selectedZoneId)}`);
            if (!response.ok) return;

            const slots = await response.json();
            updateGridDOM(slots);
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
                box.classList.remove('available', 'booked', 'reserved', 'blocked');
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
                    if (newStatus === 'BOOKED') {
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

                // Smooth status transition animation pulse
                box.style.animation = 'bay-selected-pop 0.45s ease';
                setTimeout(() => { box.style.animation = ''; }, 450);

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
