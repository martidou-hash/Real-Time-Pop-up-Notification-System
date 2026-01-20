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