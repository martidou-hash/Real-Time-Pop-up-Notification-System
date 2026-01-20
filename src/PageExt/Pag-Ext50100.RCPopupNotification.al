/// <summary>
/// Añade en el Role Center de "Administrador de negocio" la extensión del monitor de notificaciones emergentes.
/// Asegura que al abrir el Role Center se cargue el componente que detecta si el usuario tiene notificaciones pendientes y dispara el pop-up cuando corresponda según "Scheduled DateTime".
/// Se ubica justo antes del control de "Tareas de la cola de trabajos" (Job Queue Tasks Activities).
/// </summary>
pageextension 50100 "RC Pop-up Notification" extends "Business Manager Role Center"
{
    layout
    {
        //addbefore("Job Queue Tasks Activities")
        addafter("Job Queue Tasks Activities")
        {
            part(NotificationMonitor; "Pop-up Notification Monitor")
            {
                ApplicationArea = All;
                ShowFilter = false;
            }
        }
    }
}
