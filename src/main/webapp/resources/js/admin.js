/**
 * Smart Parking Management System — Admin Dashboard Interactivity
 * Provides client-side searching, column sorting, filtering for bookings/slots,
 * slot override modals, real-time IoT simulator controls, and
 * Lot Vulture Architectural Live Parking Deck Map.
 */

document.addEventListener('DOMContentLoaded', function () {
    initBookingSearchAndFilter();
    initUserSearchAndFilter();
    initTableSort();
    initSlotOverrideModal();
    initIotPolling();
    initAdminLotMap();
    initAdminViewModeToggle();
    initActiveSessionsStopwatches();
    initActiveSessionsSearch();
    initGateActivityFilter();
});

// 1. Search & Filter for Bookings (Query, Status, and Zone)
function initBookingSearchAndFilter() {
    const searchInput = document.getElementById('bookingSearchInput');
    const statusFilter = document.getElementById('bookingStatusFilter');
    const zoneFilter = document.getElementById('bookingZoneFilter');
    const tableBody = document.querySelector('#adminBookingsTable tbody');

    if (!searchInput || !tableBody) return;

    function applyFilters() {
        const query = searchInput.value.toLowerCase().trim();
        const selectedStatus = statusFilter ? statusFilter.value.toUpperCase() : 'ALL';
        const selectedZone = zoneFilter ? zoneFilter.value.toUpperCase() : 'ALL';
        const rows = tableBody.querySelectorAll('tr');

        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            const statusBadge = row.querySelector('.booking-status-badge');
            const rowStatus = statusBadge ? statusBadge.dataset.status.toUpperCase() : '';
            const rowZone = row.dataset.zone ? row.dataset.zone.toUpperCase() : '';

            const matchesQuery = !query || text.includes(query);
            const matchesStatus = (selectedStatus === 'ALL') || (rowStatus === selectedStatus);
            const matchesZone = (selectedZone === 'ALL') || (rowZone === selectedZone);

            row.style.display = (matchesQuery && matchesStatus && matchesZone) ? '' : 'none';
        });
    }

    searchInput.addEventListener('input', applyFilters);
    if (statusFilter) {
        statusFilter.addEventListener('change', applyFilters);
    }
    if (zoneFilter) {
        zoneFilter.addEventListener('change', applyFilters);
    }
}

// 2. Search & Filter for Registered Users and Drivers Directory
function initUserSearchAndFilter() {
    const searchInput = document.getElementById('userSearchInput');
    const roleFilter = document.getElementById('userRoleFilter');
    const tableBody = document.querySelector('#adminUsersTable tbody');

    if (!searchInput || !tableBody) return;

    function applyUserFilters() {
        const query = searchInput.value.toLowerCase().trim();
        const selectedRole = roleFilter ? roleFilter.value.toUpperCase() : 'ALL';
        const rows = tableBody.querySelectorAll('tr');

        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            const roleBadge = row.querySelector('.badge');
            const rowRole = roleBadge ? roleBadge.textContent.trim().toUpperCase() : '';

            const matchesQuery = !query || text.includes(query);
            const matchesRole = (selectedRole === 'ALL') || (rowRole === selectedRole);

            row.style.display = (matchesQuery && matchesRole) ? '' : 'none';
        });
    }

    searchInput.addEventListener('input', applyUserFilters);
    if (roleFilter) {
        roleFilter.addEventListener('change', applyUserFilters);
    }
}

