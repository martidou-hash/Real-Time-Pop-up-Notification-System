// Startup script for Popup Notification Control Add-in
console.log('*** STARTUP.JS LOADED ***');

// Store timer handle so we can stop it later (Dispose)
let timerHandle = null;

// Expose a stop function to be called from PopupNotification.js / Dispose
window.__PopupNotif_StopTimer = function () {
    if (timerHandle) {
        clearInterval(timerHandle);
        timerHandle = null;
        console.log('*** Timer stopped ***');
    }
};

// Notify AL that the control is ready
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnReady', []);
console.log('*** OnReady invoked ***');

// Timer: every 30 seconds check for new notifications
timerHandle = setInterval(function () {
    console.log('*** Timer tick - OnTimerElapsed invoked ***');
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnTimerElapsed', []);
}, 30000);