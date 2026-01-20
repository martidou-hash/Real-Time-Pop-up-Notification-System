# Codeunits

## Pop-up Notification Mgt
codeunit 50100 "Pop-up Notification Mgt"
{
    procedure ResolveUserName(UserSecurityId: Guid): Text
    var
        UserRec: Record User;
    begin
        if IsNullGuid(UserSecurityId) then
            exit('');

        if UserRec.Get(UserSecurityId) then
            exit(UserRec."User Name");

        exit('');
    end;

    procedure AddRecipientsFromUsers(EntryNo: Integer)
    var
        Queue: Record "Pop-up Notifications";
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        TempUsers: Record User temporary;
        PopUpUsersSelection: Page "Pop-up Users Selection";
    begin
        if not Queue.Get(EntryNo) then
            Error('No existe la notificación %1.', EntryNo);


        PopUpUsersSelection.RunModal();
        PopUpUsersSelection.GetSelectedUsers(TempUsers);

        if TempUsers.IsEmpty() then
            Error(NoUsersSelectedErrLbl);

        if TempUsers.FindSet() then
            repeat
                if TempUsers."User Name" = '' then
                    continue;

                // Evitar duplicados (PK: EntryNo + UserID)
                if not PopUpNotificationRecipients.Get(EntryNo, TempUsers."User Name") then begin
                    PopUpNotificationRecipients.Init();
                    PopUpNotificationRecipients."Entry No." := EntryNo;
                    PopUpNotificationRecipients."User ID" := TempUsers."User Name";

                    // Copia info necesaria desde Queue
                    PopUpNotificationRecipients."Scheduled DateTime" := Queue."Scheduled DateTime";
                    PopUpNotificationRecipients."Expiration DateTime" := Queue."Expiration DateTime";
                    PopUpNotificationRecipients."Read DateTime" := 0DT;

                    PopUpNotificationRecipients.Insert(true);
                end;
            until TempUsers.Next() = 0;
    end;

    procedure CheckMandatoryFields(EntryNo: Integer): Boolean
    var
        Queue: Record "Pop-up Notifications";
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
    begin
        if Queue.Get(EntryNo) then
            if Queue."Expiration DateTime" = 0DT then
                Error('El campo "Fecha de caducidad" está vacío.');
        if (Queue.Message = '') or (Queue.Title = '') then
            Error('Rellene totalmente el título y el cuerpo de la notificación.');
        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("Entry No.", EntryNo);
        if not PopUpNotificationRecipients.FindFirst() then
            Error('Añada distinatarios de la notificación antes de poder programarla.')
        else begin
            ModifyScheduledDateTime(EntryNo, QUeue."Scheduled DateTime");
            ModifyExpirationDateTime(EntryNo, QUeue."Expiration DateTime");
            exit(true);
        end;
    end;

    procedure CancelNotification(EntryNo: Integer): Boolean
    var
        Queue: Record "Pop-up Notifications";
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        RecipientStatus: Enum "Recipients Status";
    begin
        if Queue.Get(EntryNo) then begin
            ModifyScheduledDateTime(EntryNo, 0DT);
            ModifyExpirationDateTime(EntryNo, 0DT);
            Queue.Status := Queue.Status::Cancelled;
            Queue.Modify();
            UpdateRecipientsStatus(EntryNo, RecipientStatus::Cancelled);
        end;
    end;

    /// <summary>
    /// Gets notifications that the current user has NOT read (personal inbox)
    /// </summary>
    /// <param name="NotificationQueue">The record variable to store the filtered notifications.</param>
    procedure GetActiveNotifications(var PopUpNotifications: Record "Pop-up Notifications")
    var
        NotificationRecipient: Record "Pop-up Notification Recipients";
        CurrentUserID: Code[50];
    begin
        CurrentUserID := CopyStr(UserId(), 1, 50);

        PopUpNotifications.Reset();
        Clear(PopUpNotifications);
        //NotificationRecipient.SetRange(Status, NotificationRecipient.Status::Scheduled);
        // Filter recipients for current user where Read DateTime is blank (unread) and scheduled time has arrived
        NotificationRecipient.SetCurrentKey("User ID", "Read DateTime", "Scheduled DateTime");
        NotificationRecipient.SetRange("User ID", CurrentUserID);
        NotificationRecipient.SetRange("Read DateTime", 0DT); // Blank = unread
        NotificationRecipient.SetFilter("Scheduled DateTime", '<=%1', CurrentDateTime());
        NotificationRecipient.SetFilter("Expiration DateTime", '>%1', CurrentDateTime());

        if NotificationRecipient.FindSet() then
            repeat
                // Get the corresponding notification
                NotificationRecipient."Notification Dispatch Time" := CurrentDateTime();
                NotificationRecipient.Modify(true);
                if PopUpNotifications.Get(NotificationRecipient."Entry No.") then
                    PopUpNotifications.Mark(true);
            until NotificationRecipient.Next() = 0;

        PopUpNotifications.MarkedOnly(true);
    end;

    procedure MarkAsShownToUser(EntryNo: Integer)
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        CurrentUserID: Code[50];
    begin
        CurrentUserID := CopyStr(UserId(), 1, 50);

        // Find the existing record and update read date
        PopUpNotificationRecipients.SetRange("Entry No.", EntryNo);
        PopUpNotificationRecipients.SetRange("User ID", CurrentUserID);
        if PopUpNotificationRecipients.FindFirst() then begin
            PopUpNotificationRecipients."Read DateTime" := CurrentDateTime();
            PopUpNotificationRecipients.Status := PopUpNotificationRecipients.Status::Read;
            PopUpNotificationRecipients.Modify(true);
        end;

    end;

    procedure UpdateRecipientsStatus(EntryNo: Integer; Status: Enum "Recipients Status")
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
    begin
        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange(PopUpNotificationRecipients."Entry No.", EntryNo);
        if PopUpNotificationRecipients.FindSet(true) then
            repeat
                PopUpNotificationRecipients.Status := Status;
                PopUpNotificationRecipients.Modify(false);
            until PopUpNotificationRecipients.Next() = 0;
    end;

    procedure ModifyScheduledDateTime(EntryNo: Integer; ScheduledDateTime: DateTime)
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
    begin
        // if not Queue.Get(EntryNo) then
        //     Error(NotificationErrLbl + '%1.', EntryNo);
        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange(PopUpNotificationRecipients."Entry No.", EntryNo);
        if PopUpNotificationRecipients.FindSet(true) then
            repeat
                PopUpNotificationRecipients."Scheduled DateTime" := ScheduledDateTime;
                PopUpNotificationRecipients.Modify(true);
            until PopUpNotificationRecipients.Next() = 0;
    end;

    procedure ModifyExpirationDateTime(EntryNo: Integer; ExpirationDateTime: DateTime)
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
    begin
        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange(PopUpNotificationRecipients."Entry No.", EntryNo);
        if PopUpNotificationRecipients.FindSet(true) then
            repeat
                PopUpNotificationRecipients."Expiration DateTime" := ExpirationDateTime;
                PopUpNotificationRecipients.Modify(true);
            until PopUpNotificationRecipients.Next() = 0;
    end;

    procedure NotificationOutdated()
    var
        PopUpNotifications: Record "Pop-up Notifications";
    begin
        PopUpNotifications.Reset();
        PopUpNotifications.SetFilter(PopUpNotifications.Status, '%1|%2', PopUpNotifications.Status::Open, PopUpNotifications.Status::Scheduled);
        PopUpNotifications.SetFilter(PopUpNotifications."Scheduled DateTime", '<%1', CurrentDateTime());
        if PopUpNotifications.FindSet() then
            repeat
                CancelNotification(PopUpNotifications."Entry No.");
            until PopUpNotifications.Next() = 0;
    end;

    procedure ApplyFromSetup(var Setup: Record "Pop-up Notification Setup")
    var
        jobQueue: Record "Job Queue Entry";
        OldStatus: Option;
    begin
        // 0) Asegura categoría (si el usuario ha cambiado code/desc, lo respeta)
        EnsureJobQueueCategory(Setup."Job Queue Category Code", Setup."Job Queue Category Description");

        // 1) Asegura que existe el Job (si no existe, se crea en On Hold para configurarlo “en frío”)
        EnsureCleanupJobExists(jobQueue);

        // 2) Guardar estado actual
        OldStatus := jobQueue.Status;

        // 3) Deshabilitar temporalmente (On Hold) para aplicar cambios sin que se ejecute
        if jobQueue.Status <> jobQueue.Status::"On Hold" then begin
            jobQueue.Status := jobQueue.Status::"On Hold";
            jobQueue.Modify(true);
        end;

        // 4) Aplicar configuración desde Setup (incluye Descripción + Prioridad)
        ApplySetupToCleanupJob(jobQueue, Setup);

        // 5) Restaurar estado original (Ready/On Hold/…)
        if jobQueue.Status <> OldStatus then begin
            jobQueue.Status := OldStatus;
            jobQueue.Modify(true);
        end;
    end;

    local procedure EnsureJobQueueCategory(CategoryCode: Code[10]; CategoryDescription: Text[100])
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        if CategoryCode = '' then
            exit;

        if not JobQueueCategory.Get(CategoryCode) then begin
            JobQueueCategory.Init();
            JobQueueCategory.Code := CategoryCode;
            JobQueueCategory.Description := CategoryDescription;
            JobQueueCategory.Insert(true);
        end;
    end;

    local procedure EnsureCleanupJobExists(var jobQueue: Record "Job Queue Entry")
    begin
        if FindCleanupJob(jobQueue) then
            exit;

        jobQueue.Init();
        jobQueue."Object Type to Run" := jobQueue."Object Type to Run"::Codeunit;
        jobQueue."Object ID to Run" := Codeunit::"Pop-up Notif. Cleanup Job";

        // Crear en On Hold por defecto (ApplyFromSetup no debe arrancarlo)
        jobQueue.Status := jobQueue.Status::"On Hold";

        // Valores mínimos razonables (luego ApplySetupToCleanupJob lo completa)
        jobQueue."Recurring Job" := true;
        jobQueue."Earliest Start Date/Time" := CurrentDateTime();

        jobQueue.Insert(true);

        // Releer por seguridad
        FindCleanupJob(jobQueue);
    end;

    local procedure ApplySetupToCleanupJob(var jobQueue: Record "Job Queue Entry"; Setup: Record "Pop-up Notification Setup")
    begin
        // Descripción (asumo que Setup.Description es tu campo de texto)
        jobQueue.Description := Setup.Description;

        // Categoría
        jobQueue."Job Queue Category Code" := Setup."Job Queue Category Code";

        // Prioridad (Option en Job Queue Entry) mapeada desde Enum en Setup
        ApplyPriority(jobQueue, Setup);

        // Recurrente + intervalo
        jobQueue."Recurring Job" := true;
        jobQueue."No. of Minutes between Runs" := Max(1, Setup."Cleanup Interval (Minutes)");

        // Suele ser buena idea “rearmar” el earliest start
        jobQueue."Earliest Start Date/Time" := CurrentDateTime();

        jobQueue.Modify(true);
    end;

    procedure EnableOrCreateCleanupJob(var Setup: Record "Pop-up Notification Setup")
    var
        jobQueue: Record "Job Queue Entry";
    begin
        EnsureJobQueueCategory(Setup."Job Queue Category Code", Setup."Job Queue Category Description");
        EnsureCleanupJobExists(jobQueue);

        // Aplica setup antes de habilitar (opcional pero recomendable)
        ApplySetupToCleanupJob(jobQueue, Setup);

        // Habilita
        jobQueue.Status := jobQueue.Status::Ready;
        jobQueue.Modify(true);
    end;

    local procedure ApplyPriority(var jobQueue: Record "Job Queue Entry"; Setup: Record "Pop-up Notification Setup")
    begin
        case Setup.Priority of
            Setup.Priority::Low:
                jobQueue."Priority Within Category" := jobQueue."Priority Within Category"::Low;

            Setup.Priority::Normal:
                jobQueue."Priority Within Category" := jobQueue."Priority Within Category"::Normal;

            Setup.Priority::High:
                jobQueue."Priority Within Category" := jobQueue."Priority Within Category"::High;
        end;
    end;

    procedure DisableCleanupJob()
    var
        jobQueue: Record "Job Queue Entry";
    begin
        if FindCleanupJob(jobQueue) then begin
            jobQueue.Status := jobQueue.Status::"On Hold";
            jobQueue.Modify(true);
        end;
    end;

    procedure TryGetCleanupJob(var JobQueue: Record "Job Queue Entry"): Boolean
    begin
        exit(FindCleanupJob(JobQueue));
    end;

    local procedure FindCleanupJob(var jobQueue: Record "Job Queue Entry"): Boolean
    begin
        jobQueue.Reset();
        jobQueue.SetRange("Object Type to Run", jobQueue."Object Type to Run"::Codeunit);
        jobQueue.SetRange("Object ID to Run", Codeunit::"Pop-up Notif. Cleanup Job");
        exit(jobQueue.FindFirst());
    end;

    local procedure Max(A: Integer; B: Integer): Integer
    begin
        if A > B then exit(A);
        exit(B);
    end;



    var
        NoUsersSelectedErrLbl: Label 'No se han seleccionado usuarios.';
        NotificationErrLbl: Label 'No existe la notificación';
}

