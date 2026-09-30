/**
 * Smart Parking Management System — Payment Screen Countdown Timer & Method Tabs
 * Auto-expires pending booking session state if payment is not confirmed in time.
 */

(function () {
    let timerInterval = null;
    const totalDuration = 300; // 5 minutes = 300 seconds

    document.addEventListener('DOMContentLoaded', function () {
        initCountdown();
        initPaymentMethods();
    });

    function initCountdown() {
        const timerContainer = document.getElementById('paymentTimerBox');
        if (!timerContainer) return;

        const bookingId = timerContainer.dataset.bookingId;
        let remaining = parseInt(timerContainer.dataset.remainingSeconds || '300');

        const digitsEl = document.getElementById('timerDigits');
        const circleProgress = document.getElementById('timerCircleProgress');
        const circumference = 2 * Math.PI * 22; // radius is 22

        function updateDisplay() {
            if (remaining <= 0) {
                clearInterval(timerInterval);
                digitsEl.textContent = '00:00';
                handleExpiry(bookingId);
                return;
            }

            const mins = Math.floor(remaining / 60);
            const secs = remaining % 60;
            digitsEl.textContent = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

            // Update SVG circle stroke
            if (circleProgress) {
                const fraction = remaining / totalDuration;
                const offset = circumference * (1 - fraction);
                circleProgress.style.strokeDasharray = `${circumference} ${circumference}`;
                circleProgress.style.strokeDashoffset = offset;
            }

            remaining--;
        }

        updateDisplay();
        timerInterval = setInterval(updateDisplay, 1000);
    }

    async function handleExpiry(bookingId) {
        alert('Your 5-minute reservation window has expired. The parking bay has been released.');
        try {
            await fetch(`${contextPath}/booking?action=expirePending&bookingId=${encodeURIComponent(bookingId)}`, {
                method: 'POST'
            });
        } catch (e) {
            console.error('Error releasing slot:', e);
        }
        window.location.href = `${contextPath}/zones?msg=session_expired`;
    }

    function initPaymentMethods() {
        const methodRadios = document.querySelectorAll('input[name="paymentMethod"]');
        const panels = {
            'UPI': document.getElementById('methodPanelUPI'),
            'FASTag': document.getElementById('methodPanelFASTag'),
            'CARD': document.getElementById('methodPanelCard'),
            'NET_BANKING': document.getElementById('methodPanelNet'),
            'WALLET': document.getElementById('methodPanelWallet')
        };

        methodRadios.forEach(radio => {
            radio.addEventListener('change', function () {
                Object.values(panels).forEach(p => {
                    if (p) p.style.display = 'none';
                });
                const target = panels[this.value];
                if (target) target.style.display = 'block';
            });
        });
    }

    window.addEventListener('beforeunload', function () {
        if (timerInterval) clearInterval(timerInterval);
    });
})();
