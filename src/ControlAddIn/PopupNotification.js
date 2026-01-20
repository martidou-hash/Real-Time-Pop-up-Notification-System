(function() {
  'use strict';

  let currentNotificationId = null;
  let modalOverlay = null;

  function showInternal(title, message, notificationId, forceShow) {
    console.log('*** showInternal ***', title, message, notificationId, { forceShow });

    const shownKey = 'gdrg_notif_shown_' + notificationId;

    // Solo producción: bloquear si ya se mostró
    if (!forceShow) {
      if (sessionStorage.getItem(shownKey)) {
        console.log('Notification already shown in this session:', notificationId);
        return;
      }
      sessionStorage.setItem(shownKey, Date.now().toString());
    }

    currentNotificationId = notificationId;

    if (modalOverlay) window.HideNotification();

    modalOverlay = document.createElement('div');
    modalOverlay.className = 'gdrg-notification-overlay';
    //esto machaca el CSS. Para modificar el fondo hay que modificar el "0.20" de "background: rgba(0,0,0,0.20) !important;"
    modalOverlay.style.cssText = 'position: fixed !important; top: 0 !important; left: 0 !important; width: 100vw !important; height: 100vh !important; z-index: 2147483647 !important; display: flex !important; justify-content: center !important; align-items: center !important; background: rgba(0,0,0,0.16) !important;';

    //Antes de crear el overlay, elimina los existentes
    const doc = window.parent.document;
    doc.querySelectorAll('.gdrg-notification-overlay').forEach(e => e.remove());

    const modal = document.createElement('div');
    modal.className = 'gdrg-notification-modal';
    modal.style.cssText = 'background: #ffffff;  border-radius: 3px; box-shadow: 0 2px 6px rgba(0,0,0,0.15); border: 1px solid rgba(0,0,0,0.12); max-width: 500px; width: 90%; padding: 0; position: relative; font-family: "Segoe UI", "Segoe WP", Segoe, device-segoe, Tahoma, Helvetica, Arial, sans-serif;';
    /*'background: #B2E9ED;*/
    const header = document.createElement('div');
    header.className = 'gdrg-notification-header';
    header.style.cssText = 'padding: 20px 24px 16px 24px; border-bottom: none;';
    const h2 = document.createElement('h2');
    h2.textContent = title;
    //h2.style.cssText = 'margin: 0; font-size: 18px; font-weight: 700; color: #212121; font-family: "Segoe UI ", "Segoe UI Semilight Web (West European)", -apple-system, BlinkMacSystemFont, Roboto, "Helvetica Neue", sans-serif;';
    h2.style.cssText = 'margin: 0; font-size: 20px; font-weight: 600; color: #1f1f1f; font-family: "Segoe UI", "Segoe WP", Segoe, device-segoe, Tahoma, Helvetica, Arial, sans-serif;';
    header.appendChild(h2);

    const body = document.createElement('div');
    body.className = 'gdrg-notification-body';
    body.style.cssText = 'padding: 20px 24px; font-size: 14px; color: #444444; line-height: 20px;';
    const p = document.createElement('p');
    p.textContent = message;
    p.style.cssText = 'margin: 0; white-space: pre-wrap; word-wrap: break-word;';
    body.appendChild(p);

    const footer = document.createElement('div');
    footer.className = 'gdrg-notification-footer';
    footer.style.cssText = 'padding: 16px 24px 20px 24px; border-top: none; text-align: right; display: flex; justify-content: flex-end; gap: 8px;';
    const btnAccept = document.createElement('button');
    btnAccept.className = 'gdrg-btn-accept';
    btnAccept.textContent = 'Aceptar';
    btnAccept.style.cssText = 'background: #008489; color: white; border: none; border-radius: 0; padding: 8px 32px; font-size: 14px; font-weight: 600; cursor: pointer; font-family: "Segoe UI", "Segoe UI Web (West European)", -apple-system, BlinkMacSystemFont, Roboto, "Helvetica Neue", sans-serif; transition: background 0.1s ease; min-width: 96px;';
    btnAccept.onmouseover = function() { this.style.background = '#00757a'; };
    btnAccept.onmouseout  = function() { this.style.background = '#008489'; };
    btnAccept.onclick = handleAccept;
    footer.appendChild(btnAccept);

    modal.appendChild(header);
    modal.appendChild(body);
    modal.appendChild(footer);
    modalOverlay.appendChild(modal);

    window.parent.document.body.appendChild(modalOverlay);

    setTimeout(() => modalOverlay.classList.add('show'), 10);

    // Recomendación: usa parent document también para el keydown (consistente)
    window.parent.document.addEventListener('keydown', handleEscapeKey);
  }

  window.ShowNotification = function(title, message, notificationId) {
    showInternal(title, message, notificationId, false); // producción
  };

  window.ShowPreviewNotification = function(title, message, notificationId) {
    showInternal(title, message, notificationId, true);  // preview ilimitado
  };

  window.HideNotification = function() {
    if (modalOverlay) {
      modalOverlay.classList.remove('show');

      setTimeout(() => {
        if (modalOverlay && modalOverlay.parentNode) {
          modalOverlay.parentNode.removeChild(modalOverlay);
        }
        modalOverlay = null;
      }, 300);
    }
    window.parent.document.removeEventListener('keydown', handleEscapeKey);
  };

  function handleAccept() {
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnAccepted', [currentNotificationId]);
    window.HideNotification();
  }

  function handleEscapeKey(event) {
    if (event.key === 'Escape' && modalOverlay) {
      handleAccept();
    }
  }

  window.Dispose = function() {
    console.log('*** Dispose called ***');

    // Close any open popup
    window.HideNotification();

    // Stop the timer from Startup.js
    if (window.__PopupNotif_StopTimer) {
        window.__PopupNotif_StopTimer();
    }

    // Reset state
    currentNotificationId = null;
    modalOverlay = null;
};

})();