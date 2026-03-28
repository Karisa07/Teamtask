
# 📋 TeamTask — Colaboración en Tiempo Real

Aplicación móvil colaborativa de gestión de tareas construida con Flutter y Firebase.
Permite que varios usuarios vean y actualicen un tablero compartido en tiempo real,
similar a Trello. Cualquier cambio que haga un usuario aparece de inmediato
en los dispositivos de todos los demás.

---

## 🛠️ Stack Tecnológico

| Categoría | Tecnología |
|-----------|------------|
| Lenguaje | Dart 3.x |
| Framework | Flutter 3.x |
| Base de datos | Firebase Firestore |
| Autenticación | Firebase Auth |
| Estado | Riverpod 2.x |
| Navegación | Go Router |
| Gestión de Proyecto | Jira (Scrum) |
| CI/CD | GitHub Actions |

---

## 🏗️ Arquitectura del Sistema

| Capa | Tecnología | Responsabilidad |
|------|------------|-----------------|
| Presentación | Flutter / Dart | Pantallas, widgets, navegación |
| Estado | Riverpod | Estado global de la aplicación |
| Datos | Repositorios Dart | Acceso a Firebase |
| Base de datos | Firestore | Tareas en tiempo real |
| Autenticación | Firebase Auth | Login y sesiones |
| Notificaciones | Firebase FCM | Push notifications |

---

## 🌿 Estrategia de Ramas (Git Flow)

| Rama | Propósito | Merge |
|------|-----------|---------|
| `main` | Código en producción, siempre estable | Solo desde release |
| `develop` | Integración de features, base del sprint | main al hacer release |
| `feature/TEAM-XX-nombre` | Nueva funcionalidad específica | develop |
| `release/vX.X` | Preparación para producción | main y develop |
| `hotfix/nombre` | Correcciones urgentes en producción | main y develop |

### Convención de Commits

| Prefijo | Uso | 
|---------|-----|
| `feat:` | Nueva funcionalidad | 
| `fix:` | Corrección de bug | 
| `chore:` | Mantenimiento | 
| `docs:` | Documentación | 
| `test:` | Pruebas |

### Flujo de Trabajo

1. Tomar un ticket de Jira y moverlo a **En Progreso**
2. Crear la rama: `git checkout -b feature/TEAM-XX-nombre`
3. Desarrollar con commits frecuentes referenciando el ticket
4. Abrir un **Pull Request** hacia `develop`
5. Solicitar revisión de un compañero
6. Hacer merge tras aprobación
7. El ticket se mueve automáticamente a **Hecho** en Jira

---

## 🚀 Sprints del Proyecto

### Sprint 1 — Fundamentos y Autenticación
> **Semana 1** · Entregable: App con login funcional

| Historia de Usuario |
|-------------------|
| Configurar proyecto Flutter con Firebase |
| Registro de usuario con email y contraseña |
| Login con cuenta de Google |
| Pantalla de perfil de usuario |
| Cierre de sesión seguro |

---

### Sprint 2 — Tablero y CRUD de Tareas
> **Semana 2** · Entregable: Tablero básico operativo

| Historia de Usuario |
|-------------------|
| Crear y visualizar tableros |
| Agregar nueva tarea con título y descripción |
| Marcar tarea como completada o pendiente |
| Eliminar una tarea del tablero |
| Editar título y descripción de una tarea |

---

### Sprint 3 — Colaboración en Tiempo Real
> **Semana 3** · Entregable: Colaboración en vivo

| Historia de Usuario |
|-------------------|
| Sincronización instantánea via Firestore |
| Invitar usuarios al tablero por email |
| Ver miembros activos en el tablero |
| Asignar tareas a miembros específicos |
| Notificación push al asignar una tarea |

---

### Sprint 4 — Pulido y Lanzamiento
> **Semana 4** · Entregable: App publicada

| Historia de Usuario |
|-------------------|
|Animaciones y transiciones de la UI |
|Modo oscuro de la aplicación |
| Tests de integración completos |
|Optimización de rendimiento |


---

## 🔄 Ceremonias Scrum

| Ceremonia | Cuándo | Duración | Objetivo |
|-----------|--------|----------|----------|
| Sprint Planning | Martes inicio de sprint | 1 hora | Seleccionar historias del backlog |
| Daily Standup | Todos los días | 15 min | Qué hice, qué haré, impedimentos |
| Sprint Review | Viernes fin de sprint | 30 min | Demostrar el incremento al equipo |
| Retrospectiva | Viernes fin de sprint | 30 min | Mejorar el proceso del equipo |

### ✅ Definition of Done
Una historia se considera terminada cuando:
- El código pasa todos los tests automatizados
- El Pull Request fue revisado y aprobado por al menos un compañero
- La rama fue fusionada a `develop` sin conflictos
- El ticket en Jira está en estado **Hecho**

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── core/
│   ├── constants/               # Colores, textos, rutas
│   └── theme/                   # Tema visual
├── data/
│   ├── models/
│   │   ├── task_model.dart
│   │   └── user_model.dart
│   └── repositories/
│       ├── auth_repository.dart
│       └── task_repository.dart
├── presentation/
│   ├── auth/
│   │   └── login_screen.dart
│   └── board/
│       ├── board_screen.dart
│       └── task_card.dart
└── providers/
    ├── auth_provider.dart
    └── task_provider.dart
```

---

## ☁️ Servicios Firebase

| Servicio | Función | Plan Gratuito |
|----------|---------|---------------|
| Firebase Auth | Login con email y Google | Usuarios ilimitados |
| Firestore | Tareas y tableros en tiempo real | 1 GB almacenado |
| Firebase FCM | Notificaciones push | Mensajes ilimitados |
| Firebase Analytics | Métricas de uso | Ilimitado |

---

## ⚙️ Cómo correr el proyecto

```bash
# 1. Clonar el repositorio
git clone https://github.com/Karisa07/Teamtask.git
cd Teamtask

# 2. Instalar dependencias
flutter pub get

# 3. Correr la app
flutter run
```
```

Copia todo ese bloque, pégalo en el editor del README en GitHub y guarda. ¿Quieres ajustar algo como los nombres del equipo o agregar integrantes?



