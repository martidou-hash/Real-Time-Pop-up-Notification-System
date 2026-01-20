/// <summary>
///  tabla muy simple que actúa como almacén de la imagen del cue (indicador) del sistema de notificaciones emergentes.
/// Se usa junto con la página "Pop-up Notification Cue Setup" para permitir que los administradores importen y gestionen la imagen que aparece en el monitor de notificaciones.
/// </summary>
table 50103 "Pop-up Notification Cue"
{
    CaptionML = ENU = 'Pop-up Notification Cue', ESP = 'Indicador de notificación emergente';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[50])
        {
            //Caption = 'Notification key';

            Editable = false;
            NotBlank = false;
            TooltipML = ENU = 'Specifies the primary key for the notification.', ESP = 'Especifica la clave principal para la notificación.';
        }
        field(2; Image; MediaSet)
        {
            CaptionML = ENU = 'Notification', ESP = 'Notificación';
            TooltipML = ENU = 'Specifies the notification image.', ESP = 'Especifica la imagen de la notificación.';
        }
    }
    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}