# TeamTask — Documentación Técnica por Categoría

---

## Índice

1. [Configuración y Arranque](#1-configuración-y-arranque)
2. [Navegación y Rutas](#2-navegación-y-rutas)
3. [Tema y Diseño Visual](#3-tema-y-diseño-visual)
4. [Autenticación](#4-autenticación)
5. [Repositorios (Capa de Datos)](#5-repositorios-capa-de-datos)
6. [Providers (Estado Global)](#6-providers-estado-global)
7. [Modelos de Datos](#7-modelos-de-datos)
8. [Screens (Pantallas)](#8-screens-pantallas)
9. [Sheets (Bottom Sheets Modales)](#9-sheets-bottom-sheets-modales)
10. [Widgets Reutilizables](#10-widgets-reutilizables)
11. [Sub-widgets Internos del Tablero](#11-sub-widgets-internos-del-tablero)
12. [Analíticas y Estadísticas](#12-analíticas-y-estadísticas)
13. [Notificaciones](#13-notificaciones)
14. [Actividad del Tablero](#14-actividad-del-tablero)
15. [Utilidades](#15-utilidades)

---

## 1. Configuración y Arranque

### `main.dart`

Punto de entrada de la aplicación.

**Responsabilidades:**

- Inicializa el plugin de notificaciones locales (`FlutterLocalNotificationsPlugin`).
- Inicializa Supabase con URL y clave anónima desde `SupabaseConstants`.
- Envuelve la app en un `ProviderScope` de Riverpod.
- Activa el listener de eventos de notificaciones (`notificationEventsListenerProvider`) solo cuando hay un usuario autenticado.

**Widget principal:** `TeamTaskApp` (ConsumerStatefulWidget)

```dart
// Activación condicional del listener de notificaciones
if (user != null && user.id.isNotEmpty) {
  ref.read(notificationEventsListenerProvider);
}
```

---

## 2. Navegación y Rutas

### `app_router.dart`

Configura la navegación de la aplicación con **GoRouter**.

**Provider:** `appRouterProvider`

### Rutas

| Ruta                        | Widget              | Notas                                         |
|-----------------------------|---------------------|-----------------------------------------------|
| `/login`                    | `LoginPage`         |                                               |
| `/register`                 | `RegisterPage`      |                                               |
| `/boards`                   | `BoardsListPage`    |                                               |
| `/boards/:boardId`          | `BoardDetailPage`   | Acepta `extra` como `String` o `Map`          |
| `/boards/:boardId/stats`    | `StatisticsPage`    | `extra` como `String` (boardName)             |
| `/profile`                  | `ProfilePage`       |                                               |

### Lógica de redirección

- Si el usuario **no está autenticado** y accede a rutas protegidas → redirige a `/login`.
- Si el usuario **está autenticado** y visita `/login` o `/register` → redirige a `/boards`.
- Las rutas de callback OAuth se redirigen a `/login` para que Supabase procese el token.

### `_AuthNotifier`

`ChangeNotifier` interno que reacciona a cambios en `authStateProvider` y notifica al router para que reevalúe las redirecciones.

### Paso de parámetros en `/boards/:boardId`

```dart
// extra puede ser String (solo nombre) o Map (nombre + focusTaskId)
if (extra is String) {
  boardName = extra;
} else if (extra is Map) {
  boardName = extra['boardName'] ?? 'Tablero';
  focusTaskId = extra['focusTaskId'];
}
```

---

## 3. Tema y Diseño Visual

### `app_theme.dart`

Define el sistema de diseño visual de la aplicación.

**Clase:** `AppTheme` (solo estática, constructor privado)

### Paleta de colores

| Constante       | Color hex   | Uso                        |
|-----------------|-------------|----------------------------|
| `primaryColor`  | `#6366F1`   | Color principal (índigo)   |
| `secondaryColor`| `#8B5CF6`   | Secundario (violeta)       |
| `successColor`  | `#10B981`   | Éxito / completado         |
| `errorColor`    | `#EF4444`   | Errores                    |
| `warningColor`  | `#F59E0B`   | Advertencias               |
| `accentColor`   | `#06B6D4`   | Acento (cian)              |
| `googleRed`     | `#DB4437`   | Botón Google               |
| `githubDark`    | `#24292E`   | Botón GitHub               |
| `appleBlack`    | `#000000`   | Botón Apple                |

### `lightTheme`

Configura un `ThemeData` con Material 3 que incluye:

- `AppBarTheme` — transparente, sin elevación.
- `ElevatedButtonTheme` — fondo `primaryColor`, bordes redondeados (14 px), altura mínima 52 px.
- `OutlinedButtonTheme` — borde `#E2E8F0`, misma forma.
- `InputDecorationTheme` — fondo blanco, borde inactivo `#E2E8F0`, borde activo `primaryColor` (2 px).

---

## 4. Autenticación

### `auth_provider.dart`

Gestión de autenticación con Supabase.

### Providers

| Provider                  | Tipo                          | Descripción                                              |
|---------------------------|-------------------------------|----------------------------------------------------------|
| `supabaseClientProvider`  | `Provider<SupabaseClient>`    | Instancia global del cliente Supabase                    |
| `authStateProvider`       | `StreamProvider<User?>`       | Stream del usuario autenticado (incluye valor inicial)   |
| `currentUserProvider`     | `Provider<User?>`             | Snapshot sincrónico del usuario actual                   |
| `authServiceProvider`     | `Provider<AuthService>`       | Servicio con métodos de autenticación                    |

### `AuthService`

Encapsula las operaciones de autenticación:

| Método                  | Descripción                                                          |
|-------------------------|----------------------------------------------------------------------|
| `signInWithEmail`       | Inicia sesión con email y contraseña                                 |
| `signUpWithEmail`       | Registra usuario y crea registro en tabla `profiles`                 |
| `signInWithGoogle`      | OAuth con Google (modo navegador externo)                            |
| `signInWithGitHub`      | OAuth con GitHub                                                     |
| `signInWithApple`       | OAuth con Apple                                                      |
| `signOut`               | Cierra la sesión                                                     |
| `parseError`            | Traduce mensajes de error de Supabase a español                      |

**Nota:** Al registrarse, se realiza un `upsert` en la tabla `profiles` con `id`, `email` y `full_name`.

---

## 5. Repositorios (Capa de Datos)

### `board_repository.dart`

Capa de acceso a datos para tableros y tareas.

### `BoardRepository` — Métodos principales

| Método                    | Descripción                                                              |
|---------------------------|--------------------------------------------------------------------------|
| `getBoards(userId)`       | Retorna tableros propios + tableros donde el usuario es miembro          |
| `getBoardStats(boardId)`  | Llama RPC `get_board_stats` y retorna un `BoardStats`                    |
| `createBoard(...)`        | Crea tablero con código de invitación y agrega al creador como miembro   |
| `joinBoardByCode(...)`    | Valida el código y agrega al usuario como miembro                        |
| `getInviteCode(boardId)`  | Obtiene el código de invitación de un tablero                            |
| `getTasks(boardId)`       | Lista tareas de un tablero (sin realtime)                                |
| `createTask(...)`         | Inserta una tarea nueva                                                  |
| `updateTaskStatus(...)`   | Cambia el estado; si es `completed` registra `completed_at`              |
| `updateTaskAssignedUser`  | Asigna o desasigna un usuario a una tarea                                |
| `deleteTask(taskId)`      | Elimina una tarea                                                        |
| `watchTasks(boardId)`     | Stream realtime de tareas (Supabase `.stream()`)                         |
| `fetchBoardMembers`       | Lista miembros del tablero con su perfil (`full_name`, `email`)          |
| `fetchActorName(userId)`  | Obtiene el nombre o email de un usuario desde `profiles`                 |
| `logActivity(...)`        | Inserta un evento en la tabla `activity_log`                             |

**Generación de código de invitación:** `_generateCode()` genera 6 caracteres alfanuméricos en mayúsculas de forma determinista a partir del timestamp.

---

### `activity_repository.dart`

Gestiona la lectura de eventos de actividad del tablero.

### Tipos de evento (`eventType`)

| Valor                  | Emoji | Descripción                  |
|------------------------|-------|------------------------------|
| `task_created`         | 📝    | Tarea creada                 |
| `task_completed`       | ✅    | Tarea completada             |
| `task_status_changed`  | 🔄    | Estado cambiado              |
| `task_assigned`        | 👤    | Tarea asignada a un usuario  |
| `task_unassigned`      | ➖    | Asignación removida          |
| `task_deleted`         | 🗑️    | Tarea eliminada              |

Propiedad `label` genera un texto legible en español, por ejemplo:
- `"Juan creó "Revisar PR"`
- `"Ana asignó "Deploy" a Carlos"`

`watchBoardActivity(boardId, limit)` — Stream realtime de los últimos N eventos de un tablero, ordenados por `created_at` descendente.

---

### `profile_repository.dart`

Gestiona el perfil del usuario en la tabla `profiles` y el almacenamiento de avatares.

### `ProfileRepository` — Métodos

| Método           | Descripción                                                                          |
|------------------|--------------------------------------------------------------------------------------|
| `getProfile`     | Obtiene el perfil por `userId` (`maybeSingle`, retorna `null` si no existe)          |
| `updateProfile`  | Actualiza `full_name` en `profiles`                                                  |
| `uploadAvatar`   | Sube imagen al bucket `Avatars`, actualiza `avatar_url` en `profiles` y retorna la URL pública |

**Ruta en Storage:** `{userId}/{timestamp}.jpg`

---

## 6. Providers (Estado Global)

### `board_provider.dart`

| Provider                      | Tipo                                    | Descripción                                             |
|-------------------------------|-----------------------------------------|---------------------------------------------------------|
| `boardRepositoryProvider`     | `Provider<BoardRepository>`             | Instancia del repositorio                               |
| `boardsProvider`              | `FutureProvider<List<Board>>`           | Lista de tableros del usuario autenticado               |
| `createBoardProvider`         | `Provider<CreateBoardService>`          | Servicio para crear tablero e invalidar caché           |
| `joinBoardProvider`           | `Provider<JoinBoardService>`            | Servicio para unirse a tablero e invalidar caché        |
| `tasksStreamProvider`         | `StreamProvider.family<List<Task>>`     | Stream realtime de tareas por `boardId`                 |
| `tasksFilteredProvider`       | `Provider.family<List<Task>>`           | Tareas sin las eliminadas localmente                    |
| `tasksByStatusProvider`       | `Provider.family<Map<String,List>>`     | Tareas agrupadas por `pending`/`in_progress`/`completed`|
| `statsProvider`               | `FutureProvider.family<BoardStats>`     | Estadísticas del tablero (se actualiza con el stream)   |
| `boardMembersProvider`        | `FutureProvider.family<List<Map>>`      | Miembros del tablero                                    |
| `taskActionsProvider`         | `Provider.family<TaskActions>`          | Acciones sobre tareas (CRUD + log de actividad)         |

### `TaskActions`

Clase que orquesta las operaciones sobre tareas registrando actividad:

| Método                        | Descripción                                                  |
|-------------------------------|--------------------------------------------------------------|
| `createTask(...)`             | Crea tarea y registra evento `task_created`                  |
| `updateStatus(...)`           | Cambia estado y registra `task_completed` o `task_status_changed` |
| `assignTaskToUser(...)`       | Asigna/desasigna y registra `task_assigned` / `task_unassigned` |
| `deleteTask(taskId)`          | Eliminación optimista: oculta la tarea localmente antes de la llamada remota |

**Eliminación optimista:** Al eliminar, la tarea se agrega inmediatamente a `_deletedTaskIdsProvider` para ocultarla en la UI. Si la operación falla, se revierte.

---

### `activity_provider.dart`

| Provider                     | Tipo                                          | Descripción                                     |
|------------------------------|-----------------------------------------------|-------------------------------------------------|
| `activityRepositoryProvider` | `Provider<ActivityRepository>`                | Instancia del repositorio                       |
| `activityFeedProvider`       | `StreamProvider.family<List<ActivityEvent>>`  | Stream de actividad por `boardId`; retorna `[]` si el ID está vacío |

---

### `profile_provider.dart`

| Provider                   | Tipo                        | Descripción                                      |
|----------------------------|-----------------------------|--------------------------------------------------|
| `profileRepositoryProvider`| `Provider<ProfileRepository>`| Instancia del repositorio                        |
| `profileProvider`          | `FutureProvider<Profile?>`  | Perfil del usuario autenticado; `null` si no hay sesión |
| `profileActionsProvider`   | `Provider<ProfileActions>`  | Acciones sobre el perfil                         |

### `ProfileActions`

| Método        | Descripción                                             |
|---------------|---------------------------------------------------------|
| `updateName`  | Actualiza el nombre e invalida `profileProvider` para refrescar |

---

## 7. Modelos de Datos

### `Board`

| Campo               | Tipo        | Descripción                        |
|---------------------|-------------|-------------------------------------|
| `id`                | `String`    | UUID del tablero                   |
| `name`              | `String`    | Nombre del tablero                 |
| `description`       | `String?`   | Descripción opcional               |
| `emoji`             | `String`    | Emoji representativo               |
| `createdBy`         | `String`    | UUID del creador                   |
| `createdAt`         | `DateTime`  | Fecha de creación                  |
| `taskCount`         | `int`       | Total de tareas                    |
| `completedCount`    | `int`       | Tareas completadas                 |
| `inviteCode`        | `String?`   | Código de invitación de 6 chars    |

Propiedad calculada: `completionPercentage` = `completedCount / taskCount`.

---

### `Task`

| Campo               | Tipo        | Descripción                              |
|---------------------|-------------|------------------------------------------|
| `id`                | `String`    | UUID de la tarea                         |
| `boardId`           | `String`    | UUID del tablero al que pertenece        |
| `title`             | `String`    | Título                                   |
| `description`       | `String?`   | Descripción opcional                     |
| `status`            | `String`    | `pending` / `in_progress` / `completed`  |
| `priority`          | `String`    | `low` / `medium` / `high`               |
| `createdBy`         | `String`    | UUID del creador                         |
| `assignedUserId`    | `String?`   | Usuario asignado (solo 1)               |

Getters: `isCompleted`, `isInProgress`, `isPending`.

---

### `BoardStats`

Estadísticas de un tablero: `total`, `pending`, `inProgress`, `completed`, `percentage`. Se obtienen vía RPC `get_board_stats`.

---

### `ActivityEvent`

| Campo             | Tipo       | Descripción                              |
|-------------------|------------|------------------------------------------|
| `id`              | `String`   | UUID del evento                          |
| `boardId`         | `String`   | Tablero al que pertenece                 |
| `taskId`          | `String?`  | Tarea relacionada                        |
| `taskTitle`       | `String?`  | Título de la tarea en el momento del evento |
| `eventType`       | `String`   | Tipo de evento                           |
| `actorUserId`     | `String`   | UUID del usuario que realizó la acción   |
| `actorName`       | `String?`  | Nombre del actor                         |
| `targetUserName`  | `String?`  | Nombre del usuario afectado (asignación) |
| `createdAt`       | `DateTime` | Timestamp del evento                     |

---

### `Profile`

| Campo       | Tipo       | Descripción               |
|-------------|------------|---------------------------|
| `id`        | `String`   | UUID (igual al de Auth)   |
| `email`     | `String`   | Email del usuario         |
| `fullName`  | `String?`  | Nombre completo           |
| `avatarUrl` | `String?`  | URL pública del avatar    |
| `createdAt` | `DateTime` | Fecha de creación         |

---

## 8. Screens (Pantallas)

### `login_page.dart`

Pantalla de inicio de sesión. Soporta autenticación por email/contraseña y OAuth.

**Widget:** `LoginPage` (ConsumerStatefulWidget)

### Estado local

| Variable        | Tipo                    | Descripción                                 |
|-----------------|-------------------------|---------------------------------------------|
| `_emailCtrl`    | `TextEditingController` | Campo de correo electrónico                 |
| `_passCtrl`     | `TextEditingController` | Campo de contraseña                         |
| `_obscure`      | `bool`                  | Visibilidad de la contraseña                |
| `_loadingEmail` | `bool`                  | Carga activa para login por email           |
| `_loadingGoogle`| `bool`                  | Carga activa para login con Google          |
| `_loadingGitHub`| `bool`                  | Carga activa para login con GitHub          |
| `_error`        | `String?`               | Mensaje de error visible al usuario         |

`_anyLoading` es un getter que retorna `true` si cualquier método de login está activo, bloqueando todos los botones durante ese tiempo.

### Acciones

| Método          | Descripción                                                        |
|-----------------|--------------------------------------------------------------------|
| `_loginEmail`   | Valida el formulario y llama a `signInWithEmail`                   |
| `_loginGoogle`  | Llama a `signInWithGoogle` (OAuth redirige al navegador externo)   |
| `_loginGitHub`  | Llama a `signInWithGitHub`                                         |
| `_setError`     | Muestra el error en `_ErrorBanner` (sin traducción en login)       |

### Sub-widgets privados

| Widget          | Descripción                                                              |
|-----------------|--------------------------------------------------------------------------|
| `_Header`       | Logo con gradiente (`primaryColor` → `secondaryColor`), título y subtítulo |
| `_OAuthButton`  | Botón outlined con ícono FontAwesome, estado de carga y color propio     |
| `_Divider`      | Separador "o continúa con" entre formulario y OAuth                      |
| `_ErrorBanner`  | Contenedor rojo semitransparente con ícono de error y texto              |
| `_Spinner`      | `CircularProgressIndicator` blanco de 20×20 px                          |

### Navegación

- Enlace a `RegisterPage` mediante `Navigator.push` (no GoRouter, para mantener el back).
- Al autenticarse con éxito, `authStateProvider` actualiza el estado y `GoRouter` redirige automáticamente a `/boards`.

---

### `register_page.dart`

Pantalla de registro de cuenta nueva. Misma estructura de OAuth que LoginPage con el campo adicional de nombre.

**Widget:** `RegisterPage` (ConsumerStatefulWidget)

### Estado local

| Variable        | Tipo                    | Descripción                            |
|-----------------|-------------------------|----------------------------------------|
| `_nameCtrl`     | `TextEditingController` | Nombre completo                        |
| `_emailCtrl`    | `TextEditingController` | Correo electrónico                     |
| `_passCtrl`     | `TextEditingController` | Contraseña (mín. 6 chars)              |
| `_obscure`      | `bool`                  | Toggle visibilidad contraseña          |
| `_loadingEmail` / `_loadingGoogle` / `_loadingGitHub` / `_loadingApple` | `bool` | Estado de carga por método |
| `_error`        | `String?`               | Error traducido por `AuthService.parseError` |

### Validaciones del formulario

| Campo       | Regla                                     |
|-------------|-------------------------------------------|
| Nombre      | No vacío                                  |
| Email       | No vacío + contiene `@`                   |
| Contraseña  | No vacío + mínimo 6 caracteres            |

### Métodos

| Método     | Descripción                                                                    |
|------------|--------------------------------------------------------------------------------|
| `_register`| Valida formulario, llama `signUpWithEmail`, muestra SnackBar de éxito o dialog de error |
| `_oauth`   | Wrapper genérico que gestiona estado de carga y errores para cualquier OAuth   |

**Nota:** Los errores de registro se muestran en un `AlertDialog` (no en `_ErrorBanner`), para dar mayor visibilidad.

### Sub-widgets privados

| Widget       | Descripción                                                                   |
|--------------|-------------------------------------------------------------------------------|
| `_OAuthRow`  | Fila de tres íconos OAuth (Google, GitHub, Apple) en botones cuadrados        |
| `_OAuthIcon` | Botón individual expandido con borde de color, ícono y spinner de carga       |
| `_DividerOr` | Separador "o con email"                                                       |
| `_ErrorBanner`| Igual al de LoginPage                                                        |

---

### `boards_list_page.dart`

Pantalla principal de la app. Muestra todos los tableros del usuario con su progreso.

**Widget:** `BoardsListPage` (ConsumerWidget)

### Estructura de la UI

```
CustomScrollView
├── SliverAppBar (expandedHeight: 120)
│   └── FlexibleSpaceBar → saludo + avatar
├── SliverToBoxAdapter → HomeNotificationsSection
└── SliverPadding → lista de BoardCard / skeleton / empty state
```

### Estados del listado

| Estado     | Widget mostrado      |
|------------|----------------------|
| Cargando   | `_BoardsSkeleton`    |
| Error      | Texto con el error   |
| Vacío      | `_EmptyBoards`       |
| Con datos  | Lista de `BoardCard` |

### FABs (Floating Action Buttons)

| FAB             | Acción                                         |
|-----------------|------------------------------------------------|
| `join` (outline)| Abre `JoinBoardSheet` como `ModalBottomSheet`  |
| `create` (filled)| Abre `CreateBoardSheet` como `ModalBottomSheet`|

### Sub-widgets

#### `BoardCard`

Tarjeta de tablero con emoji, nombre, descripción (truncada a 1 línea), contador de tareas, `LinearProgressIndicator` con `completionPercentage` y animación `fadeIn` + `slideY` escalonada por índice.

#### `_EmptyBoards`

Estado vacío con ícono de dashboard, título y descripción motivacional. Aparece con `fadeIn` a los 200ms.

#### `_BoardsSkeleton`

Tres contenedores grises de 120px de alto con efecto shimmer animado en loop.

---

### `board_detail_page.dart`

Pantalla central de la aplicación. Implementa el tablero Kanban con tres columnas, barra de progreso en tiempo real, gestión de tareas y control de acceso por rol.

**Widget:** `BoardDetailPage` (ConsumerWidget)

### Parámetros

| Parámetro    | Tipo      | Descripción                                                      |
|--------------|-----------|------------------------------------------------------------------|
| `boardId`    | `String`  | UUID del tablero                                                 |
| `boardName`  | `String`  | Nombre mostrado en el AppBar                                     |
| `focusTaskId`| `String?` | ID de una tarea que debe resaltarse (viene de una notificación)  |

### Providers observados

| Provider                        | Uso                                                          |
|---------------------------------|--------------------------------------------------------------|
| `tasksStreamProvider(boardId)`  | Stream realtime de tareas; controla el estado del indicador  |
| `statsProvider(boardId)`        | Estadísticas para la barra de progreso                       |
| `tasksByStatusProvider(boardId)`| Tareas agrupadas para cada columna Kanban                    |
| `profileProvider`               | Avatar del usuario en el AppBar                             |
| `currentUserProvider`           | ID del usuario para determinar si es dueño                   |
| `boardsProvider`                | Lista de tableros para verificar `createdBy`                 |

### AppBar

| Elemento                  | Condición         | Comportamiento                                          |
|---------------------------|-------------------|---------------------------------------------------------|
| Botón estadísticas        | Siempre           | Navega a `/boards/:boardId/stats`                       |
| Botón código de invitación| Solo si `isOwner` | Abre `_showInviteCode` (bottom sheet con el código)     |
| Avatar circular           | Siempre           | Navega a `/profile`; muestra foto o inicial             |
| `_RealtimeIndicator`      | Siempre           | Indicador verde pulsante cuando el stream tiene datos   |

### Detección de dueño (`isOwner`)

Busca el tablero actual en `boardsProvider` y compara su `createdBy` con `currentUser?.id`. Si el tablero no se encuentra, `isOwner` resulta `false`.

### Barra de progreso (header fijo)

Muestra: texto `"{completadas} de {total} completadas"` + porcentaje, `LinearProgressIndicator` de 6 px y fila de tres `_StatChip`. Si `statsAsync` aún no tiene datos, usa `BoardStats` con valores en 0 como fallback.

### Tablero Kanban

`ListView` horizontal con tres columnas `_KanbanColumn`:

| Columna       | Status         | Emoji | Color              |
|---------------|----------------|-------|--------------------|
| Por hacer     | `pending`      | ⏳    | `grey.shade600`    |
| En progreso   | `in_progress`  | 🔄    | `warningColor`     |
| Completada    | `completed`    | ✅    | `successColor`     |

### Flujo completo de una tarea

```
Usuario toca FAB (+)
    → CreateTaskSheet
    → taskActionsProvider.createTask()
    → BoardRepository.createTask() + logActivity('task_created')
    → Supabase inserta en 'tasks'
    → watchTasks() stream emite lista actualizada
    → _KanbanColumn se reconstruye con la nueva tarea
    → statsProvider se actualiza (dependiente del stream)
    → Barra de progreso refleja el nuevo total
```

### FAB

`FloatingActionButton` con fondo `primaryColor` que abre `CreateTaskSheet(boardId: boardId)`. Aparece con animación `scale` a los 400ms (via `flutter_animate`).

---

### `profile_page.dart`

Pantalla de perfil del usuario autenticado.

**Widget:** `ProfilePage` (ConsumerStatefulWidget)

### Funcionalidades

| Función              | Referencia ticket | Descripción                                                         |
|----------------------|-------------------|---------------------------------------------------------------------|
| Ver perfil           | TT-118            | Muestra email, nombre y proveedor de autenticación                  |
| Editar nombre        | TT-119            | Modo edición inline dentro de una `Card`                            |
| Subir foto de perfil | TT-121            | Abre galería, redimensiona a 512×512 px, sube a Supabase Storage    |

### Estado local

| Variable          | Tipo                    | Descripción                                      |
|-------------------|-------------------------|--------------------------------------------------|
| `_nameController` | `TextEditingController` | Campo de nombre editable                         |
| `_isEditing`      | `bool`                  | Alterna entre vista y modo edición del nombre    |
| `_isLoading`      | `bool`                  | Indica carga en curso (nombre o avatar)          |

### Flujo de edición de nombre

1. Usuario toca "Editar" → `_isEditing = true` → aparece `TextField` autoenfocado.
2. Toca "Guardar" → `_saveName()` → llama `profileActionsProvider.updateName()` → invalida `profileProvider`.
3. Toca "Cancelar" → `_isEditing = false`.

### Flujo de subida de avatar

1. `_pickImage()` abre `ImagePicker` con calidad 80 y límite 512×512 px.
2. Llama `profileRepositoryProvider.uploadAvatar()`.
3. Invalida `profileProvider` para refrescar la imagen en pantalla.

---

### `home_page.dart`

Pantalla de bienvenida / placeholder post-login. Usada para verificar la autenticación antes de implementar el tablero completo.

**Widget:** `HomePlaceholderPage` (ConsumerWidget)

**Contenido:** Ícono de check animado con `elasticOut`, nombre del usuario y badge con el proveedor de sesión, card informativa del sprint, sección de notificaciones y botón de cerrar sesión.

**Nota:** Pantalla de sprint. La navegación real usa `BoardsListPage` como destino principal tras el login.

---

## 9. Sheets (Bottom Sheets Modales)

### `create_board_sheet.dart`

Bottom sheet modal para crear un nuevo tablero.

**Widget:** `CreateBoardSheet` (ConsumerStatefulWidget)

### Campos

| Campo        | Tipo       | Obligatorio | Descripción                                  |
|--------------|------------|-------------|----------------------------------------------|
| Nombre       | `TextField`| Sí          | Nombre del tablero                           |
| Descripción  | `TextField`| No          | Descripción opcional                         |
| Emoji        | Selector   | Sí (default `📋`) | Selector horizontal de 16 emojis        |

### Selector de emoji

`ListView` horizontal de 16 emojis predefinidos. El emoji seleccionado se resalta con borde `primaryColor` y fondo semitransparente. Animación `AnimatedContainer` de 200ms al cambiar selección.

### Flujo de creación

1. Valida que el nombre no esté vacío.
2. Llama `createBoardProvider.call(name, description, emoji)`.
3. Cierra el sheet + muestra SnackBar de éxito.
4. En caso de error, muestra SnackBar de error.

---

### `create_task_sheet.dart`

Bottom sheet modal para crear una nueva tarea en un tablero.

**Widget:** `CreateTaskSheet` (ConsumerStatefulWidget) | **Parámetro requerido:** `boardId`

### Campos

| Campo        | Tipo              | Obligatorio        | Descripción                        |
|--------------|-------------------|--------------------|-------------------------------------|
| Título       | `TextField`       | Sí                 | Autofocus al abrir el sheet        |
| Descripción  | `TextField`       | No                 | Máximo 2 líneas                    |
| Prioridad    | `_PriorityOption` | Sí (default `medium`) | Selector de 3 opciones          |

### Selector de prioridad (`_PriorityOption`)

| Opción | Valor    | Color          |
|--------|----------|----------------|
| Baja   | `low`    | `successColor` |
| Media  | `medium` | `warningColor` |
| Alta   | `high`   | `errorColor`   |

Cada opción muestra un ícono de bandera y etiqueta. La seleccionada tiene fondo y borde de color con `AnimatedContainer` de 200ms.

### Flujo de creación

1. Valida título no vacío.
2. Llama `taskActionsProvider(boardId).createTask(...)`.
3. Cierra el sheet. En caso de error muestra SnackBar.

---

### `join_board_sheet.dart`

Bottom sheet modal para unirse a un tablero mediante código de invitación.

**Widget:** `JoinBoardSheet` (ConsumerStatefulWidget)

### Campo de código

`TextField` centrado con `fontSize: 28`, `fontWeight: w800`, `letterSpacing: 8`, máximo 6 caracteres alfanumérico, capitalización automática a mayúsculas y `hintText: 'ABC123'`.

### Validaciones

| Condición             | Mensaje de error                          |
|-----------------------|-------------------------------------------|
| Campo vacío           | "Ingresa el código de invitación"         |
| Longitud ≠ 6          | "El código debe tener 6 caracteres"       |

### Flujo

1. Valida el código localmente.
2. Llama `joinBoardProvider.call(code)`.
3. Al unirse exitosamente: cierra el sheet + SnackBar con el nombre del tablero.
4. En caso de error del servidor: muestra el error en el campo.

---

### `_showInviteCode` (método de `board_detail_page.dart`)

Abre un `ModalBottomSheet` que:

1. Obtiene el código via `boardRepositoryProvider.getInviteCode(boardId)`.
2. Muestra el código en texto grande (`fontSize: 36`, `letterSpacing: 10`, `fontWeight: w900`).
3. Al tocar el código → copia al portapapeles con `Clipboard.setData` + SnackBar de confirmación.

---

## 10. Widgets Reutilizables

### `task_assigned_chip.dart`

Chip interactivo que muestra el estado de asignación de una tarea y permite cambiarla.

**Widget:** `TaskAssignedChip` (ConsumerWidget)

**Parámetros:** `task` (`Task`), `boardId` (`String`)

### Comportamiento

- Si `task.assignedUserId` es `null` o vacío → muestra `"Sin asignar"`.
- Si tiene usuario asignado → muestra `"Asignado"`.
- Al tocar → abre `AssignTaskSheet(boardId, task)` como bottom sheet.

### Estilo

- Fondo `primaryColor` al 8% de opacidad.
- Borde `primaryColor` al 18%, radio 10.
- Ícono de persona + texto en `primaryColor`.

---

### `home_notifications_section.dart`

Componente reutilizable que muestra las notificaciones recientes del usuario. Aparece en `HomePlaceholderPage` y en `BoardsListPage`.

**Widget:** `HomeNotificationsSection` (ConsumerWidget)

### Lógica

- Si `userId` está vacío → retorna `SizedBox.shrink()`.
- Observa `notificationEventsNotifierProvider`.
- Muestra hasta 8 notificaciones con `events.take(8)`.

### Estados

| Estado    | Visualización                                              |
|-----------|-------------------------------------------------------------|
| Cargando  | `CircularProgressIndicator` dentro del shell              |
| Error     | Texto de error dentro del shell                           |
| Vacío     | Mensaje "No tienes notificaciones nuevas."                |
| Con datos | Lista de `_EventRow`                                      |

### `_shell`

Contenedor decorado con borde, padding y encabezado fijo ("Notificaciones recientes" con ícono) que envuelve todos los estados.

### `_EventRow`

Fila de notificación individual. Muestra `title` y `body` truncados. Al tocar: llama `markAsRead(id)` y navega a `/boards/{boardId}`. Muestra ícono de flecha si tiene `boardId` asociado.

---

## 11. Sub-widgets Internos del Tablero

### `_KanbanColumn`

**Tipo:** ConsumerWidget | **Ancho:** 78% del ancho de pantalla

**Estructura:**

```
SizedBox (78% ancho)
└── Column
    ├── Encabezado (emoji + label + badge de conteo)
    └── Expanded
        ├── Estado vacío: ícono inbox + "Sin tareas"
        └── ListView.separated con _TaskCard (animación fadeIn + slideY escalonada)
```

El badge de conteo usa el color de la columna con 10% de opacidad.

---

### `_TaskCard`

**Tipo:** ConsumerWidget | **Interacción principal:** toque → `_showStatusOptions`; deslizar (endToStart) → eliminar

### Swipe to delete (`Dismissible`)

- `direction: endToStart` — deslizar a la izquierda revela fondo rojo con ícono de papelera.
- `confirmDismiss` muestra un `AlertDialog` de confirmación.
- Si confirma → llama `actions.deleteTask(task.id)`.
- **Siempre retorna `false`**: la eliminación optimista del stream ya remueve el widget.

### Layout interno

```
Card
└── InkWell (onTap → _showStatusOptions)
    └── Padding
        ├── Row
        │   ├── Badge de prioridad (color según prioridad)
        │   └── Ícono de estado (toque rápido → cicla al siguiente estado)
        ├── Título (tachado y gris si completada)
        └── Descripción (máx. 2 líneas, si existe)
```

### Colores de prioridad

| Prioridad | Color          | Texto  |
|-----------|----------------|--------|
| `high`    | `errorColor`   | "Alta" |
| `medium`  | `warningColor` | "Media"|
| `low`     | `successColor` | "Baja" |

### Ícono de estado (ciclo rápido)

| Estado actual | Ícono                           | Próximo estado |
|---------------|---------------------------------|----------------|
| `pending`     | `radio_button_unchecked` (gris) | `in_progress`  |
| `in_progress` | `sync` (amarillo)               | `completed`    |
| `completed`   | `check_circle` (verde)          | `pending`      |

### `focusTaskId`

Si `focusTaskId == task.id`, la tarjeta se renderiza con un borde de 2 px en `primaryColor` (útil cuando se llega desde una notificación).

---

### `_showStatusOptions` (método de `_TaskCard`)

Bottom sheet modal con las tres opciones de estado + opción de eliminar:

```
Container (sheet)
└── Column
    ├── Handle (barra gris)
    ├── Título de la tarea
    ├── _StatusOption × 3 (pending / in_progress / completed)
    └── ListTile "Eliminar" (rojo)
```

La opción de eliminar incluye un delay de 300ms antes de mostrar el `AlertDialog` para esperar a que el sheet se cierre visualmente.

---

### `_StatusOption`

`ListTile` con emoji, etiqueta y checkmark si `isSelected`. Bordes redondeados (radio 12). El ítem seleccionado muestra `fontWeight.w700` y un ícono de check en `primaryColor`.

---

### `_StatChip`

Chip de texto con fondo de color semitransparente (10% opacidad) para mostrar conteos de estado en la barra de progreso. Solo texto, sin bordes.

---

### `_RealtimeIndicator`

Indicador de conexión en tiempo real ubicado en el AppBar.

**Tipo:** StatefulWidget con `SingleTickerProviderStateMixin`

**Animación:** `AnimationController` con duración de 1 segundo en loop reverse (pulso continuo).

**Optimización de rebuild:** El `AnimatedBuilder` envuelve **solo** el `Container` del punto (opacidad 0.5 → 1.0). El `Text` queda **fuera** del builder, evitando que se reconstruya 60 veces por segundo.

| Estado         | Color del punto            | Texto           |
|----------------|----------------------------|-----------------|
| Conectado      | `successColor` (pulsante)  | "En vivo" en verde |
| Sin datos aún  | Gris fijo                  | "Conectando..." en gris |

---

## 12. Analíticas y Estadísticas

### `statistics_page.dart`

Página de estadísticas por tablero con gráfico de barras.

**Widget:** `StatisticsPage` (ConsumerWidget) | **Parámetros:** `boardId`, `boardName`

**Dependencias:** `fl_chart` para el `BarChart`; `statsProvider(boardId)` para `BoardStats` vía RPC.

### Estructura

```
Scaffold
└── SingleChildScrollView
    ├── Título "Resumen"
    ├── _KpiCard
    ├── Título "Breakdown por estado"
    └── _BarChartCard
```

### `_KpiCard`

Tarjeta de resumen con texto `"{completadas} de {total} completadas"` + porcentaje, `LinearProgressIndicator` y fila de `_KpiChip` por estado.

### `_KpiChip`

Chip con borde de color semitransparente que muestra el número (bold) y la etiqueta del estado.

| Estado      | Color                  |
|-------------|------------------------|
| Por hacer   | `Colors.grey.shade600` |
| En progreso | `warningColor`         |
| Completada  | `successColor`         |

### `_BarChartCard`

- Si todos los valores son 0: muestra "No hay tareas todavía".
- Si hay datos: renderiza un `BarChart` de `fl_chart` con barras redondeadas (radio 8), títulos en el eje X, tooltips al tocar y `maxY` = valor máximo + 1.

---

## 13. Notificaciones

Gestionadas a través de `flutter_local_notifications` y el provider `notificationEventsListenerProvider`, activado condicionalmente en `main.dart` cuando hay un usuario autenticado.

### Flujo de notificación → pantalla

Al tocar una notificación con `boardId`, la app navega a `/boards/{boardId}` pasando opcionalmente un `focusTaskId` como `extra`. La `BoardDetailPage` recibe ese ID y resalta la tarjeta correspondiente con un borde de 2 px en `primaryColor`.

### `notificationEventsNotifierProvider`

Provee la lista de eventos de notificación observada por `HomeNotificationsSection`. Expone el método `markAsRead(id)` que se llama al tocar una fila en `_EventRow`.

---

## 14. Actividad del Tablero

La actividad se registra automáticamente en cada operación de tarea a través de `TaskActions` y se presenta en tiempo real vía `activityFeedProvider`.

### Registro automático por acción

| Acción en `TaskActions` | Evento registrado          |
|-------------------------|----------------------------|
| `createTask`            | `task_created`             |
| `updateStatus` → completed | `task_completed`        |
| `updateStatus` → otro   | `task_status_changed`      |
| `assignTaskToUser`      | `task_assigned`            |
| `assignTaskToUser(null)`| `task_unassigned`          |

El registro se realiza vía `BoardRepository.logActivity(...)` que inserta en la tabla `activity_log` de Supabase.

---

## 15. Utilidades

### `timeago_es.dart`

Función global para formatear fechas relativas en español.

**Función:** `timeAgoEs(DateTime dateTime) → String`

### Lógica de formateo

| Diferencia         | Formato ejemplo        |
|--------------------|------------------------|
| < 60 segundos      | `"hace 45 s"`          |
| < 60 minutos       | `"hace 12 min"`        |
| < 24 horas         | `"hace 3 h"`           |
| < 30 días          | `"hace 7 d"`           |
| < 12 meses         | `"hace 2 meses"`       |
| ≥ 12 meses         | `"hace 1 año"`         |

Maneja correctamente el singular/plural para "mes/meses" y "año/años".

**Uso típico:** En tarjetas de actividad o notificaciones para mostrar cuándo ocurrió un evento.