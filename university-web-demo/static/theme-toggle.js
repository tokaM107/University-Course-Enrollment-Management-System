document.addEventListener('DOMContentLoaded', () => {
    const toggleButton = document.getElementById('theme-toggle');
    const themeIcon = document.getElementById('theme-icon');
    
    if (!toggleButton || !themeIcon) {
        console.error('Theme toggle elements not found');
        return;
    }

    // Define the SVG paths for sun and moon
    const icons = {
        sun: `<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>`,
        moon: `<svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
              </svg>`
    };

    // Set initial theme and icon
    function setInitialTheme() {
        const savedTheme = localStorage.getItem('theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        
        if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
            document.documentElement.classList.add('dark');
            themeIcon.innerHTML = icons.sun; // Show sun icon in dark mode
        } else {
            document.documentElement.classList.remove('dark');
            themeIcon.innerHTML = icons.moon; // Show moon icon in light mode
        }
    }

    setInitialTheme();

    // Toggle theme on button click
    toggleButton.addEventListener('click', () => {
        const html = document.documentElement;
        const isDark = html.classList.toggle('dark');
        
        // Update icon based on new theme
        themeIcon.innerHTML = isDark ? icons.sun : icons.moon;
        
        // Save preference
        localStorage.setItem('theme', isDark ? 'dark' : 'light');
        
        // Add animation class
        themeIcon.classList.add('animate-pulse');
        setTimeout(() => {
            themeIcon.classList.remove('animate-pulse');
        }, 300);
    });
});