// 3. Client-side Table Sort for sortable tables
function initTableSort() {
    document.querySelectorAll('table.custom-table').forEach(table => {
        const headers = table.querySelectorAll('th[data-sortable="true"]');
        headers.forEach((th, colIndex) => {
            th.style.cursor = 'pointer';
            th.title = 'Click to sort column';
            let asc = true;

            th.addEventListener('click', () => {
                const tbody = table.querySelector('tbody');
                if (!tbody) return;
                const rows = Array.from(tbody.querySelectorAll('tr'));

                rows.sort((a, b) => {
                    const cellA = a.children[colIndex] ? a.children[colIndex].textContent.trim() : '';
                    const cellB = b.children[colIndex] ? b.children[colIndex].textContent.trim() : '';

                    const numA = parseFloat(cellA.replace(/[^0-9.-]+/g, ''));
                    const numB = parseFloat(cellB.replace(/[^0-9.-]+/g, ''));

                    if (!isNaN(numA) && !isNaN(numB) && cellA.match(/\d/) && cellB.match(/\d/)) {
                        return asc ? numA - numB : numB - numA;
                    }
                    return asc ? cellA.localeCompare(cellB) : cellB.localeCompare(cellA);
                });

                rows.forEach(row => tbody.appendChild(row));
                asc = !asc;
            });
        });
    });
}

// 4. Slot Status Override Modal (Global Handler)
window.openAdminOverrideModal = function (slotId, currentStatus) {
    const modal = document.getElementById('slotOverrideModal');
    const modalSlotId = document.getElementById('modalSlotId');
    const inputSlotId = document.getElementById('inputSlotId');
    const statusSelect = document.getElementById('overrideStatusSelect');

    if (!modal) return;

    if (modalSlotId) modalSlotId.textContent = slotId;
    if (inputSlotId) inputSlotId.value = slotId;
    if (statusSelect && currentStatus) statusSelect.value = currentStatus.toUpperCase();

    modal.style.display = 'flex';
};

function initSlotOverrideModal() {
    const modal = document.getElementById('slotOverrideModal');
    const closeBtn = document.getElementById('closeModalBtn');

    if (!modal) return;

    document.querySelectorAll('.admin-slot-clickable').forEach(el => {
        el.addEventListener('click', function () {
            const slotId = this.dataset.slotId;
            const currentStatus = this.dataset.status;
            window.openAdminOverrideModal(slotId, currentStatus);
        });
    });

    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            modal.style.display = 'none';
        });
    }

    window.addEventListener('click', (e) => {
        if (e.target === modal) modal.style.display = 'none';
    });
}

// 5. IoT Simulator Live Status Poller
function initIotPolling() {
    const statusEl = document.getElementById('iotLiveStatus');
    const lastEventEl = document.getElementById('iotLastEventText');
    if (!statusEl) return;

    const ctx = (typeof contextPath !== 'undefined') ? contextPath : '';

    setInterval(async () => {
        try {
            const res = await fetch(`${ctx}/admin?action=iotStatusJson`);
            if (res.ok) {
                const data = await res.json();
                if (data.running) {
                    statusEl.innerHTML = '<span class="badge badge-success">ACTIVE & BROADCASTING</span>';
                } else {
                    statusEl.innerHTML = '<span class="badge badge-secondary">PAUSED</span>';
                }
                if (lastEventEl && data.lastEvent) {
                    lastEventEl.textContent = data.lastEvent;
                }
            }
        } catch (ignored) {}
    }, 4000);
}

