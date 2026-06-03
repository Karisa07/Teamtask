# Edge Functions / Notificaciones (TT-13)

Este archivo documenta lo que falta en Supabase para que el flujo funcione:

## 1) Cambios de DB requeridos
- `public.profiles`: agregar `notifications_enabled boolean not null default true`
- `public.notification_events`: tabla para que la Edge Function inserte eventos
  - columnas mínimas sugeridas: `id`, `user_id`, `board_id`, `task_id`, `title`, `body`, `created_at`, `processed_at`

## 2) Políticas (RLS)
- Cliente: puede SELECT de `notification_events` SOLO para `user_id = auth.uid()`
- Edge Function: se inserta con service role (y/o `security definer`) para evitar bloqueos RLS

## 3) Listener en el app
- El cliente debe marcar los eventos ya procesados para evitar duplicados

---

> Importante: En este repo actualmente solo existe `supabase/schema.sql`. No hay carpeta `supabase/functions/` ni funciones Edge. 
> Se deberá crear esa estructura al implementar TT-13-3.

