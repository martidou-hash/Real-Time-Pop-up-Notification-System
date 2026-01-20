permissionset 50100 "Pop-up Notification"
{
    Assignable = true;
    Caption = 'Pop-up Notifications', Locked = true;

    Permissions =
        page "Pop-up Notif. Recipients Part" = X,
        page "Pop-up Notification List" = X,
        page "Pop-up Notification Card" = X,
        page "Pop-up Notification Recipients" = X,
        page "Pop-up Users Selection" = X,
        page "Pop-up Notifications Codes" = X,
        page "Pop-up Notification Monitor" = X,
        tabledata "Pop-up Notifications" = RIMD,
        tabledata "Pop-up Notification Code" = RIMD,
        tabledata "Pop-up Notification Recipients" = RIMD,
        tabledata "Pop-up Notification Cue" = RIMD,
        tabledata "Job Queue Entry" = RIM,
        codeunit "Pop-up Notification Mgt" = X;

}