// 6. Lot Vulture Visual Map in Admin Console
function initAdminLotMap() {
    const mapContainer = document.getElementById('adminLotMapContainer');
    const zoneSelect = document.getElementById('adminMapZoneSelect');
    const gridSection = document.getElementById('adminBaysGridSection');
    const mapToolbar = document.getElementById('adminLotMapToolbar');
    if (!mapContainer) return;

    try {
        if (typeof window.LotMap === 'undefined') {
            throw new Error('LotMap library is not available in browser scope.');
        }

        const allSlots = (typeof adminAllSlotsData !== 'undefined' && Array.isArray(adminAllSlotsData)) ? adminAllSlotsData : [];
        const activeBookings = (typeof adminActiveBookingsBySlot !== 'undefined') ? adminActiveBookingsBySlot : {};

        function renderCurrentZoneMap() {
            const selectedZoneId = zoneSelect ? zoneSelect.value : 'B';
            const selectedOpt = zoneSelect ? zoneSelect.selectedOptions[0] : null;
            const zoneName = selectedOpt ? selectedOpt.dataset.name : 'Facility Deck';
            const zoneLoc = selectedOpt ? selectedOpt.dataset.location : 'Metropolitan Corridor';
            const hourlyRate = selectedOpt ? parseFloat(selectedOpt.dataset.hourly || '40') : 40.0;

            const zoneSlots = allSlots.filter(s => s.zoneId === selectedZoneId);

            window.adminLotMapInstance = window.LotMap.create({
                containerId: 'adminLotMapContainer',
                zoneId: selectedZoneId,
                zoneName: zoneName,
                location: zoneLoc,
                hourlyRate: hourlyRate,
                mode: 'admin',
                slots: zoneSlots,
                activeBookings: activeBookings,
                currentFloor: 1,
                contextPath: (typeof contextPath !== 'undefined') ? contextPath : '',
                onSlotSelect: function (slotId, slot) {
                    // Bay selected in Admin Lot Map
                }
            });
        }

        renderCurrentZoneMap();

        if (zoneSelect && !zoneSelect._hasLotMapListener) {
            zoneSelect._hasLotMapListener = true;
            zoneSelect.addEventListener('change', renderCurrentZoneMap);
        }

        // Real-time telemetry polling for the selected zone
        if (!window._adminLotMapInterval) {
            window._adminLotMapInterval = setInterval(async () => {
                if (!window.adminLotMapInstance) return;
                const curZone = zoneSelect ? zoneSelect.value : 'B';
                const ctx = (typeof contextPath !== 'undefined') ? contextPath : '';
                try {
                    const res = await fetch(`${ctx}/api/iot-sensor?zoneId=${encodeURIComponent(curZone)}&details=true`);
                    if (res.ok) {
                        const freshSlots = await res.json();
                        if (window.adminLotMapInstance) {
                            window.adminLotMapInstance.updateStatuses(freshSlots);
                        }

                        // Also update any grid cards for this zone if present
                        freshSlots.forEach(s => {
                            const box = document.querySelector(`.admin-slot-clickable[data-slot-id="${s.slotId}"]`);
                            if (box && box.dataset.status !== s.status) {
                                box.classList.remove('available', 'booked', 'reserved', 'blocked');
                                box.classList.add(s.status.toLowerCase());
                                box.dataset.status = s.status;
                                const pill = box.querySelector('.slot-status-pill');
                                if (pill) pill.textContent = s.status;
                            }
                        });
                    }
                } catch (ignored) {}
            }, 3500);
        }
    } catch (err) {
        console.error('[LotMap Admin] Map initialization issue:', err);
        handleAdminMapFailure(mapContainer, gridSection, mapToolbar);
    }
}

function handleAdminMapFailure(mapContainer, gridSection, mapToolbar) {
    if (mapContainer) {
        mapContainer.innerHTML = `
            <div class="alert alert-warning" style="margin-bottom: 20px; border-left: 4px solid #f59e0b;">
                <strong>ℹ️ Visual Map Notice:</strong> Architectural visual map renderer is currently offline. Defaulting to supervisory grid view below.
            </div>
        `;
        mapContainer.style.display = 'block';
    }
    if (mapToolbar) mapToolbar.style.display = 'none';
    if (gridSection) gridSection.style.display = 'block';

    const toggle = document.getElementById('adminBayViewToggle');
    if (toggle) {
        toggle.querySelectorAll('.view-mode-btn').forEach(b => {
            if (b.dataset.view === 'grid') b.classList.add('active');
            else b.classList.remove('active');
        });
    }
}

window.initAdminLotMap = initAdminLotMap;

