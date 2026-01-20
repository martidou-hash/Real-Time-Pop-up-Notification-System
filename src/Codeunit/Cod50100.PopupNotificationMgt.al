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