## Pop-up Notif. Cleanup Job
codeunit 50101 "Pop-up Notif. Cleanup Job"
{
    Subtype = Normal;

    trigger OnRun()
    var
        Mgt: Codeunit "Pop-up Notification Mgt";
    begin
        // Aquí NO debe haber UI (Message/Confirm)
        Mgt.NotificationOutdated();
    end;
}

## Cue Background Task
codeunit 50102 "Cue Background Task"
{
    trigger OnRun()
    var
        CueField: Text;
        CueValue: Integer;
        Result: Dictionary of [Text, Text];
    begin
        if not Page.GetBackgroundParameters().Get('CueField', CueField) then
            exit;

        CueValue := 0;
        Clear(Result);

        case CueField of
            //Scheduled for active user
            'ScheduledForActiveUser':
                begin
                    CueValue := ScheduledForActiveUser();
                    Result.Add('CueField', 'ScheduledForActiveUser');
                end;
            'LastNotificationTotalRead':
                begin
                    CueValue := LastNotificationTotalRead();
                    Result.Add('CueField', 'LastNotificationTotalRead');
                end;
        end;
        Result.Add('CueValue', Format(CueValue));
        Page.SetBackgroundTaskResult(Result);
    end;

    local procedure ScheduledForActiveUser(): Integer
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
    begin

        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("User ID", UserId());
        PopUpNotificationRecipients.SetRange(Status, PopUpNotificationRecipients.Status::Scheduled);
        PopUpNotificationRecipients.SetRange("Read DateTime", 0DT);
        PopUpNotificationRecipients.SetFilter("Expiration DateTime", '>%1', CurrentDateTime);
        exit(PopUpNotificationRecipients.Count);
    end;

    procedure ScheduledForActiveUserDrillDown()
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        PopUpNotificationList: Page "Pop-up Notification Recipients";
    begin
        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("User ID", UserId());
        PopUpNotificationRecipients.SetRange(Status, PopUpNotificationRecipients.Status::Scheduled);
        PopUpNotificationRecipients.SetRange("Read DateTime", 0DT);
        PopUpNotificationRecipients.SetFilter("Expiration DateTime", '>%1', CurrentDateTime);
        PopUpNotificationList.SetTableView(PopUpNotificationRecipients);
        PopUpNotificationList.SetRecord(PopUpNotificationRecipients);
        PopUpNotificationList.LookUpMode(true);
        PopUpNotificationList.Run();
    end;

    local procedure LastNotificationTotalRead(): Integer
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        PopUpNotifications: Record "Pop-up Notifications";
        LastEntryNo: Integer;
        Total: Integer;
        TotalRead: Integer;
        Percentage: Decimal;
    begin

        PopUpNotifications.Reset();
        PopUpNotifications.SetRange(Status, PopUpNotifications.Status::Sent);

        if PopUpNotifications.FindLast() then begin
            LastEntryNo := PopUpNotifications."Entry No.";
        end;

        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("Entry No.", LastEntryNo);
        Total := PopUpNotificationRecipients.Count;

        PopUpNotificationRecipients.SetFilter("Read DateTime", '<>%1', 0DT);
        TotalRead := PopUpNotificationRecipients.Count;

        if Total = 0 then
            Percentage := 0
        else
            Percentage := Round((TotalRead * 100.0) / Total, 0.1);
        exit(Percentage);
    end;

    procedure LastNotificationTotalReadDrillDown()
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        PopUpNotificationList: Page "Pop-up Notification Recipients";
        PopUpNotifications: Record "Pop-up Notifications";
        LastEntryNo: Integer;
    begin

        PopUpNotifications.Reset();
        PopUpNotifications.SetRange(Status, PopUpNotifications.Status::Sent);

        if PopUpNotifications.FindLast() then begin
            LastEntryNo := PopUpNotifications."Entry No.";
        end;

        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("Entry No.", LastEntryNo);
        PopUpNotificationList.SetTableView(PopUpNotificationRecipients);
        PopUpNotificationList.SetRecord(PopUpNotificationRecipients);
        PopUpNotificationList.LookUpMode(true);
        PopUpNotificationList.Run();
    end;
}

