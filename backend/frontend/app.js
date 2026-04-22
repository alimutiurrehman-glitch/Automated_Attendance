/**
 * Attendance System Dashboard — Client-side JavaScript
 * Handles API status checks, endpoint testing, and UI updates.
 */

// ===== Configuration =====
const API_BASE = window.location.origin;

// ===== DOM Ready =====
document.addEventListener('DOMContentLoaded', () => {
    checkApiStatus();
    setupScrollEffects();

    // Auto-refresh status every 30 seconds
    setInterval(checkApiStatus, 30000);
});

// ===== API Status Check =====
async function checkApiStatus() {
    const statusText = document.getElementById('api-status');
    const statusBadge = document.getElementById('api-badge');
    const versionText = document.getElementById('api-version');
    const responseTime = document.getElementById('response-time');

    try {
        const startTime = performance.now();
        const response = await fetch(`${API_BASE}/health`, {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
        });
        const endTime = performance.now();
        const latency = Math.round(endTime - startTime);

        if (response.ok) {
            const data = await response.json();
            statusText.textContent = 'Operational';
            statusBadge.className = 'status-badge online';
            statusBadge.textContent = '●  Online';
            responseTime.textContent = `${latency}ms`;

            // Get version info from root endpoint
            try {
                const rootResp = await fetch(`${API_BASE}/`);
                const rootData = await rootResp.json();
                versionText.textContent = rootData.version || '1.0.0';
            } catch {
                versionText.textContent = '1.0.0';
            }
        } else {
            setOfflineStatus(statusText, statusBadge, responseTime);
        }
    } catch (error) {
        setOfflineStatus(statusText, statusBadge, responseTime);
    }
}

function setOfflineStatus(statusText, statusBadge, responseTime) {
    statusText.textContent = 'Unreachable';
    statusBadge.className = 'status-badge offline';
    statusBadge.textContent = '●  Offline';
    responseTime.textContent = '—';
}

// ===== Test: Health Check =====
async function testHealth() {
    const responseBox = document.getElementById('health-response');
    responseBox.classList.add('visible');
    responseBox.classList.remove('error');
    responseBox.textContent = 'Sending request...';

    try {
        const startTime = performance.now();
        const response = await fetch(`${API_BASE}/health`);
        const endTime = performance.now();
        const data = await response.json();

        responseBox.textContent = JSON.stringify(data, null, 2)
            + `\n\n// Response time: ${Math.round(endTime - startTime)}ms`
            + `\n// Status: ${response.status} ${response.statusText}`;
        responseBox.classList.remove('error');
    } catch (error) {
        responseBox.textContent = `Error: ${error.message}\n\nMake sure the API server is running.`;
        responseBox.classList.add('error');
    }
}

// ===== Test: Root Endpoint =====
async function testRoot() {
    const responseBox = document.getElementById('root-response');
    responseBox.classList.add('visible');
    responseBox.classList.remove('error');
    responseBox.textContent = 'Sending request...';

    try {
        const startTime = performance.now();
        const response = await fetch(`${API_BASE}/`);
        const endTime = performance.now();
        const data = await response.json();

        responseBox.textContent = JSON.stringify(data, null, 2)
            + `\n\n// Response time: ${Math.round(endTime - startTime)}ms`
            + `\n// Status: ${response.status} ${response.statusText}`;
        responseBox.classList.remove('error');
    } catch (error) {
        responseBox.textContent = `Error: ${error.message}\n\nMake sure the API server is running.`;
        responseBox.classList.add('error');
    }
}

// ===== Scroll Effects =====
function setupScrollEffects() {
    // Navbar background on scroll
    const navbar = document.getElementById('navbar');
    window.addEventListener('scroll', () => {
        if (window.scrollY > 20) {
            navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.3)';
        } else {
            navbar.style.boxShadow = 'none';
        }
    });

    // Intersection Observer for section animations
    const sections = document.querySelectorAll('.section');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.1 });

    sections.forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(30px)';
        section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(section);
    });

    // Active nav link on scroll
    const navLinks = document.querySelectorAll('.nav-link');
    const sectionEls = document.querySelectorAll('.section[id]');

    window.addEventListener('scroll', () => {
        let current = '';
        sectionEls.forEach(section => {
            const sectionTop = section.offsetTop - 100;
            if (scrollY >= sectionTop) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${current}`) {
                link.classList.add('active');
            }
        });
    });
}
