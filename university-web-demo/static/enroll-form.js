const form = document.getElementById('enroll-form');
const submitBtn = document.getElementById('submit-btn');
const buttonText = document.getElementById('button-text');
const loadingSpinner = document.getElementById('loading-spinner');

if (form && submitBtn && buttonText && loadingSpinner) {
    form.addEventListener('submit', (e) => {
        buttonText.classList.add('hidden');
        loadingSpinner.classList.remove('hidden');
        submitBtn.disabled = true;
    });
} else {
    console.error('One or more form elements not found.');
}