# ControlAddin
## Pop-up Notification
// Popup Notification Control Add-in
// Control to display centered modal notifications that appear over the entire interface
controladdin "Pop-up Notification"
{
    RequestedHeight = 1;
    RequestedWidth = 1;
    MinimumHeight = 1;
    MinimumWidth = 1;
    VerticalStretch = false;
    VerticalShrink = false;
    HorizontalStretch = false;
    HorizontalShrink = false;

    Scripts = 'src/ControlAddIn/Startup.js',
              'src/ControlAddIn/PopupNotification.js';
    StyleSheets = 'src/ControlAddIn/PopupNotification.css';

    /// <summary>
    /// Shows the modal popup with the specified message
    /// </summary>
    /// <param name="Title">The title of the notification.</param>
    /// <param name="Message">The message content of the notification.</param>
    /// <param name="NotificationId">The unique identifier of the notification.</param>
    procedure ShowNotification(Title: Text; Message: Text; NotificationId: Integer);

    /// <summary>
    /// Hides the current popup
    /// </summary>
    procedure HideNotification();

    #region Cambios MDV
    procedure ShowPreviewNotification(Title: Text; Message: Text; NotificationId: Integer);
    procedure Dispose();

    #endregion Cambios MDV

    /// <summary>
    /// Event that fires when the control is ready
    /// </summary>
    event OnReady();

    /// <summary>
    /// Event that fires every 30 seconds (timer)
    /// </summary>
    event OnTimerElapsed();

    /// <summary>
    /// Event that fires when the user clicks Accept
    /// </summary>
    /// <param name="NotificationId">The unique identifier of the notification that was accepted.</param>
    event OnAccepted(NotificationId: Integer);
}

## Popup Notification.css
/* Popup Notification - CSS Styles */
/* Modal appears centered over entire interface */

/* Overlay - Covers entire screen */
.gdrg-notification-overlay {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    width: 100% !important;
    height: 100% !important;
    background-color: rgba(0, 0, 0, 0.15) !important;
    z-index: 2147483647 !important;
    display: flex !important;
    justify-content: center !important;
    align-items: center !important;
    opacity: 0;
    transition: opacity 0.3s ease;
    pointer-events: auto !important;
}

.gdrg-notification-overlay.show {
    opacity: 1;
}

/* Modal container */
.gdrg-notification-modal {
    background: #ffffff;
    /*background: #B2E9ED;*/
    border-radius: 1px;
    box-shadow: 0 2px 6px rgba(0,0,0,.0.15);
    border: 1px solid rgba(0, 0, 0, 0.12);
    max-width: 500px;
    width: 90%;
    max-height: 80vh;
    display: flex;
    flex-direction: column;
    transform: scale(0.9);
    transition: transform 0.3s ease;
    overflow: hidden;
    font-family: "Segoe UI", "Segoe WP", Segoe, device-segoe, Tahoma, Helvetica, Arial, sans-serif;
    font-stretch: 100%;
}

.gdrg-notification-overlay.show .gdrg-notification-modal {
    transform: scale(1);
}

/* Header */
.gdrg-notification-header {
    padding: 24px 24px 16px 24px;
    border-bottom: none;
}

.gdrg-notification-header h2 {
    font-family: "Segoe UI", "Segoe WP", Segoe, device-segoe, Tahoma, Helvetica, Arial, sans-serif;
    margin: 0;
    font-size: 20px;
    font-weight: 600;
    line-height: 28px;
    color: #1f1f1f;
}

/* Body */
.gdrg-notification-body {
    padding: 2px;
    flex: 1;
    overflow-y: auto;
}

.gdrg-notification-body p {
    font-family: "Segoe UI", "Segoe WP", Segoe, device-segoe, Tahoma, Helvetica, Arial, sans-serif;
    /*font-stretch: 100%;*/
    margin: 0;
    font-size: 14px;
    font-weight: 400;
    letter-spacing: normal;
    line-height: 20px;
    color: #444444;
    white-space: pre-wrap;
    word-wrap: break-word;
}

/* Footer */
.gdrg-notification-footer {
    padding: 16px 24px;
    border-top: none;
    display: flex;
    justify-content: flex-end;
}

/* Botón aceptar */
.gdrg-btn-accept {
    background-color: #008489;
    color: white;
    border: none;
    border-radius: 0;
    padding: 10px 32px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    transition: background-color 0.2s ease;
}

.gdrg-btn-accept:hover {
    background-color: #00757a;
}

.gdrg-btn-accept:active {
    background-color: #00686c;
}

.gdrg-btn-accept:focus {
    outline: 2px solid #008489;
    outline-offset: 2px;
}

/* Responsive */
@media (max-width: 600px) {
    .gdrg-notification-modal {
        width: 95%;
        max-width: none;
    }
    
    .gdrg-notification-header,
    .gdrg-notification-body,
    .gdrg-notification-footer {
        padding: 16px;
    }
}

## PopUpNotification.js
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

## Startup.js
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

# Enum
## Notification Status
enum 50100 "Notification Status"
{
    Extensible = true;

    value(0; "Open") { CaptionML = ENU = 'Open', ESP = 'Abierto'; }
    value(1; "Scheduled") { CaptionML = ENU = 'Scheduled', ESP = 'Programado'; }
    value(2; "Sent") { CaptionML = ENU = 'Sent', ESP = 'Enviado'; }
    value(3; "Cancelled") { CaptionML = ENU = 'Cancelled', ESP = 'Cancelado'; }
}

## Recipients Status
enum 50101 "Recipients Status"
{
    Extensible = true;

    value(0; "Open") { CaptionML = ENU = 'Open', ESP = 'Abierto'; }
    value(1; "Scheduled") { CaptionML = ENU = 'Scheduled', ESP = 'Programado'; }
    value(2; "Sent") { CaptionML = ENU = 'Sent', ESP = 'Enviado'; }
    value(3; "Read") { CaptionML = ENU = 'Read', ESP = 'Leído'; }
    value(4; "Cancelled") { CaptionML = ENU = 'Cancelled', ESP = 'Cancelado'; }
}

## Pop-up Job Queue Priority
enum 50102 "Pop-up Job Queue Priority"
{
    Extensible = false;

    value(0; Low) { CaptionML = ENU = 'Low', ESP = 'Baja'; }
    value(1; Normal) { CaptionML = ENU = 'Normal', ESP = 'Normal'; }
    value(2; High) { CaptionML = ENU = 'High', ESP = 'Alta'; }
}

# Page
## Pop-up Notification List
page 50100 "Pop-up Notification List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Pop-up Notifications";
    QueryCategory = 'Pop-up Notification List';
    CaptionML = ENU = 'Pop-up Notification List', ESP = 'Lista de notificaciones emergentes';
    Editable = false;
    CardPageId = "Pop-up Notification Card";
    SourceTableView = sorting("Entry No.") order(descending);

    AdditionalSearchTerms = '';
    AboutTitle = '';
    AboutText = '';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Editable = false;
                }
                field(Title; Rec.Title)
                {
                }
                field("Status"; Rec."Status")
                {
                    Editable = false;
                }
                field("Category Code"; Rec."Category Code")
                {

                }
                field(TotalRecipients; Rec."Recipients Count")
                {

                }
                field(TotalReads; Rec."Recipients Read Count")
                {

                }
                field(Message; Rec.Message)
                {
                }
                field("Created DateTime"; Rec.SystemCreatedAt)
                {
                    Editable = false;
                }
                field("Scheduled DateTime"; Rec."Scheduled DateTime")
                {
                }
                field("Responsible"; Rec.Responsible)
                {
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
    begin
        Rec.Responsible := PopUpNotificationMgt.ResolveUserName(Rec.SystemModifiedBy);
        //PopUpNotificationMgt.NotificationOutdated();
    end;

    var
}

