/**
 * Smart Parking Management System — Admin Dashboard Interactivity
 * Provides client-side searching, column sorting, filtering for bookings/slots,
 * slot override modals, and real-time IoT simulator controls.
 */

document.addEventListener('DOMContentLoaded', function () {
    initBookingSearchAndFilter();
    initTableSort();
    initSlotOverrideModal();
    initIotPolling();
});

// 1. Search & Status Filter for Bookings
function initBookingSearchAndFilter() {
    const searchInput = document.getElementById('bookingSearchInput');
    const statusFilter = document.getElementById('bookingStatusFilter');
    const tableBody = document.querySelector('#adminBookingsTable tbody');

    if (!searchInput || !tableBody) return;

    function applyFilters() {
        const query = searchInput.value.toLowerCase().trim();
        const selectedStatus = statusFilter ? statusFilter.value.toUpperCase() : 'ALL';
        const rows = tableBody.querySelectorAll('tr');

        rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            const statusBadge = row.querySelector('.booking-status-badge');
            const rowStatus = statusBadge ? statusBadge.dataset.status.toUpperCase() : '';

            const matchesQuery = !query || text.includes(query);
            const matchesStatus = (selectedStatus === 'ALL') || (rowStatus === selectedStatus);

            row.style.display = (matchesQuery && matchesStatus) ? '' : 'none';
        });
    }

    searchInput.addEventListener('input', applyFilters);
    if (statusFilter) {
        statusFilter.addEventListener('change', applyFilters);
    }
}

// 2. Client-side Table Sort
function initTableSort() {
    const table = document.getElementById('adminBookingsTable');
    if (!table) return;

    const headers = table.querySelectorAll('th[data-sortable="true"]');
    headers.forEach((th, colIndex) => {
        th.style.cursor = 'pointer';
        th.title = 'Click to sort';
        let asc = true;

        th.addEventListener('click', () => {
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr'));

            rows.sort((a, b) => {
                const cellA = a.children[colIndex].textContent.trim();
                const cellB = b.children[colIndex].textContent.trim();

                const numA = parseFloat(cellA.replace(/[^0-9.-]+/g, ''));
                const numB = parseFloat(cellB.replace(/[^0-9.-]+/g, ''));

                if (!isNaN(numA) && !isNaN(numB)) {
                    return asc ? numA - numB : numB - numA;
                }
                return asc ? cellA.localeCompare(cellB) : cellB.localeCompare(cellA);
            });

            rows.forEach(row => tbody.appendChild(row));
            asc = !asc;
        });
    });
}

// 3. Slot Status Override Modal
function initSlotOverrideModal() {
    const modal = document.getElementById('slotOverrideModal');
    const closeBtn = document.getElementById('closeModalBtn');
    const modalSlotId = document.getElementById('modalSlotId');
    const inputSlotId = document.getElementById('inputSlotId');

    if (!modal) return;

    document.querySelectorAll('.admin-slot-clickable').forEach(el => {
        el.addEventListener('click', function () {
            const slotId = this.dataset.slotId;
            const currentStatus = this.dataset.status;

            if (modalSlotId) modalSlotId.textContent = slotId;
            if (inputSlotId) inputSlotId.value = slotId;

            const statusSelect = document.getElementById('overrideStatusSelect');
            if (statusSelect) statusSelect.value = currentStatus;

            modal.style.display = 'flex';
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

// 4. IoT Simulator Live Status Poller
function initIotPolling() {
    const statusEl = document.getElementById('iotLiveStatus');
    const lastEventEl = document.getElementById('iotLastEventText');
    if (!statusEl) return;

    setInterval(async () => {
        try {
            const res = await fetch(`${contextPath}/admin?action=iotStatusJson`);
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
