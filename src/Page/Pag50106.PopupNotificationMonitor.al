/// <summary>
/// Página no visible que monitorea continuamente si hay notificaciones nuevas para el usuario actual y mostrarlas como popups en tiempo real.
/// Se integra en el Role Center mediante la extensión de página "Pop-up Notification Role Center Extension"..
/// Todos los usuarios la tienen activa constantemente en segundo plano mientras usan la aplicación.
/// </summary>
page 50106 "Pop-up Notification Monitor"
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