/**
 * Smart Parking Management System — Client-Side Form Validation
 * Reduces server round-trips by validating email, password, phone, and vehicle VRN before submit.
 */

document.addEventListener('DOMContentLoaded', function () {
    // 1. Registration Form Validation
    const registerForm = document.getElementById('registerForm');
    if (registerForm) {
        registerForm.addEventListener('submit', function (e) {
            let isValid = true;

            const nameInput = document.getElementById('name');
            const emailInput = document.getElementById('email');
            const phoneInput = document.getElementById('phoneNumber');
            const passwordInput = document.getElementById('password');
            const confirmPasswordInput = document.getElementById('confirmPassword');

            // Clear previous errors
            clearErrors(registerForm);

            // Name validation
            if (!nameInput.value.trim() || nameInput.value.trim().length < 2) {
                showError(nameInput, 'Full name must be at least 2 characters.');
                isValid = false;
            }

            // Email validation
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(emailInput.value.trim())) {
                showError(emailInput, 'Please enter a valid email address.');
                isValid = false;
            }

            // Phone validation (10 digits)
            const phoneRegex = /^[6-9]\d{9}$/;
            if (phoneInput.value.trim() && !phoneRegex.test(phoneInput.value.trim())) {
                showError(phoneInput, 'Please enter a valid 10-digit mobile number.');
                isValid = false;
            }

            // Password length
            if (passwordInput.value.length < 6) {
                showError(passwordInput, 'Password must be at least 6 characters.');
                isValid = false;
            }

            // Passwords match
            if (passwordInput.value !== confirmPasswordInput.value) {
                showError(confirmPasswordInput, 'Passwords do not match.');
                isValid = false;
            }

            // DPDP & Terms Consent
            const termsConsent = document.getElementById('termsConsent');
            if (termsConsent && !termsConsent.checked) {
                showError(termsConsent, 'You must agree to the Terms, Privacy Policy (DPDP Act), and Cookie Policy to register.');
                isValid = false;
            }

            if (!isValid) {
                e.preventDefault();
            }
        });
    }

    // 2. Login Form Validation
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', function (e) {
            let isValid = true;
            const emailInput = document.getElementById('email');
            const passwordInput = document.getElementById('password');

            clearErrors(loginForm);

            if (!emailInput.value.trim()) {
                showError(emailInput, 'Email address is required.');
                isValid = false;
            }

            if (!passwordInput.value) {
                showError(passwordInput, 'Password is required.');
                isValid = false;
            }

            if (!isValid) {
                e.preventDefault();
            }
        });
    }

    // 3. Booking Form VRN Live Preview & Validation
    const bookingForm = document.getElementById('bookingForm');
    const vrnInput = document.getElementById('vehicleNumber');
    const platePreviewText = document.getElementById('hsrpVrnPreview');

    if (vrnInput && platePreviewText) {
        // Auto uppercase and format
        vrnInput.addEventListener('input', function () {
            let clean = this.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
            if (clean.length > 10) clean = clean.substring(0, 10);
            this.value = clean;
            platePreviewText.textContent = clean.length > 0 ? clean : 'KA 01 AB 1234';
        });
    }

    if (bookingForm) {
        bookingForm.addEventListener('submit', function (e) {
            let isValid = true;
            clearErrors(bookingForm);

            if (vrnInput) {
                const vrn = vrnInput.value.trim();
                if (vrn.length < 5) {
                    showError(vrnInput, 'Enter a valid Vehicle Registration Number (e.g. KA01AB1234)');
                    isValid = false;
                }
            }

            const durationInput = document.getElementById('durationHours');
            if (durationInput && (parseInt(durationInput.value) < 1 || parseInt(durationInput.value) > 24)) {
                showError(durationInput, 'Duration must be between 1 and 24 hours.');
                isValid = false;
            }

            const bookingConsent = document.getElementById('bookingConsent');
            if (bookingConsent && !bookingConsent.checked) {
                showError(bookingConsent, 'You must accept the facility rules, grace period conditions, and cancellation policy to proceed.');
                isValid = false;
            }

            if (!isValid) {
                e.preventDefault();
            }
        });
    }

    function showError(inputElement, message) {
        inputElement.classList.add('is-invalid');
        const errSpan = document.createElement('span');
        errSpan.className = 'form-error';
        errSpan.textContent = message;
        inputElement.parentNode.appendChild(errSpan);
    }

    function clearErrors(formElement) {
        formElement.querySelectorAll('.form-error').forEach(el => el.remove());
        formElement.querySelectorAll('.is-invalid').forEach(el => el.classList.remove('is-invalid'));
    }
});