## Pop-up Notification Card
page 50101 "Pop-up Notification Card"
{
    CaptionML = ENU = 'Pop-up Notification Card', ESP = 'Notificación emergente';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Pop-up Notifications";

    AdditionalSearchTerms = '';
    AboutTitle = '';
    AboutText = '';

    layout
    {
        area(Content)
        {
            group(General)
            {
                CaptionML = ENU = 'General', ESP = 'General';

                field("Entry No."; Rec."Entry No.")
                {
                    CaptionML = ENU = 'Entry No.', ESP = 'Núm. de entrada';
                    ToolTipML = ENU = 'Specifies the unique entry number of the notification.', ESP = 'Especifica el número de entrada único de la notificación.';
                    Editable = false;
                }

                field(ScheduledDateTime; Rec."Scheduled DateTime")
                {
                    CaptionML = ENU = 'Scheduled Date/Time', ESP = 'Fecha y hora programada';
                    ToolTipML = ENU = 'Specifies when the notification should start being displayed to users.', ESP = 'Especifica cuándo debe comenzar a mostrarse la notificación a los usuarios.';
                    ShowMandatory = true;
                    Editable = IsEditable;

                }
                field(ExpirationDate; Rec."Expiration DateTime")
                {
                    CaptionML = ENU = 'Expiration Date', ESP = 'Fecha caducidad';
                    ToolTipML = ENU = 'The date when the notification expires and is no longer valid to be shown.', ESP = 'Fecha en la que la notificación deja de ser válida y no se muestra más.';
                    ShowMandatory = true;
                    Editable = IsEditable;
                }
                field(Status; Rec."Status")
                {
                    CaptionML = ENU = 'Status', ESP = 'Estado';
                    ToolTipML = ENU = 'Specifies the status of the notification.', ESP = 'Especifica el estado de la notificación.';
                    Editable = false;
                }
                field(Responsible; Rec.Responsible)
                {
                    CaptionML = ENU = 'Responsible', ESP = 'Responsable';
                    ToolTipML = ENU = 'Specifies the user who is responsible for the notification.', ESP = 'Especifica el usuario responsable de la notificación.';
                }
                field("Category Code"; Rec."Category Code")
                {
                    CaptionML = ENU = 'Category Code', ESP = 'Categoría';
                    ToolTipML = ENU = 'Specifies the user who is responsible for the notification.', ESP = 'Especifica el usuario responsable de la notificación.';
                    Editable = IsEditable;
                }
            }
            group(TitleGroup)
            {
                CaptionML = ENU = 'Notification Header', ESP = 'Encabezado de la notificación';

                field(Title; Rec.Title)
                {
                    CaptionML = ENU = 'Title', ESP = 'Título';
                    ToolTipML = ENU = 'Specifies the title of the notification.', ESP = 'Especifica el título de la notificación.';
                    ShowMandatory = true;
                    Editable = IsEditable;
                }
            }
            group(MessageGroup)
            {
                //ShowCaption = false;
                CaptionML = ENU = 'Notification Body', ESP = 'Cuerpo de la notificación';

                field(Message; Rec.Message)
                {
                    CaptionML = ENU = 'Message', ESP = 'Mensaje';
                    MultiLine = true;
                    ToolTipML = ENU = 'Specifies the message that will be displayed to all users.', ESP = 'Especifica el mensaje que se mostrará a todos los usuarios.';
                    ShowMandatory = true;
                    Editable = IsEditable;
                }
            }
            group(RecipientsGroup)
            {
                CaptionML = ENU = 'Recipients', ESP = 'Destinatarios';

                part(RecipientsPart; "Pop-up Notif. Recipients Part")
                {
                    SubPageLink = "Entry No." = field("Entry No.");
                    CaptionML = ENU = '', ESP = '';
                    ShowFilter = false;
                    //Editable = IsEditable;
                }
            }
            group(SystemInformationGroup)
            {
                CaptionML = ENU = 'System Information', ESP = 'Información del sistema';

                group(CreationInfo)
                {
                    CaptionML = ENU = 'Creation Information', ESP = 'Información de creación';

                    field(SystemCreatedAt; Rec.SystemCreatedAt)
                    {
                        CaptionML = ENU = 'Created At', ESP = 'Fecha creación';
                        ToolTipML = ENU = 'Specifies the date and time when the notification was created.', ESP = 'Especifica la fecha y hora en que se creó la notificación.';
                        Editable = false;
                    }
                    field(SystemCreatedBy; SystemCreatedByName)
                    {
                        CaptionML = ENU = 'Created By', ESP = 'Creado por';
                        ToolTipML = ENU = 'Specifies the user who is responsible for the notification.', ESP = 'Especifica el usuario responsable de la notificación.';
                        Editable = false;
                    }
                }
                group(ModifiedInfo)
                {
                    CaptionML = ENU = 'Modified Information', ESP = 'Información de modificación';

                    field(SystemModifiedAt; Rec.SystemModifiedAt)
                    {
                        CaptionML = ENU = 'Modified At', ESP = 'Fecha modificación';
                        ToolTipML = ENU = 'Specifies the date and time when the notification was last modified.', ESP = 'Especifica la fecha y hora en que se modificó la notificación por última vez.';
                        Editable = false;
                    }
                    field(SystemModifiedBy; SystemModifiedByName)
                    {
                        CaptionML = ENU = 'Modified By', ESP = 'Modificado por';
                        ToolTipML = ENU = 'Specifies the user who last modified the notification.', ESP = 'Especifica el usuario que modificó la notificación por última vez.';
                        Editable = false;
                    }
                }
            }
            usercontrol(NotificationPopup; "Pop-up Notification")
            {
                trigger OnReady()
                begin
                    IsControlReady := true;
                    // Force immediate verification
                    // CurrPage.Update(false);
                    // CheckForNewNotifications();
                end;

                /// <summary>
                /// Se activa cuando se cumple el temporizador configurado (cada X segundos).
                /// </summary>
                trigger OnTimerElapsed()
                begin
                    // CheckForNewNotifications();
                end;

                /// <summary>
                /// Se activa cuando el usuario acepta (hace clic en Aceptar) en el pop-up de notificación
                /// Marca la notificación como leída para el usuario actual, y la notificación desaparece.
                /// </summary>
                trigger OnAccepted(NotificationId: Integer)
                begin
                    // User clicked OK - NOW mark as read
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Administration)
            {
                CaptionML = ENU = 'Administration', ESP = 'Administrar';
                Image = Post;
                action(Release)
                {
                    CaptionML = ENU = 'Release', ESP = 'Lanzar';
                    ToolTipML = ENU = 'Releases the notification to be scheduled.', ESP = 'Lanza la notificación para que se programe su ejecución.';
                    Image = Post;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Status <> Rec.Status::Scheduled;

                    trigger OnAction()
                    var
                        PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                        RecipientStatus: Enum "Recipients Status";
                    begin
                        if Rec.Status = Rec.Status::Sent then
                            Error(ScheduleErrLbl);
                        if Rec."Scheduled DateTime" < CurrentDateTime then
                            Error(ScheduledDateTimeNotValidErrLbl);
                        if PopUpNotificationMgt.CheckMandatoryFields(Rec."Entry No.") then
                            PopUpNotificationMgt.ModifyScheduledDateTime(Rec."Entry No.", Rec."Scheduled DateTime");
                        PopUpNotificationMgt.ModifyExpirationDateTime(Rec."Entry No.", Rec."Expiration DateTime");
                        Rec.Validate(Status, Rec.Status::Scheduled);
                        CurrPage.SaveRecord();
                        PopUpNotificationMgt.UpdateRecipientsStatus(Rec."Entry No.", RecipientStatus::Scheduled);
                        Rec.Get(Rec."Entry No.");
                        CurrPage.SetRecord(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Reopen)
                {
                    CaptionML = ENU = 'Reopen', ESP = 'Volver a abrir';
                    ToolTipML = ENU = 'Reopens the notification.', ESP = 'Reabre la notificación para su modificación.';
                    Image = ReOpen;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Status <> Rec.Status::Open;

                    trigger OnAction()
                    var
                        PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                        RecipientStatus: Enum "Recipients Status";
                        EntryNo: Integer;
                    begin
                        //CurrPage.SaveRecord();
                        if Rec.Status = Rec.Status::Sent then
                            Error(ReOpenErrLbl);

                        EntryNo := Rec."Entry No.";
                        Rec.Validate(Status, Rec.Status::Open);
                        Rec.Modify(true);
                        Commit();
                        PopUpNotificationMgt.UpdateRecipientsStatus(EntryNo, RecipientStatus::Open);
                        Rec.Get(EntryNo);
                        CurrPage.SetRecord(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Cancel)
                {
                    CaptionML = ENU = 'Cancel', ESP = 'Cancelar';
                    ToolTipML = ENU = 'Cancels the notification.', ESP = 'Cancela la notificación.';
                    Image = Pause;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Status <> Rec.Status::Cancelled;

                    trigger OnAction()
                    var
                        PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                        RecipientStatus: Enum "Recipients Status";
                    begin
                        if Rec.Status = Rec.Status::Sent then
                            Error(ReOpenErrLbl);
                        PopUpNotificationMgt.CancelNotification(Rec."Entry No.");
                        Rec.Get(Rec."Entry No.");
                        CurrPage.SetRecord(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Preview)
                {
                    CaptionML = ENU = 'Preview', ESP = 'Vista previa';
                    ToolTipML = ENU = '', ESP = '';
                    Image = Export;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    Enabled = Rec.Title <> '';

                    trigger OnAction()
                    var
                        //PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                        PreviewCounter: Integer;
                    begin
                        PreviewCounter += 1;
                        CurrPage.NotificationPopup.ShowPreviewNotification(Rec.Title, Rec.Message, -PreviewCounter);

                    end;
                }
            }
            group(Recipients)
            {
                CaptionML = ENU = 'Recipients', ESP = 'Destinatarios';
                Image = Add;
                action(SelectRecipients)
                {
                    CaptionML = ENU = 'Select Recipients', ESP = 'Seleccionar destinatarios';
                    Image = Users;
                    Promoted = true;
                    PromotedOnly = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTipML = ENU = 'Save notification and manually select which users should receive it.', ESP = 'Guardar la notificación y seleccionar manualmente qué usuarios deben recibirla.';

                    trigger OnAction()
                    var
                        PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                    begin
                        if Rec.Status <> Rec.Status::Open then
                            Error('No se pueden añadir destinatarios a una notificación que no esté abierta. Vuelva abrir la notificación para añadir nuevos destinatarios.');
                        PopUpNotificationMgt.AddRecipientsFromUsers(Rec."Entry No.");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
    begin
        SystemCreatedByName := PopUpNotificationMgt.ResolveUserName(Rec.SystemCreatedBy);
        SystemModifiedByName := PopUpNotificationMgt.ResolveUserName(Rec.SystemModifiedBy);
        //PopUpNotificationMgt.NotificationOutdated();
        IsEditable := (Rec.Status = Rec.Status::Open)
    end;

    trigger OnClosePage()
    begin
        if IsControlReady then
            CurrPage.NotificationPopup.Dispose();
    end;


    // local procedure CheckForNewNotifications()
    // var
    //     NotificationQueue: Record "Pop-up Notifications";
    // begin
    //     if not IsControlReady then
    //         exit;
    //     // Show popup - will be marked as read when user clicks OK (OnAccepted)
    //     CurrPage.NotificationPopup.ShowNotification(
    //         NotificationQueue.Title,
    //         NotificationQueue.Message,
    //         NotificationQueue."Entry No."
    //     );
    // end;

    var
        isEditable: Boolean;
        SystemCreatedByName: Text[50];
        SystemModifiedByName: Text[50];
        ScheduledDateTime: DateTime;
        ReOpenErrLbl: Label 'No puede reabrir ni modificar una notificación ya enviada.';
        ScheduleErrLbl: label 'No puede reprogramar una notificación ya enviada.';
        ScheduledDateTimeNotValidErrLbl: Label 'Fecha y hora programada es anterior a la fecha y hora actual.';
        IsControlReady: Boolean;
}

## Pop-up Notification Recipients
/// <summary>
/// Página tipo lista que muestra el historial de destinatarios de notificaciones emergentes y permite agregar manualmente destinatarios.
/// </summary>
page 50102 "Pop-up Notification Recipients"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Pop-up Notification Recipients";
    CaptionML = ENU = 'Pop-up Notification Recipients History', ESP = 'Historial de destinatarios de notificaciones emergentes';
    DelayedInsert = true;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Editable = false;
                }
                field("User ID"; Rec."User ID")
                {
                    TableRelation = User."User Name";
                }
                field(Status; Rec.Status)
                {
                    Editable = false;
                }
                field("Scheduled DateTime"; Rec."Scheduled DateTime")
                {
                    Editable = false;
                }
                field("Expiration DateTime"; Rec."Expiration DateTime")
                {
                    Editable = false;
                }
                field("Dispatch Time"; Rec."Notification Dispatch Time")
                {
                    Editable = false;
                }
                field("Read DateTime"; Rec."Read DateTime")
                {
                    Editable = false;
                }
                field("User Profile ID"; Rec."User Profile ID")
                {
                    Editable = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(OpenNotificationCard)
            {
                CaptionML = ENU = 'Open notification', ESP = 'Abrir notificación';
                ApplicationArea = All;
                Image = PreviewChecks;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    PopUpNotifications: Record "Pop-up Notifications";
                begin
                    if not PopUpNotifications.Get(Rec."Entry No.") then
                        Error('No existe la notificación %1.', Rec."Entry No.");

                    Page.Run(Page::"Pop-up Notification Card", PopUpNotifications);
                end;
            }
        }
    }
}

## Pop-up Users Selection
page 50103 "Pop-up Users Selection"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = User;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Users)
            {
                field("User Name"; Rec."User Name") { }
                field("Full Name"; Rec."Full Name") { }
                field(State; Rec.State) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Select)
            {
                CaptionML = ENU = 'Select', ESP = 'Seleccionar';
                ApplicationArea = All;
                Image = Approve;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    User: Record User;
                begin
                    // Captura multiselección de la lista
                    CurrPage.SetSelectionFilter(User);

                    SelectedUsers.DeleteAll();
                    if User.FindSet() then
                        repeat
                            SelectedUsers := User;
                            SelectedUsers.Insert();
                        until User.Next() = 0;

                    CurrPage.Close();
                end;
            }
        }
    }

    var
        SelectedUsers: Record User temporary;

    procedure GetSelectedUsers(var TempUsers: Record User temporary)
    begin
        TempUsers.DeleteAll();
        if SelectedUsers.FindSet() then
            repeat
                TempUsers := SelectedUsers;
                TempUsers.Insert();
            until SelectedUsers.Next() = 0;
    end;
}

