page 50103 "Pop-up Users Selection"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = User;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    CaptionML = ENU = 'Pop-up users selection', ESP = 'Selección de usuarios';

    layout
    {
        area(Content)
        {
            repeater(Users)
            {
                field("User Name"; Rec."User Name") { }
                field("Full Name"; Rec."Full Name") { }
                field(State; Rec.State) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Select)
            {
                CaptionML = ENU = 'Select', ESP = 'Seleccionar';
                ApplicationArea = All;
                Image = Approve;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    User: Record User;
                begin
                    // Captura multiselección de la lista
                    CurrPage.SetSelectionFilter(User);

                    SelectedUsers.DeleteAll();
                    if User.FindSet() then
                        repeat
                            SelectedUsers := User;
                            SelectedUsers.Insert();
                        until User.Next() = 0;

                    CurrPage.Close();
                end;
            }
        }
    }

    var
        SelectedUsers: Record User temporary;

    procedure GetSelectedUsers(var TempUsers: Record User temporary)
    begin
        TempUsers.DeleteAll();
        if SelectedUsers.FindSet() then
            repeat
                TempUsers := SelectedUsers;
                TempUsers.Insert();
            until SelectedUsers.Next() = 0;
    end;
}