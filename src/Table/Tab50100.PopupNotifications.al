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