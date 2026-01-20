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