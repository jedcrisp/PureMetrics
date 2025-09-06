// Blood Pressure Tracker App
class BloodPressureTracker {
    constructor() {
        this.currentSession = {
            readings: [],
            startTime: new Date(),
            id: this.generateId()
        };
        this.sessions = this.loadSessions();
        this.maxReadingsPerSession = 5;
        
        this.initializeElements();
        this.bindEvents();
        this.updateUI();
        this.updateSessionTime();
    }

    initializeElements() {
        // Form elements
        this.form = document.getElementById('bp-form');
        this.systolicInput = document.getElementById('systolic');
        this.diastolicInput = document.getElementById('diastolic');
        this.heartRateInput = document.getElementById('heart-rate');
        this.addReadingBtn = document.getElementById('add-reading-btn');
        
        // Session elements
        this.readingsCount = document.getElementById('readings-count');
        this.sessionTime = document.getElementById('session-time');
        this.readingsContainer = document.getElementById('readings-container');
        this.sessionAverage = document.getElementById('session-average');
        this.avgSystolic = document.getElementById('avg-systolic');
        this.avgDiastolic = document.getElementById('avg-diastolic');
        this.avgHeartRate = document.getElementById('avg-heart-rate');
        
        // Action buttons
        this.saveSessionBtn = document.getElementById('save-session-btn');
        this.clearSessionBtn = document.getElementById('clear-session-btn');
        
        // History elements
        this.toggleHistoryBtn = document.getElementById('toggle-history');
        this.historyContent = document.getElementById('history-content');
        this.historyList = document.getElementById('history-list');
        this.noHistory = document.getElementById('no-history');
    }

    bindEvents() {
        // Form submission
        this.form.addEventListener('submit', (e) => this.handleFormSubmit(e));
        
        // Input validation
        this.systolicInput.addEventListener('input', () => this.validateInputs());
        this.diastolicInput.addEventListener('input', () => this.validateInputs());
        this.heartRateInput.addEventListener('input', () => this.validateInputs());
        
        // Session actions
        this.saveSessionBtn.addEventListener('click', () => this.saveSession());
        this.clearSessionBtn.addEventListener('click', () => this.clearSession());
        
        // History toggle
        this.toggleHistoryBtn.addEventListener('click', () => this.toggleHistory());
    }

    handleFormSubmit(e) {
        e.preventDefault();
        
        if (this.currentSession.readings.length >= this.maxReadingsPerSession) {
            alert(`Maximum ${this.maxReadingsPerSession} readings per session allowed.`);
            return;
        }

        const reading = {
            systolic: parseInt(this.systolicInput.value),
            diastolic: parseInt(this.diastolicInput.value),
            heartRate: this.heartRateInput.value ? parseInt(this.heartRateInput.value) : null,
            timestamp: new Date()
        };

        this.addReading(reading);
        this.form.reset();
        this.validateInputs();
    }

    addReading(reading) {
        this.currentSession.readings.push(reading);
        this.updateUI();
        this.calculateAndDisplayAverage();
    }

    removeReading(index) {
        this.currentSession.readings.splice(index, 1);
        this.updateUI();
        this.calculateAndDisplayAverage();
    }

    calculateAndDisplayAverage() {
        if (this.currentSession.readings.length === 0) {
            this.sessionAverage.style.display = 'none';
            return;
        }

        const averages = this.calculateAverages(this.currentSession.readings);
        
        this.avgSystolic.textContent = Math.round(averages.systolic);
        this.avgDiastolic.textContent = Math.round(averages.diastolic);
        
        if (averages.heartRate) {
            this.avgHeartRate.textContent = `HR: ${Math.round(averages.heartRate)}`;
        } else {
            this.avgHeartRate.textContent = '';
        }
        
        this.sessionAverage.style.display = 'block';
    }

    calculateAverages(readings) {
        const totals = readings.reduce((acc, reading) => {
            acc.systolic += reading.systolic;
            acc.diastolic += reading.diastolic;
            if (reading.heartRate) {
                acc.heartRate += reading.heartRate;
                acc.heartRateCount++;
            }
            return acc;
        }, { systolic: 0, diastolic: 0, heartRate: 0, heartRateCount: 0 });

        return {
            systolic: totals.systolic / readings.length,
            diastolic: totals.diastolic / readings.length,
            heartRate: totals.heartRateCount > 0 ? totals.heartRate / totals.heartRateCount : null
        };
    }

    updateUI() {
        // Update readings count
        this.readingsCount.textContent = `${this.currentSession.readings.length}/${this.maxReadingsPerSession} readings`;
        
        // Update add reading button state
        this.addReadingBtn.disabled = this.currentSession.readings.length >= this.maxReadingsPerSession;
        
        // Update save session button
        this.saveSessionBtn.disabled = this.currentSession.readings.length === 0;
        
        // Update readings display
        this.updateReadingsDisplay();
    }

    updateReadingsDisplay() {
        this.readingsContainer.innerHTML = '';
        
        if (this.currentSession.readings.length === 0) {
            this.readingsContainer.innerHTML = '<p class="no-readings">No readings yet. Add your first reading above!</p>';
            return;
        }

        this.currentSession.readings.forEach((reading, index) => {
            const readingElement = this.createReadingElement(reading, index);
            this.readingsContainer.appendChild(readingElement);
        });
    }

