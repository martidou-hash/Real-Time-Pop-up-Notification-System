codeunit 50101 "Pop-up Notif. Cleanup Job"
{
    Subtype = Normal;

    trigger OnRun()
    var
        Mgt: Codeunit "Pop-up Notification Mgt";
    begin
        // Aquí NO debe haber UI (Message/Confirm)
        Mgt.NotificationOutdated();
    end;
}