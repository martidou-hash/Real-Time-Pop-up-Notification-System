# Real-Time Pop-up Notification System
Solución para Microsoft Business Central que permite mostrar notificaciones emergentes en tiempo real, con auditoría de lectura y KPIs integrados en el Role Center.

**Derechos de autor y nota de atribución**

Esta solución se basa en la original "*Alertas en tiempo real para BC: Sistema de notificaciones emergentes para usuarios activos*" del autor [**Gerardo Rentería**](https://gerardorenteria.blog/), publicada en su repositorio de [**GitHub**](https://github.com/gdrgdev/Blog/tree/main/GDRGDev_PopupNotifications).

El código original se utiliza como **inspiración técnica**, habiendo sido posteriormente **modificado, ampliado y adaptado** para cumplir requisitos funcionales, técnicos y de gobernanza propios. La presente documentación y las extensiones descritas no representan una reproducción literal del código original, sino una evolución funcional basada en dicha referencia.

## Características principales

- Pop-ups modales en tiempo real
- Programación y caducidad de mensajes
- Control de lectura por usuario
- KPIs y métricas de impacto
- Compatible con Role Centers estándar y personalizados

## Arquitectura

- AL (tablas, pages, codeunits)
- Control Add-in JavaScript
- Background Tasks para KPIs

## Instalación

1. Publicar la extensión en Business Central.
2. Configurar el Setup inicial.
3. Añadir el monitor al Role Center correspondiente (si es personalizado).

## Extensibilidad

La solución permite extender cualquier Role Center mediante una pageextension estándar.

Más información [aquí](/doc/Real%20Time%20Pop-up%20Notification%20System.md).