    createReadingElement(reading, index) {
        const div = document.createElement('div');
        div.className = 'reading-item';
        
        const timeStr = reading.timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const heartRateStr = reading.heartRate ? ` • HR: ${reading.heartRate}` : '';
        
        div.innerHTML = `
            <div class="reading-values">
                ${reading.systolic}/${reading.diastolic}${heartRateStr}
            </div>
            <div class="reading-time">
                ${timeStr}
                <button class="remove-reading" onclick="bpTracker.removeReading(${index})">×</button>
            </div>
        `;
        
        return div;
    }

    validateInputs() {
        const systolic = parseInt(this.systolicInput.value);
        const diastolic = parseInt(this.diastolicInput.value);
        const heartRate = this.heartRateInput.value ? parseInt(this.heartRateInput.value) : null;
        
        const isValid = systolic >= 50 && systolic <= 300 && 
                       diastolic >= 30 && diastolic <= 200 && 
                       systolic > diastolic &&
                       (heartRate === null || (heartRate >= 30 && heartRate <= 200));
        
        this.addReadingBtn.disabled = !isValid || this.currentSession.readings.length >= this.maxReadingsPerSession;
    }

    saveSession() {
        if (this.currentSession.readings.length === 0) {
            alert('No readings to save!');
            return;
        }

        const averages = this.calculateAverages(this.currentSession.readings);
        const session = {
            ...this.currentSession,
            endTime: new Date(),
            averages: averages,
            readingCount: this.currentSession.readings.length
        };

        this.sessions.unshift(session);
        this.saveSessions();
        this.clearSession();
        this.updateHistoryDisplay();
        
        // Show success message
        this.showNotification('Session saved successfully!', 'success');
    }

    clearSession() {
        this.currentSession = {
            readings: [],
            startTime: new Date(),
            id: this.generateId()
        };
        this.form.reset();
        this.updateUI();
        this.sessionAverage.style.display = 'none';
    }

    toggleHistory() {
        const isVisible = this.historyContent.style.display !== 'none';
        this.historyContent.style.display = isVisible ? 'none' : 'block';
        this.toggleHistoryBtn.textContent = isVisible ? 'Show History' : 'Hide History';
        
        if (!isVisible) {
            this.updateHistoryDisplay();
        }
    }

    updateHistoryDisplay() {
        if (this.sessions.length === 0) {
            this.historyList.style.display = 'none';
            this.noHistory.style.display = 'block';
            return;
        }

        this.historyList.style.display = 'block';
        this.noHistory.style.display = 'none';
        this.historyList.innerHTML = '';

        this.sessions.forEach(session => {
            const historyElement = this.createHistoryElement(session);
            this.historyList.appendChild(historyElement);
        });
    }

    createHistoryElement(session) {
        const div = document.createElement('div');
        div.className = 'history-item';
        
        const dateStr = session.startTime.toLocaleDateString();
        const timeStr = session.startTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const avgHeartRateStr = session.averages.heartRate ? ` • HR: ${Math.round(session.averages.heartRate)}` : '';
        
        div.innerHTML = `
            <div class="history-details">
                <div class="history-date">${dateStr}</div>
                <div class="history-time">${timeStr}</div>
                <div class="history-stats">${session.readingCount} reading${session.readingCount !== 1 ? 's' : ''}</div>
            </div>
            <div class="history-average">
                ${Math.round(session.averages.systolic)}/${Math.round(session.averages.diastolic)}${avgHeartRateStr}
            </div>
        `;
        
        return div;
    }

    updateSessionTime() {
        const now = new Date();
        const elapsed = Math.floor((now - this.currentSession.startTime) / 1000);
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        
        this.sessionTime.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;
        
        // Update every second
        setTimeout(() => this.updateSessionTime(), 1000);
    }

    generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }

    loadSessions() {
        try {
            const saved = localStorage.getItem('bpSessions');
            return saved ? JSON.parse(saved).map(session => ({
                ...session,
                startTime: new Date(session.startTime),
                endTime: new Date(session.endTime),
                readings: session.readings.map(reading => ({
                    ...reading,
                    timestamp: new Date(reading.timestamp)
                }))
            })) : [];
        } catch (error) {
            console.error('Error loading sessions:', error);
            return [];
        }
    }

    saveSessions() {
        try {
            localStorage.setItem('bpSessions', JSON.stringify(this.sessions));
        } catch (error) {
            console.error('Error saving sessions:', error);
            this.showNotification('Error saving session data', 'error');
        }
    }

    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        // Style the notification
        Object.assign(notification.style, {
            position: 'fixed',
            top: '20px',
            right: '20px',
            padding: '12px 20px',
            borderRadius: '6px',
            color: 'white',
            fontWeight: '600',
            zIndex: '1000',
            opacity: '0',
            transform: 'translateX(100%)',
            transition: 'all 0.3s ease'
        });
        
        // Set background color based on type
        const colors = {
            success: '#28a745',
            error: '#dc3545',
            info: '#17a2b8'
        };
        notification.style.backgroundColor = colors[type] || colors.info;
        
        document.body.appendChild(notification);
        
        // Animate in
        setTimeout(() => {
            notification.style.opacity = '1';
            notification.style.transform = 'translateX(0)';
        }, 100);
        
        // Remove after 3 seconds
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 3000);
    }
}

// Initialize the app when the DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.bpTracker = new BloodPressureTracker();
});
