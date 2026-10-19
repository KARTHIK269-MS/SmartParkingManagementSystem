/**
 * Smart Parking Management System — Cookie Consent Banner
 * Compliant with India's DPDP Act (2023), GDPR, and ePrivacy Guidelines.
 * Allows users to choose between 'Accept All' and 'Essential Only', and adjust preferences.
 */
(function() {
    const COOKIE_CONSENT_KEY = 'smart_parking_cookie_consent';

    function initCookieConsent() {
        const storedConsent = localStorage.getItem(COOKIE_CONSENT_KEY);

        // If no consent chosen yet, render the banner
        if (!storedConsent) {
            showCookieBanner();
        }

        // Attach listeners to any "Cookie Settings" links in footer
        document.querySelectorAll('.cookie-settings-btn').forEach(btn => {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                showCookieBanner(true);
            });
        });
    }

    function showCookieBanner(forceShow) {
        let banner = document.getElementById('cookieConsentBanner');
        if (!banner) {
            banner = document.createElement('div');
            banner.id = 'cookieConsentBanner';
            banner.className = 'cookie-consent-banner';
            banner.setAttribute('role', 'region');
            banner.setAttribute('aria-label', 'Cookie Consent Notice');

            const contextPath = window.contextPath || '';

            banner.innerHTML = `
                <div class="cookie-consent-container">
                    <div class="cookie-consent-content">
                        <div class="cookie-consent-icon" aria-hidden="true">🍪</div>
                        <div class="cookie-consent-text">
                            <strong>We value your privacy &amp; transparency</strong>
                            <p>
                                We use strictly necessary cookies to keep you authenticated, process parking bay reservations, and secure your session. We do not use third-party advertising trackers or sell personal data. Read our 
                                <a href="${contextPath}/cookies.jsp" target="_blank" class="cookie-link">Cookie Policy</a> and 
                                <a href="${contextPath}/privacy.jsp" target="_blank" class="cookie-link">Privacy Policy</a> (compliant with India's DPDP Act, 2023).
                            </p>
                        </div>
                    </div>
                    <div class="cookie-consent-actions">
                        <button type="button" id="cookieBtnEssential" class="btn btn-secondary btn-sm" aria-label="Accept Essential Cookies Only">
                            Essential Only
                        </button>
                        <button type="button" id="cookieBtnAcceptAll" class="btn btn-primary btn-sm" aria-label="Accept All Cookies">
                            Accept All
                        </button>
                    </div>
                </div>
            `;
            document.body.appendChild(banner);

            document.getElementById('cookieBtnAcceptAll').addEventListener('click', function() {
                saveConsent('all');
            });
            document.getElementById('cookieBtnEssential').addEventListener('click', function() {
                saveConsent('essential');
            });
        }

        banner.style.display = 'block';
        setTimeout(() => {
            banner.classList.add('visible');
        }, 50);

        if (forceShow) {
            const acceptBtn = document.getElementById('cookieBtnAcceptAll');
            if (acceptBtn) acceptBtn.focus();
        }
    }

    function saveConsent(level) {
        localStorage.setItem(COOKIE_CONSENT_KEY, JSON.stringify({
            level: level,
            timestamp: new Date().toISOString()
        }));

        const banner = document.getElementById('cookieConsentBanner');
        if (banner) {
            banner.classList.remove('visible');
            setTimeout(() => {
                banner.style.display = 'none';
            }, 300);
        }
    }

    function initResponsiveNavbar() {
        const navbar = document.querySelector('.navbar');
        if (!navbar || navbar.dataset.navReady === 'true') return;
        navbar.dataset.navReady = 'true';

        const navLinks = navbar.querySelector('.nav-links');
        const navActions = navbar.querySelector('.nav-actions');

        let headerControls = navbar.querySelector('.nav-header-controls');
        if (!headerControls) {
            headerControls = document.createElement('div');
            headerControls.className = 'nav-header-controls';
            navbar.appendChild(headerControls);
        }

        let toggleBtn = navbar.querySelector('.nav-toggle-btn');
        if (!toggleBtn) {
            toggleBtn = document.createElement('button');
            toggleBtn.type = 'button';
            toggleBtn.className = 'nav-toggle-btn';
            toggleBtn.setAttribute('aria-label', 'Toggle navigation menu');
            toggleBtn.setAttribute('aria-expanded', 'false');
            toggleBtn.innerHTML = '<span class="nav-toggle-icon">☰</span>';
            headerControls.appendChild(toggleBtn);
        }

        // Check for unread notification badge and add subtle alert dot
        const notifBadge = navbar.querySelector('#notifBadge');
        if (notifBadge && notifBadge.style.display !== 'none' && parseInt(notifBadge.textContent || '0') > 0) {
            if (!toggleBtn.querySelector('.nav-toggle-dot')) {
                const dot = document.createElement('span');
                dot.className = 'nav-toggle-dot';
                toggleBtn.appendChild(dot);
            }
        }

        let collapse = navbar.querySelector('.nav-collapse');
        if (!collapse) {
            collapse = document.createElement('div');
            collapse.className = 'nav-collapse';
            if (navLinks) collapse.appendChild(navLinks);
            if (navActions) collapse.appendChild(navActions);
            navbar.appendChild(collapse);
        }

        toggleBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            const isOpen = navbar.classList.toggle('nav-open');
            toggleBtn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
            const icon = toggleBtn.querySelector('.nav-toggle-icon');
            if (icon) icon.textContent = isOpen ? '✕' : '☰';
        });

        document.addEventListener('click', function(e) {
            if (navbar.classList.contains('nav-open') && !navbar.contains(e.target)) {
                navbar.classList.remove('nav-open');
                toggleBtn.setAttribute('aria-expanded', 'false');
                const icon = toggleBtn.querySelector('.nav-toggle-icon');
                if (icon) icon.textContent = '☰';
            }
        });

        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && navbar.classList.contains('nav-open')) {
                navbar.classList.remove('nav-open');
                toggleBtn.setAttribute('aria-expanded', 'false');
                const icon = toggleBtn.querySelector('.nav-toggle-icon');
                if (icon) icon.textContent = '☰';
            }
        });

        window.addEventListener('resize', function() {
            if (window.innerWidth > 768 && navbar.classList.contains('nav-open')) {
                navbar.classList.remove('nav-open');
                toggleBtn.setAttribute('aria-expanded', 'false');
                const icon = toggleBtn.querySelector('.nav-toggle-icon');
                if (icon) icon.textContent = '☰';
            }
        });
    }

    function initAll() {
        initCookieConsent();
        initResponsiveNavbar();
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAll);
    } else {
        initAll();
    }
})();
