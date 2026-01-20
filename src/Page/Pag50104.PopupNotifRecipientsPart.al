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