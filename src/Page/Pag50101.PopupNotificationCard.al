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