table 50104 "Pop-up Notification Setup"
{
    DataClassification = ToBeClassified;
    CaptionML = ENU = 'Pop-up Notification Setup', ESP = 'Configuración de notificaciones emergentes';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(10; "Cleanup Job Enabled"; Boolean)
        {
            CaptionML = ENU = 'Job Queue', ESP = 'Cola de trabajo';
            ToolTipML = ENU = '', ESP = '';
        }
        field(11; Priority; Enum "Pop-up Job Queue Priority")
        {
            CaptionML = ENU = 'Priority', ESP = 'Prioridad';
            InitValue = Low;
            ToolTipML = ENU = 'Specifies the priority of the job within the job queue category. It is only relevant when a job queue category code is specified.', ESP = 'Especifica la prioridad del trabajo dentro de la categoría de cola de trabajos. Solo es relevante cuando se especifica el código de categoría de cola de trabajos.';
        }
        field(12; Description; Text[250])
        {
            CaptionML = ENU = 'Description', ESP = 'Descripción';
            ToolTipML = ENU = 'Specifies the description of the job queue entry. The description can be edited and updated on the job queue entry card. The description is also displayed in the Job Queue Entries window, but it cannot be updated from that window.', ESP = 'Especifica la descripción del movimiento de cola de trabajos. Se puede editar y actualizar la descripción de la ficha del movimiento de cola de trabajos. La descripción también se muestra en la ventana Movs. cola trabajo, pero no se puede actualizar en dicha ventana.';
        }

        field(20; "Cleanup Interval (Minutes)"; Integer)
        {
            CaptionML = ENU = 'Cleanup Interval (Minutes)', ESP = 'Minutos entre ejecuciones';
            InitValue = 5;
            ToolTipML = ENU = 'Specifies the minimum number of minutes that must elapse between executions of a job queue entry. This field is only relevant if the job queue entry is set up as a recurring job. If you use a number of minutes between runs, the date formula setting is cleared.', ESP = 'Especifica el número mínimo de minutos que deben transcurrir entre las ejecuciones de un movimiento de cola de trabajos. Este campo solo tiene sentido si el movimiento de cola de trabajos está establecido para ser un trabajo periódico. Si usa un n.º de minutos entre ejecuciones, se borra la configuración de la fórmula de fecha';
        }

        field(30; "Job Queue Category Code"; Code[10])
        {
            CaptionML = ENU = 'Job Queue Category Code', ESP = 'Cód. categoría cola trabajos';
            TableRelation = "Job Queue Category".Code;
            ToolTipML = ENU = 'Specifies the job queue category code to which the job queue entry belongs. Select the field to choose a code from the list.', ESP = 'Especifica el código de la categoría de cola de trabajos a la que pertenece el movimiento de la cola de trabajos. Seleccione el campo para seleccionar un código de la lista';
        }

        field(40; "Job Queue Category Description"; Text[100])
        {
            Caption = 'Descripción categoría';
            TableRelation = "Job Queue Category".Description;
            Editable = false;
        }
        field(50; "Contact Email"; Text[250])
        {
            CaptionML = ENU = 'Contact Email', ESP = 'Email de contacto';
            ToolTipML = ENU = 'Specifies the contact email address that will be used to send notifications and alerts.', ESP = 'Especifica la dirección de correo electrónico de contacto que se utilizará para enviar notificaciones y avisos.';

        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure GetOrCreate(): Boolean
    begin
        if Get('SETUP') then
            exit(true);

        Init();
        "Primary Key" := 'SETUP';
        Insert(true);
        exit(true);
    end;
}