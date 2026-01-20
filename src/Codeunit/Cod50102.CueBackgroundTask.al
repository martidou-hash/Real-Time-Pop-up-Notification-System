codeunit 50102 "Cue Background Task"
{
    trigger OnRun()
    var
        CueField: Text;
        CueValue: Integer;
        Result: Dictionary of [Text, Text];
    begin
        if not Page.GetBackgroundParameters().Get('CueField', CueField) then
            exit;

        CueValue := 0;
        Clear(Result);

        case CueField of
            //Scheduled for active user
            'ScheduledForActiveUser':
                begin
                    CueValue := ScheduledForActiveUser();
                    Result.Add('CueField', 'ScheduledForActiveUser');
                end;
            'LastNotificationTotalRead':
                begin
                    CueValue := LastNotificationTotalRead();
                    Result.Add('CueField', 'LastNotificationTotalRead');
                end;
        end;
        Result.Add('CueValue', Format(CueValue));
        Page.SetBackgroundTaskResult(Result);
    end;

    local procedure ScheduledForActiveUser(): Integer
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
    begin

        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("User ID", UserId());
        PopUpNotificationRecipients.SetRange(Status, PopUpNotificationRecipients.Status::Scheduled);
        PopUpNotificationRecipients.SetRange("Read DateTime", 0DT);
        PopUpNotificationRecipients.SetFilter("Expiration DateTime", '>%1', CurrentDateTime);
        exit(PopUpNotificationRecipients.Count);
    end;

    procedure ScheduledForActiveUserDrillDown()
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        PopUpNotificationList: Page "Pop-up Notification Recipients";
    begin
        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("User ID", UserId());
        PopUpNotificationRecipients.SetRange(Status, PopUpNotificationRecipients.Status::Scheduled);
        PopUpNotificationRecipients.SetRange("Read DateTime", 0DT);
        PopUpNotificationRecipients.SetFilter("Expiration DateTime", '>%1', CurrentDateTime);
        PopUpNotificationList.SetTableView(PopUpNotificationRecipients);
        PopUpNotificationList.SetRecord(PopUpNotificationRecipients);
        PopUpNotificationList.LookUpMode(true);
        PopUpNotificationList.Run();
    end;

    local procedure LastNotificationTotalRead(): Integer
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        PopUpNotifications: Record "Pop-up Notifications";
        LastEntryNo: Integer;
        Total: Integer;
        TotalRead: Integer;
        Percentage: Decimal;
    begin

        PopUpNotifications.Reset();
        PopUpNotifications.SetRange(Status, PopUpNotifications.Status::Sent);

        if PopUpNotifications.FindLast() then begin
            LastEntryNo := PopUpNotifications."Entry No.";
        end;

        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("Entry No.", LastEntryNo);
        Total := PopUpNotificationRecipients.Count;

        PopUpNotificationRecipients.SetFilter("Read DateTime", '<>%1', 0DT);
        TotalRead := PopUpNotificationRecipients.Count;

        if Total = 0 then
            Percentage := 0
        else
            Percentage := Round((TotalRead * 100.0) / Total, 0.1);
        exit(Percentage);
    end;

    procedure LastNotificationTotalReadDrillDown()
    var
        PopUpNotificationRecipients: Record "Pop-up Notification Recipients";
        PopUpNotificationList: Page "Pop-up Notification Recipients";
        PopUpNotifications: Record "Pop-up Notifications";
        LastEntryNo: Integer;
    begin

        PopUpNotifications.Reset();
        PopUpNotifications.SetRange(Status, PopUpNotifications.Status::Sent);

        if PopUpNotifications.FindLast() then begin
            LastEntryNo := PopUpNotifications."Entry No.";
        end;

        PopUpNotificationRecipients.Reset();
        PopUpNotificationRecipients.SetRange("Entry No.", LastEntryNo);
        PopUpNotificationList.SetTableView(PopUpNotificationRecipients);
        PopUpNotificationList.SetRecord(PopUpNotificationRecipients);
        PopUpNotificationList.LookUpMode(true);
        PopUpNotificationList.Run();
    end;
}