// 7. Admin View Mode Switcher (Grid vs Visual Lot Map)
function initAdminViewModeToggle() {
    const toggle = document.getElementById('adminBayViewToggle');
    if (!toggle) return;

    const mapToolbar = document.getElementById('adminLotMapToolbar');
    const mapContainer = document.getElementById('adminLotMapContainer');
    const gridSection = document.getElementById('adminBaysGridSection');
    const btns = toggle.querySelectorAll('.view-mode-btn');

    const savedMode = sessionStorage.getItem('sp_admin_view_mode') || 'map';
    applyMode(savedMode);

    btns.forEach(btn => {
        btn.addEventListener('click', function () {
            const mode = this.dataset.view;
            sessionStorage.setItem('sp_admin_view_mode', mode);
            applyMode(mode);
        });
    });

    function applyMode(mode) {
        btns.forEach(b => {
            if (b.dataset.view === mode) b.classList.add('active');
            else b.classList.remove('active');
        });

        if (mode === 'grid') {
            if (mapToolbar) mapToolbar.style.display = 'none';
            if (mapContainer) mapContainer.style.display = 'none';
            if (gridSection) gridSection.style.display = 'block';
        } else {
            if (mapToolbar) mapToolbar.style.display = 'flex';
            if (mapContainer) mapContainer.style.display = 'block';
            if (gridSection) gridSection.style.display = 'none';
            if (window.adminLotMapInstance) {
                window.adminLotMapInstance.renderMap();
            } else {
                initAdminLotMap();
            }
        }
    }
}

// 8. Real-time stopwatch and tariff counter for Active Parking Sessions
function initActiveSessionsStopwatches() {
    const rows = document.querySelectorAll('.active-session-row');
    if (!rows.length) return;

    setInterval(() => {
        const now = Date.now();
        rows.forEach(row => {
            const entryEpoch = parseInt(row.dataset.entryEpoch || '0');
            const hourlyRate = parseFloat(row.dataset.hourlyRate || '40');
            const isPending = row.dataset.pending === 'true';

            if (entryEpoch > 0) {
                const elapsedSec = Math.max(0, Math.floor((now - entryEpoch) / 1000));
                const hrs = Math.floor(elapsedSec / 3600);
                const mins = Math.floor((elapsedSec % 3600) / 60);
                const secs = elapsedSec % 60;
                const clockStr = 
                    String(hrs).padStart(2, '0') + ':' + 
                    String(mins).padStart(2, '0') + ':' + 
                    String(secs).padStart(2, '0');

                const digitsEl = row.querySelector('.stopwatch-digits');
                if (digitsEl) digitsEl.textContent = clockStr;

                if (!isPending) {
                    const billedHours = Math.max(1, Math.ceil(elapsedSec / 3600));
                    const estAmount = (billedHours * hourlyRate).toFixed(2);
                    const accruedEl = row.querySelector('.live-accrued-val');
                    if (accruedEl) accruedEl.textContent = '₹ ' + estAmount;
                }
            }
        });
    }, 1000);
}

// 9. Active Sessions Table Search
function initActiveSessionsSearch() {
    const searchInput = document.getElementById('activeSessionsSearchInput');
    const tableBody = document.querySelector('#activeSessionsTable tbody');
    if (!searchInput || !tableBody) return;

    searchInput.addEventListener('input', function () {
        const query = this.value.toLowerCase().trim();
        tableBody.querySelectorAll('tr.active-session-row').forEach(row => {
            const text = row.textContent.toLowerCase();
            row.style.display = (!query || text.includes(query)) ? '' : 'none';
        });
    });
}

// 10. Gate Activity Ledger Search and Event Filter
function initGateActivityFilter() {
    const searchInput = document.getElementById('gateSearchInput');
    const filterSelect = document.getElementById('gateEventTypeFilter');
    const tableBody = document.querySelector('#gateActivityTable tbody');
    if (!tableBody) return;

    function applyGateFilter() {
        const query = searchInput ? searchInput.value.toLowerCase().trim() : '';
        const selectedType = filterSelect ? filterSelect.value.toUpperCase() : 'ALL';

        tableBody.querySelectorAll('tr.gate-event-row').forEach(row => {
            const text = row.textContent.toLowerCase();
            const rowType = row.dataset.eventType ? row.dataset.eventType.toUpperCase() : '';

            const matchesQuery = !query || text.includes(query);
            const matchesType = (selectedType === 'ALL') || (rowType === selectedType);

            row.style.display = (matchesQuery && matchesType) ? '' : 'none';
        });
    }

    if (searchInput) searchInput.addEventListener('input', applyGateFilter);
    if (filterSelect) filterSelect.addEventListener('change', applyGateFilter);
}

