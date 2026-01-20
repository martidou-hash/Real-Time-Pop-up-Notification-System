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