## "Pop-up Notif. Recipients Part
page 50104 "Pop-up Notif. Recipients Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Pop-up Notification Recipients";
    DelayedInsert = true;
    InsertAllowed = true;
    DeleteAllowed = true;
    ModifyAllowed = true;

    CaptionML = ENU = 'Manage', ESP = 'Administrar';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                ShowCaption = false;
                field("User ID"; Rec."User ID")
                {
                    TableRelation = User."User Name";
                }
                field(Status; Rec.Status)
                {
                    Editable = false;
                }
                field("Scheduled DateTime"; Rec."Scheduled DateTime")
                {
                    Editable = false;
                }
                field("Dispatch Time"; Rec."Notification Dispatch Time")
                {
                    Editable = false;
                }
                field("Read DateTime"; Rec."Read DateTime")
                {
                    Editable = false;
                }
                field("Profile ID"; Rec."User Profile ID")
                {
                    Editable = false;
                }
            }
        }
    }
}

## Pop-up Notifications Codes
page 50105 "Pop-up Notifications Codes"
{
    PageType = List;
    ApplicationArea = All;
    CaptionML = ENU = 'Notification category code', ESP = 'Códigos categoría de notificación';
    UsageCategory = Administration;
    SourceTable = "Pop-up Notification Code";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                /// <summary>
                /// Specifies a reason code to attach to the entry.
                /// </summary>
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTipML = ENU = 'Specifies a category code to attach to the entry.', ESP = 'Especifica un código de categoría al registro.';
                }
                /// <summary>
                /// Specifies a description of what the code stands for.
                /// </summary>
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTipML = ENU = 'Specifies a description of what the code stands for.', ESP = 'Especifica una descripción de lo que representa el código.';
                }
            }
        }
    }
} 

