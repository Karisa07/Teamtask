# TODO - Real-time activity + Assignación + Miembros (BlackboxAI)

## SQL (Supabase)
- [ ] Crear tabla `public.board_members` (board_id, user_id, joined_at)

- [ ] Habilitar RLS y políticas para que miembros puedan ver/actuar en su tablero
- [ ] Agregar columna `public.tasks.assigned_user_id` (nullable) para asignación (solo 1)
- [ ] Crear trigger `task_assigned` que inserte en `public.activity_log` cuando cambie `assigned_user_id`
- [ ] Ajustar política RLS de `public.activity_log` para que miembros del tablero puedan leer (no solo owner)
- [ ] Ajustar política RLS de `public.tasks` para que miembros puedan leer/actualizar `assigned_user_id`

## Flutter (App)
- [ ] Agregar métodos en `BoardRepository`:
  - [ ] `fetchBoardMembers(boardId)`
  - [ ] `updateTaskAssignedUser(taskId, assignedUserId)`
- [ ] Crear bottom sheet `AssignTaskSheet` con lista de miembros
- [ ] Actualizar `BoardDetailPage` / `TaskCard` para abrir el bottom sheet desde cada tarea
- [ ] Mostrar “Asignado a” en el card (usando nombre/email del miembro)
- [ ] Verificar que navegación desde notificaciones (`focusTaskId`) resalte/visualice la task

## Testing
- [ ] Probar 2 usuarios:
  - [ ] La actividad se ve en tiempo real para miembros
  - [ ] La asignación genera evento `task_assigned` y aparece en activity feed en vivo
  - [ ] El bottom sheet lista solo miembros con acceso
  - [ ] Notificación navega al tablero y enfoca la tarea

