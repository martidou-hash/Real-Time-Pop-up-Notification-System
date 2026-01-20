page 50107 "Pop-up Notification Setup"
{
    CaptionML = ENU = 'Pop-up Notifications Setup', ESP = 'Conf. notificaciones emergentes';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Pop-up Notification Setup";
    UsageCategory = Administration;
    DataCaptionExpression = '';

    layout
    {
        area(content)
        {
            group(Status)
            {
                field("Cleanup Job Enabled"; Rec."Cleanup Job Enabled")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Contact Email"; Rec."Contact Email")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                }

            }
            group("Configuración actual (Job activo)")
            {
                Visible = JobEnabled;

                field(JobDescription; JobDescription)
                {
                    Caption = 'Descripción';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(JobCategoryCode; JobCategoryCode)
                {
                    Caption = 'Categoría';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(JobPriority; JobPriority)
                {
                    Caption = 'Prioridad';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(JobIntervalMinutes; JobIntervalMinutes)
                {
                    Caption = 'Intervalo (minutos)';
                    ApplicationArea = All;
                    Editable = false;
                }
            }

            group("Configuración (Job inactivo)")
            {
                Visible = not JobEnabled;

                field(Description; Rec.Description)
                {
                    Caption = 'Descripción';
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    Editable = true;
                }
                field("Cleanup Interval (Minutes)"; Rec."Cleanup Interval (Minutes)")
                {
                    ApplicationArea = All;
                    Editable = true;
                    MinValue = 1;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ApplyJobQueue)
            {
                Caption = 'Aplicar configuración';
                Image = Apply;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = not JobEnabled;

                trigger OnAction()
                var
                    PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                begin
                    CurrPage.SaveRecord();
                    PopUpNotificationMgt.ApplyFromSetup(Rec);
                    LoadJobState();
                    CurrPage.Update(false);
                    Message('Configuración aplicada.');
                end;
            }

            action(EnableJob)
            {
                Caption = 'Habilitar';
                Image = Start;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = not JobEnabled;

                trigger OnAction()
                var
                    PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                begin
                    CurrPage.SaveRecord();
                    PopUpNotificationMgt.EnableOrCreateCleanupJob(Rec);
                    LoadJobState();
                    CurrPage.Update(false);
                    Message('Limpieza automática habilitada.');
                end;
            }

            action(DisableJob)
            {
                Caption = 'Deshabilitar';
                Image = Pause;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    PopUpNotificationMgt: Codeunit "Pop-up Notification Mgt";
                begin
                    PopUpNotificationMgt.DisableCleanupJob();
                    LoadJobState();
                    CurrPage.Update(false);
                    Message('Limpieza automática deshabilitada.');
                end;
            }
        }
    }

    local procedure LoadJobState()
    var
        Mgt: Codeunit "Pop-up Notification Mgt";
        JQ: Record "Job Queue Entry";
    begin
        JobEnabled := false;

        if Mgt.TryGetCleanupJob(JQ) then begin
            JobEnabled := (JQ.Status = JQ.Status::Ready);

            // Si existe, mostramos valores actuales del Job (aunque esté On Hold también te interesa)
            JobDescription := JQ.Description;
            JobCategoryCode := JQ."Job Queue Category Code";
            JobIntervalMinutes := JQ."No. of Minutes between Runs";

            // Map Option -> Enum para mostrar
            JobPriority := MapJobPriorityToEnum(JQ);
        end else begin
            // Si no existe, muestra defaults o vacío
            JobDescription := '';
            JobCategoryCode := '';
            JobIntervalMinutes := 0;
            JobPriority := JobPriority::Normal;
        end;

        // Refresca el indicador del setup (NO editable) si quieres que refleje el estado real
        Rec."Cleanup Job Enabled" := JobEnabled;
    end;

    local procedure MapJobPriorityToEnum(JobQueueEntry: Record "Job Queue Entry"): Enum "Pop-up Job Queue Priority"
    var
        PriorityEnum: Enum "Pop-up Job Queue Priority";
    begin
        // Ajusta los valores según los options reales de tu entorno
        case JobQueueEntry."Priority Within Category" of
            JobQueueEntry."Priority Within Category"::Low:
                exit(PriorityEnum::Low);
            JobQueueEntry."Priority Within Category"::Normal:
                exit(PriorityEnum::Normal);
            JobQueueEntry."Priority Within Category"::High:
                exit(PriorityEnum::High);
        end;

        exit(PriorityEnum::Normal);
    end;

    trigger OnOpenPage()
    begin
        Rec.GetOrCreate();
        LoadJobState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LoadJobState();
    end;

    var
        JobEnabled: Boolean;

        // Valores “reales” del Job (solo lectura)
        JobDescription: Text[250];
        JobCategoryCode: Code[10];
        JobIntervalMinutes: Integer;
        JobPriority: Enum "Pop-up Job Queue Priority";
}