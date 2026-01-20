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