## Pop-up Notification Cue Setup
/// <summary>
/// Setup page to configure notification cue image
/// </summary>
page 50106 "Pop-up Notification Cue Setup"
{
    CaptionML = ENU = 'Pop-up Notification Cue Setup', ESP = 'Configuración del indicador de notificación emergente';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Pop-up Notification Cue";

    layout
    {
        area(Content)
        {
            group(Display)
            {
                Caption = 'Notification Image';

                field(Image; Rec.Image)
                {
                    ShowCaption = false;
                    ToolTipML = ENU = 'Specifies the decorative image displayed in the notification monitor.', ESP = 'Especifica la imagen decorativa que se muestra en el monitor de notificaciones.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportImage)
            {
                CaptionML = ENU = 'Import Image', ESP = 'Importar imagen';
                Image = Import;
                ToolTipML = ENU = 'Specifies the action to import an image file to display in the notification monitor.', ESP = 'Especifica la acción para importar un archivo de imagen que se mostrará en el monitor de notificaciones.';
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    FileManagement: Codeunit "File Management";
                    InStr: InStream;
                    FileName: Text;
                    FilterTxt: Label 'Image Files (*.png, *.jpg, *.jpeg, *.bmp)|*.png;*.jpg;*.jpeg;*.bmp', Locked = true;
                begin
                    FileName := FileManagement.BLOBImportWithFilter(TempBlob, '', '', FilterTxt, FilterTxt);
                    if FileName = '' then
                        exit;

                    TempBlob.CreateInStream(InStr);
                    Rec.Image.ImportStream(InStr, FileName);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
            action(DeleteImage)
            {
                CaptionML = ENU = 'Delete Image', ESP = 'Eliminar imagen';
                Image = Delete;
                ToolTipML = ENU = 'Specifies the action to remove the current image from the notification monitor.', ESP = 'Especifica la acción para eliminar la imagen actual del monitor de notificaciones.';
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    if not Confirm('¿Borrar la imagen actual?', false) then
                        exit;

                    Clear(Rec.Image);
                    Rec.Modify(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        // Ensure the shared record exists
        if not Rec.Get('') then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert(true);
        end;
    end;
}

## Pop-up Notification Monitor
/// <summary>
/// Página no visible que monitorea continuamente si hay notificaciones nuevas para el usuario actual y mostrarlas como popups en tiempo real.
/// Se integra en el Role Center mediante la extensión de página "Pop-up Notification Role Center Extension"..
/// Todos los usuarios la tienen activa constantemente en segundo plano mientras usan la aplicación.
/// </summary>
page 50107 "Pop-up Notification Monitor"
{
    CaptionML = ENU = 'Pop-up Notification Monitor', ESP = 'Notificaciones';
    PageType = CardPart;
    ApplicationArea = All;
    UsageCategory = None;
    ShowFilter = false;
    Editable = false;
    RefreshOnActivate = true;
    SourceTable = "Pop-up Notification Cue";
    Permissions =
        tabledata "Pop-up Notifications" = R;

    layout
    {
        area(Content)
        {

            // grid(Grid1)
            // {
            //     ShowCaption = false;

            //     group(Group1)
            //     {
            //         ShowCaption = false;
            //     }
            //     field(Image; Rec.Image)
            //     {

            //     }
            // }
            cuegroup(Cues)
            {
                CaptionML = ENU = 'User', ESP = 'Usuario';
                //CueGroupLayout = Wide;
                field(ScheduledForActiveUser; ScheduledForActiveUser)
                {
                    CaptionML = ENU = 'Scheduled', ESP = 'Programadas';
                    ApplicationArea = All;
                    ToolTipML = ENU = 'Scheduled notifications', ESP = 'Notificaciones programadas.';
                    trigger OnDrillDown()
                    var

                    begin
                        CueBackgroundTask.ScheduledForActiveUserDrillDown();
                    end;
                }
            }
            cuegroup(Admin)
            {
                CaptionML = ENU = 'Admin', ESP = 'Admin';
                //CueGroupLayout = Wide;
                field(LastNotificationTotalRead; LastNotificationTotalRead)
                {
                    CaptionML = ENU = '% Read', ESP = '% Leídas';
                    ApplicationArea = All;
                    ToolTipML = ENU = 'Percentage of messages read in the most recent pop-up notification delivery', ESP = 'Total de notificaciones leídas.';
                    trigger OnDrillDown()
                    var

                    begin
                        CueBackgroundTask.LastNotificationTotalReadDrillDown();
                    end;
                }
            }

            /// <summary>
            /// Componente JavaScript/HTML que muestra los pop-us
            /// </summary>
            usercontrol(NotificationPopup; "Pop-up Notification")
            {
                trigger OnReady()
                begin
                    IsControlReady := true;
                    // Force immediate verification
                    CurrPage.Update(false);
                    CheckForNewNotifications();
                end;

                /// <summary>
                /// Se activa cuando se cumple el temporizador configurado (cada X segundos).
                /// </summary>
                trigger OnTimerElapsed()
                begin
                    CheckForNewNotifications();
                end;

                /// <summary>
                /// Se activa cuando el usuario acepta (hace clic en Aceptar) en el pop-up de notificación
                /// Marca la notificación como leída para el usuario actual, y la notificación desaparece.
                /// </summary>
                trigger OnAccepted(NotificationId: Integer)
                begin
                    // User clicked OK - NOW mark as read
                    NotificationMgt.MarkAsShownToUser(NotificationId);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Setup: Record "Pop-up Notification Setup";
    begin
        IsControlReady := false;

        // Ensure Cue record exists (single shared record for image)
        if not Rec.Get('') then begin
            Rec.Init();
            Rec."Primary Key" := '';
            Rec.Insert(true);
        end;

        Setup.GetOrCreate();

    end;


    trigger OnAfterGetCurrRecord()
    var
        Parameters: Dictionary of [Text, Text];
    begin
        Clear(Parameters);
        //Summary
        Parameters.Set('CueField', 'ScheduledForActiveUser');
        CurrPage.EnqueueBackgroundTask(TaskIdG, Codeunit::"Cue Background Task", Parameters);
        Parameters.Set('CueField', 'LastNotificationTotalRead');
        CurrPage.EnqueueBackgroundTask(TaskIdG, Codeunit::"Cue Background Task", Parameters);
    end;


    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CueField: Text;
        CueValueStr: Text;
        CueValue: Text;
    begin
        if not Results.Get('CueField', CueField) then
            exit;

        case CueField of
            //Summary
            'ScheduledForActiveUser':
                begin
                    if Results.Get('CueValue', CueValueStr) then begin
                        if not Evaluate(ScheduledForActiveUser, CueValueStr) then
                            ScheduledForActiveUser := 0;
                    end else
                        ScheduledForActiveUser := 0;
                end;
            'LastNotificationTotalRead':
                begin
                    if Results.Get('CueValue', CueValueStr) then begin
                        if not Evaluate(LastNotificationTotalRead, CueValueStr) then
                            LastNotificationTotalRead := 0;
                    end else
                        LastNotificationTotalRead := 0;
                end;


        end;

        CurrPage.Update(false);
    end;


    /// <summary>
    /// Verifica notificaciones:
    /// - Obtiene las notificaciones no leídas del usuario actual
    /// - Para cada notificación, muestra el popup
    /// Llama al usercontrol JavaScript con: título, mensaje y número de entrada
    /// </summary>
    local procedure CheckForNewNotifications()
    var
        NotificationQueue: Record "Pop-up Notifications";
    begin
        if not IsControlReady then
            exit;

        // Get unread notifications from user's personal inbox
        NotificationMgt.GetActiveNotifications(NotificationQueue);

        if NotificationQueue.FindSet() then
            repeat
                // Show popup - will be marked as read when user clicks OK (OnAccepted)
                CurrPage.NotificationPopup.ShowNotification(
                    NotificationQueue.Title,
                    NotificationQueue.Message,
                    NotificationQueue."Entry No."
                );
                NotificationQueue.Status := NotificationQueue.Status::Sent;
                NotificationQueue.Modify(true);
            until NotificationQueue.Next() = 0;
    end;

    var
        NotificationMgt: Codeunit "Pop-up Notification Mgt";
        CueBackgroundTask: Codeunit "Cue Background Task";
        IsControlReady: Boolean;
        TaskIdG: Integer;
        ScheduledForActiveUser, LastNotificationTotalRead : Integer;

}

## Pop-up Notification Setup
page 50108 "Pop-up Notification Setup"
{
    CaptionML = ENU = 'Pop-up Notifications Setup', ESP = 'Conf. notificaciones emergentes';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Pop-up Notification Setup";
    UsageCategory = Administration;
    DataCaptionExpression = '';

    layout
    {
        area(content)
        {
            group(Status)
            {
                field("Cleanup Job Enabled"; Rec."Cleanup Job Enabled")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Contact Email"; Rec."Contact Email")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }

            }
            group("Configuración actual (Job activo)")
            {
                Visible = JobEnabled;

                field(JobDescription; JobDescription)
                {
                    Caption = 'Descripción';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(JobCategoryCode; JobCategoryCode)
                {
                    Caption = 'Categoría';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(JobPriority; JobPriority)
                {
                    Caption = 'Prioridad';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(JobIntervalMinutes; JobIntervalMinutes)
                {
                    Caption = 'Intervalo (minutos)';
                    ApplicationArea = All;
                    Editable = false;
                }
            }

            group("Configuración (Job inactivo)")
            {
                Visible = not JobEnabled;

                field(Description; Rec.Description)
                {
                    Caption = 'Descripción';
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Cleanup Interval (Minutes)"; Rec."Cleanup Interval (Minutes)")
                {
                    ApplicationArea = All;
                    Editable = true;
                    MinValue = 1;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ApplyJobQueue)
            {
                Caption = 'Aplicar configuración';
                Image = Apply;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = not JobEnabled;

                trigger OnAction()
                var
                    PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                begin
                    CurrPage.SaveRecord();
                    PopUpNotificationMgt.ApplyFromSetup(Rec);
                    LoadJobState();
                    CurrPage.Update(false);
                    Message('Configuración aplicada.');
                end;
            }

            action(EnableJob)
            {
                Caption = 'Habilitar';
                Image = Start;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = not JobEnabled;

                trigger OnAction()
                var
                    PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                begin
                    CurrPage.SaveRecord();
                    PopUpNotificationMgt.EnableOrCreateCleanupJob(Rec);
                    LoadJobState();
                    CurrPage.Update(false);
                    Message('Limpieza automática habilitada.');
                end;
            }

            action(DisableJob)
            {
                Caption = 'Deshabilitar';
                Image = Pause;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                begin
                    PopUpNotificationMgt.DisableCleanupJob();
                    LoadJobState();
                    CurrPage.Update(false);
                    Message('Limpieza automática deshabilitada.');
                end;
            }
        }
    }

    local procedure LoadJobState()
    var
        Mgt: Codeunit "Pop-up Notification Mgt";
        JQ: Record "Job Queue Entry";
    begin
        JobEnabled := false;

        if Mgt.TryGetCleanupJob(JQ) then begin
            JobEnabled := (JQ.Status = JQ.Status::Ready);

            // Si existe, mostramos valores actuales del Job (aunque esté On Hold también te interesa)
            JobDescription := JQ.Description;
            JobCategoryCode := JQ."Job Queue Category Code";
            JobIntervalMinutes := JQ."No. of Minutes between Runs";

            // Map Option -> Enum para mostrar
            JobPriority := MapJobPriorityToEnum(JQ);
        end else begin
            // Si no existe, muestra defaults o vacío
            JobDescription := '';
            JobCategoryCode := '';
            JobIntervalMinutes := 0;
            JobPriority := JobPriority::Normal;
        end;

        // Refresca el indicador del setup (NO editable) si quieres que refleje el estado real
        Rec."Cleanup Job Enabled" := JobEnabled;
    end;

    local procedure MapJobPriorityToEnum(JobQueueEntry: Record "Job Queue Entry"): Enum "Pop-up Job Queue Priority"
    var
        PriorityEnum: Enum "Pop-up Job Queue Priority";
    begin
        // Ajusta los valores según los options reales de tu entorno
        case JobQueueEntry."Priority Within Category" of
            JobQueueEntry."Priority Within Category"::Low:
                exit(PriorityEnum::Low);
            JobQueueEntry."Priority Within Category"::Normal:
                exit(PriorityEnum::Normal);
            JobQueueEntry."Priority Within Category"::High:
                exit(PriorityEnum::High);
        end;

        exit(PriorityEnum::Normal);
    end;

    trigger OnOpenPage()
    begin
        Rec.GetOrCreate();
        LoadJobState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LoadJobState();
    end;

    var
        JobEnabled: Boolean;

        // Valores “reales” del Job (solo lectura)
        JobDescription: Text[250];
        JobCategoryCode: Code[10];
        JobIntervalMinutes: Integer;
        JobPriority: Enum "Pop-up Job Queue Priority";
}

# PageExt

## RC Pop-up Notification"
/// <summary>
/// Añade en el Role Center de "Administrador de negocio" la extensión del monitor de notificaciones emergentes.
/// Asegura que al abrir el Role Center se cargue el componente que detecta si el usuario tiene notificaciones pendientes y dispara el pop-up cuando corresponda según "Scheduled DateTime".
/// Se ubica justo antes del control de "Tareas de la cola de trabajos" (Job Queue Tasks Activities).
/// </summary>
pageextension 50100 "RC Pop-up Notification" extends "Business Manager Role Center"
{
    layout
    {
        //addbefore("Job Queue Tasks Activities")
        addafter("Job Queue Tasks Activities")
        {
            part(NotificationMonitor; "Pop-up Notification Monitor")
            {
                ApplicationArea = All;
                ShowFilter = false;
            }
        }
    }
}

# Tables
## Pop-up Notifications
table 50100 "Pop-up Notifications"
{
    DataClassification = CustomerContent;
    LookupPageId = "Pop-up Notification List";
    DrillDownPageId = "Pop-up Notification List";
    DataCaptionFields = "Entry No.", Title;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            CaptionML = ENU = 'Entry No.', ESP = 'Entry No.';
            AutoIncrement = true;
            ToolTipML = ENU = 'Specifies the unique entry number for the notification.', ESP = 'Especifica el número de entrada único para la notificación.';
        }
        field(10; Title; Text[100])
        {
            CaptionML = ENU = 'Title', ESP = 'Título';
            ToolTipML = ENU = 'Specifies the title of the notification message.', ESP = 'Especifica el título del mensaje de notificación.';
        }
        field(20; Message; Text[2048])
        {
            CaptionML = ENU = 'Message', ESP = 'Mensaje';
            ToolTipML = ENU = 'Specifies the content of the notification message.', ESP = 'Especifica el contenido del mensaje de notificación.';
        }
        field(21; Status; Enum "Notification Status")
        {
            CaptionML = ENU = 'Status', ESP = 'Estado';
            ToolTipML = ENU = 'Specifies the current status of the notification.', ESP = 'Especifica el estado actual de la notificación.';
        }
        field(40; "Scheduled DateTime"; DateTime)
        {
            CaptionML = ENU = 'Scheduled DateTime', ESP = 'Fecha y hora programada';
            ToolTipML = ENU = 'Specifies when the notification should start being displayed to users.', ESP = 'Especifica cuándo debe comenzar a mostrarse la notificación a los usuarios.';
            AllowInCustomizations = Never;

            trigger OnValidate()
            var
                TypeHelper: Codeunit "Type Helper";
            begin
                if TypeHelper.CompareDateTime("Scheduled DateTime", CurrentDateTime()) < 0 then
                    Error(DateTimePastErrLbl);
                if (Rec."Expiration DateTime" <> 0DT) and (Rec."Expiration DateTime" <= Rec."Scheduled DateTime") then
                    Rec."Expiration DateTime" := 0DT;
            end;
        }
        field(41; "Expiration DateTime"; DateTime)
        {
            CaptionML = ENU = 'Expiration DateTime', ESP = 'Fecha caducidad';
            ToolTipML = ENU = 'The date when the notification expires and is no longer valid to be shown.', ESP = 'Fecha en la que la notificación deja de ser válida y no se muestra más.';

            trigger OnValidate()
            var
                TypeHelper: Codeunit "Type Helper";
            begin
                if TypeHelper.CompareDateTime("Expiration DateTime", CurrentDateTime()) < 0 then
                    Error(DateTimePastErrLbl);
                if TypeHelper.CompareDateTime("Expiration DateTime", "Scheduled DateTime") < 0 then
                    Error(ExpirationDateTimePastErrLbl);
            end;
        }
        field(50; Responsible; Text[50])
        {
            CaptionML = ENU = 'Responsible', ESP = 'Responsable';
            FieldClass = FlowField;
            CalcFormula = lookup(User."User Name" where("User Security ID" = field(SystemModifiedBy)));
            Editable = false;
        }
        field(60; "Category Code"; Code[10])
        {
            TableRelation = "Pop-up Notification Code".Code;
        }
        field(70; "Recipients Count"; Integer)
        {
            CaptionML = ENU = 'Total recipients', ESP = 'Total destinatarios';
            FieldClass = FlowField;
            CalcFormula = count("Pop-up Notification Recipients" where("Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(71; "Recipients Read Count"; Integer)
        {
            CaptionML = ENU = 'Total Read', ESP = 'Total lecturas';
            FieldClass = FlowField;
            CalcFormula = count("Pop-up Notification Recipients" where("Entry No." = field("Entry No."), "Read DateTime" = filter(<> 0DT)));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Title)
        {
        }
        fieldgroup(Brick; Title, Message)
        {
        }
    }

    trigger OnInsert()
    begin
        Rec.Status := Rec.Status::Open;
    end;

    trigger OnModify()
    begin
    end;

    trigger OnDelete()
    begin
        if Status = Status::Sent then
            Error(OnModifySentErrLbl);
    end;

    var
        PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
        DateTimePastErrLbl: Label 'La fecha/hora no puede ser anterior a la fecha/hora actual.';
        ExpirationDateTimePastErrLbl: label 'La fecha/hora de caducidad de la notificación no puede ser anterior a la fecha/hora programada para el envío de la notificación.';
        OnModifyErrLbl: Label 'No se puede modificar una notificación que no esté abierta. Vuelva abrir la notificación para realizar cambios.';
        OnModifySentErrLbl: Label 'No se puede modificar una notificación enviada.';
        OnDeleteSentErrLbl: Label 'No se puede eliminar una notificación enviada.';

}

## Pop-up Notification Code
table 50101 "Pop-up Notification Code"
{
    DataClassification = CustomerContent;
    CaptionML = ENU = 'Notification category code', ESP = 'Código categoría de notificación';
    LookupPageID = "Pop-up Notifications Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            CaptionML = ENU = 'Code', ESP = 'Código';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            CaptionML = ENU = 'Description', ESP = 'Descripción';
        }

    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Description)
        { }
    }
}

## Pop-up Notification Recipients
/// <summary>
/// Esta tabla registra, por cada notificación y por cada usuario, el estado de lectura de la notificación.
/// La cola (Pop-up Notification Queue) define el mensaje. Esta tabla define a quién se le aplica y si ya lo ha visto.
/// El sistema garantiza que:
/// - Cada usuario ve el popup como máximo una vez (independiente de los demás).
/// - Se puede auditar quién lo leyó y cuándo.
/// - Se puede calcular fácilmente lo que le falta por leer a un usuario (pendientes).
/// </summary>
table 50102 "Pop-up Notification Recipients"
{
    CaptionML = ENU = 'Pop-up Notification Recipients', ESP = 'Destinatarios de notificación emergente';
    DataClassification = CustomerContent;
    LookupPageId = "Pop-up Notification Recipients";
    DrillDownPageId = "Pop-up Notification Recipients";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            CaptionML = ENU = 'Notification Entry No.', ESP = 'Número de entrada de notificación';
            TableRelation = "Pop-up Notifications"."Entry No.";
            TooltipML = ENU = 'Specifies the notification entry number that this recipient record is associated with.', ESP = 'Especifica el número de entrada de la notificación con la que está asociado este registro de destinatario.';
        }
        field(2; "User ID"; Code[50])
        {
            CaptionML = ENU = 'User', ESP = 'Usuario';
            DataClassification = EndUserIdentifiableInformation;
            TooltipML = ENU = 'Specifies the user who received the notification.', ESP = 'Especifica el usuario que recibió la notificación.';
        }
        /// <summary>
        /// Se considera que una notificación está pendiente si este campo está vacío y está activa (el "Scheduled DateTime" ha pasado).
        /// </summary>
        field(10; "Read DateTime"; DateTime)
        {
            CaptionML = ENU = 'Read DateTime', ESP = 'Fecha y hora de lectura';
            TooltipML = ENU = 'Specifies when the notification was read by the user.', ESP = 'Especifica cuándo fue leída la notificación por el usuario.';
        }
        field(20; "Scheduled DateTime"; DateTime)
        {
            CaptionML = ENU = 'Scheduled DateTime', ESP = 'Fecha y hora programada';
            TooltipML = ENU = 'Specifies when the notification should start being displayed to the user.', ESP = 'Especifica cuándo debe comenzar a mostrarse la notificación al usuario.';
            AllowInCustomizations = Never;
        }
        field(21; "Expiration DateTime"; DateTime)
        {
            CaptionML = ENU = 'Expiration DateTime', ESP = 'Fecha caducidad';
            ToolTipML = ENU = 'The date when the notification expires and is no longer valid to be shown.', ESP = 'Fecha en la que la notificación deja de ser válida y no se muestra más.';
        }
        field(30; "Notification Dispatch Time"; DateTime)
        {
            CaptionML = ENU = 'Notification Dispatch Time', ESP = 'Fecha y hora emisión';
            ToolTipML = ENU = 'Specifies when the notification is displayed to users.', ESP = 'Especifica cuándo se muestra la notificación a los usuarios.';
            Editable = false;
        }
        field(40; "User Profile ID"; Code[30])
        {
            CaptionML = ENU = 'User Profile', ESP = 'Perfil (rol)';
            FieldClass = FlowField;
            CalcFormula = lookup("User Personalization"."Profile ID" where("User ID" = field("User ID")));
        }
        field(50; Status; Enum "Recipients Status")
        {
            CaptionML = ENU = 'Status', ESP = 'Estado';
            ToolTipML = ENU = '';
        }
    }

    keys
    {
        key(PK; "Entry No.", "User ID")
        {
            Clustered = true;
        }
        key(UserUnread; "User ID", "Read DateTime", "Scheduled DateTime")
        {
            // Optimized key for finding unread notifications for a user that are ready to display
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "User ID", "Read DateTime")
        {
        }
        fieldgroup(Brick; "User ID", "Entry No.", "Read DateTime")
        {
        }
    }

    trigger OnInsert()
    var
        PopUpNotifications: Record "Pop-up Notifications";
    begin
        if not PopUpNotifications.Get("Entry No.") then
            Error('No existe la notificación %1.', "Entry No.");

        if PopUpNotifications.Status <> PopUpNotifications.Status::Open then
            Error('No se pueden añadir destinatarios a una notificación que no esté abierta. Vuelva abrir la notificación para añadir nuevos destinatarios.');

        Rec.Status := Rec.Status::Open;
        Rec."Notification Dispatch Time" := 0DT;
    end;

    var
        OnModifyAlreadySentErrLbl: label 'No puede modificarse una notificación que ya ha sido enviada.';
        OnDeleteAlreadySentErrLbl: label 'No puede eliminarse una notificación que ya ha sido enviada.';
}

## Pop-up Notification Cue
/// <summary>
///  tabla muy simple que actúa como almacén de la imagen del cue (indicador) del sistema de notificaciones emergentes.
/// Se usa junto con la página "Pop-up Notification Cue Setup" para permitir que los administradores importen y gestionen la imagen que aparece en el monitor de notificaciones.
/// </summary>
table 50103 "Pop-up Notification Cue"
{
    CaptionML = ENU = 'Pop-up Notification Cue', ESP = 'Indicador de notificación emergente';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[50])
        {
            //Caption = 'Notification key';

            Editable = false;
            NotBlank = false;
            TooltipML = ENU = 'Specifies the primary key for the notification.', ESP = 'Especifica la clave principal para la notificación.';
        }
        field(2; Image; MediaSet)
        {
            CaptionML = ENU = 'Notification', ESP = 'Notificación';
            TooltipML = ENU = 'Specifies the notification image.', ESP = 'Especifica la imagen de la notificación.';
        }
    }
    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

## Pop-up Notification Setup
table 50104 "Pop-up Notification Setup"
{
    DataClassification = ToBeClassified;
    CaptionML = ENU = 'Pop-up Notification Setup', ESP = 'Configuración de notificaciones emergentes';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(10; "Cleanup Job Enabled"; Boolean)
        {
            Caption = 'Habilitar limpieza automática';
        }
        field(11; Priority; Enum "Pop-up Job Queue Priority")
        {
            CaptionML = ENU = 'Priority', ESP = 'Prioridad';
            InitValue = Low;
        }
        field(12; Description; Text[250])
        {
            CaptionML = ENU = 'Description', ESP = 'Descripción';
        }

        field(20; "Cleanup Interval (Minutes)"; Integer)
        {
            Caption = 'Intervalo (minutos)';
            InitValue = 5;
        }

        field(30; "Job Queue Category Code"; Code[10])
        {
            Caption = 'Categoría Job Queue';
            TableRelation = "Job Queue Category".Code;
        }

        field(40; "Job Queue Category Description"; Text[100])
        {
            Caption = 'Descripción categoría';
            InitValue = 'Notificaciones emergentes';
        }
        field(50; "Contact Email"; Text[250])
        {
            Caption = 'Email de contacto';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure GetOrCreate(): Boolean
    begin
        if Get('SETUP') then
            exit(true);

        Init();
        "Primary Key" := 'SETUP';
        Insert(true);
        exit(true);
    end;
}

# Permission Set

## Pop-up Notification
permissionset 50100 "Pop-up Notification"
{
    Assignable = true;
    Caption = 'Pop-up Notifications', Locked = true;

    Permissions =
        page "Pop-up Notif. Recipients Part" = X,
        page "Pop-up Notification Cue Setup" = X,
        page "Pop-up Notification List" = X,
        page "Pop-up Notification Card" = X,
        page "Pop-up Notification Recipients" = X,
        page "Pop-up Users Selection" = X,
        page "Pop-up Notifications Codes" = X,
        page "Pop-up Notification Monitor" = X,
        tabledata "Pop-up Notifications" = RIMD,
        tabledata "Pop-up Notification Code" = RIMD,
        tabledata "Pop-up Notification Recipients" = RIMD,
        tabledata "Pop-up Notification Cue" = RIMD,
        tabledata "Job Queue Entry" = RIM,
        codeunit "Pop-up Notification Mgt" = X;

}