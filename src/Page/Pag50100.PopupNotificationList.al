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