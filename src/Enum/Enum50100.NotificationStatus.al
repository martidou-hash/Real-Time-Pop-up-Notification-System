enum 50100 "Notification Status"
{
    Extensible = true;

    value(0; "Open") { CaptionML = ENU = 'Open', ESP = 'Abierto'; }
    value(1; "Scheduled") { CaptionML = ENU = 'Scheduled', ESP = 'Programado'; }
    value(2; "Sent") { CaptionML = ENU = 'Sent', ESP = 'Enviado'; }
    value(3; "Cancelled") { CaptionML = ENU = 'Cancelled', ESP = 'Cancelado'; }
}