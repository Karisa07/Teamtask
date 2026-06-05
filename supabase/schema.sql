create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  notifications_enabled boolean not null default true,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;


create policy "Perfil propio"
  on public.profiles for all
  using (auth.uid() = id);


-- Mantener el toggle por defecto al crear perfil
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles(id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name');
  return new;
end;
$$ language plpgsql security definer;



create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Tabla boards
create table public.boards (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  description text,
  created_by  uuid not null references auth.users(id) on delete cascade,
  created_at  timestamptz default now()
);

-- ────────────────────────────────────────────────────────────
-- Evento para que la app dispare flutter_local_notifications
-- ─────────────────────────────────────────────────────────────

create table public.notification_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  board_id uuid not null references public.boards(id) on delete cascade,
  task_id uuid not null,
  title text not null,
  body text not null,
  created_at timestamptz default now(),
  processed_at timestamptz
);

alter table public.notification_events enable row level security;

create policy "Eventos propios - leer"
  on public.notification_events for select
  using (auth.uid() = user_id);

create policy "Eventos propios - procesar"
  on public.notification_events for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Inserción será realizada por trigger (y/o Edge Function) usando service role.
-- No creamos política de INSERT para el cliente.


-- ─────────────────────────────────────────────────────────────
-- Trigger para crear `notification_events` cuando cambia una tarea
-- Este trigger cubre el caso donde la app solo hace update directo en `public.tasks`.
-- ─────────────────────────────────────────────────────────────

create or replace function public.notify_task_change()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.board_id is null then
    return new;
  end if;

  insert into public.notification_events (user_id, board_id, task_id, title, body)
  select
    b.created_by as user_id,
    new.board_id,
    new.id as task_id,
    'Actualización de tarea' as title,
    format('La tarea "%s" fue actualizada.', coalesce(new.title, '')) as body
  from public.boards b
  where b.id = new.board_id;

  return new;
end;
$$;

drop trigger if exists trg_notify_task_change on public.tasks;
create trigger trg_notify_task_change
after update of status, priority, title, description
on public.tasks
for each row
execute function public.notify_task_change();

-- RLS boards
alter table public.boards enable row level security;

create policy "Ver tableros propios"
  on public.boards for select
  using (auth.uid() = created_by);

create policy "Crear tableros"
  on public.boards for insert
  with check (auth.uid() = created_by);

create policy "Eliminar tableros propios"
  on public.boards for delete
  using (auth.uid() = created_by);

-- Tabla tasks
create table public.tasks (
  id           uuid primary key default gen_random_uuid(),
  board_id     uuid not null references public.boards(id) on delete cascade,
  title        text not null,
  description  text,
  status       text not null default 'pending'
                check (status in ('pending', 'in_progress', 'completed')),
  priority     text not null default 'medium'
                check (priority in ('low', 'medium', 'high')),
  created_by   uuid not null references auth.users(id),
  completed_at timestamptz,
  created_at   timestamptz default now()
);

-- ─────────────────────────────────────────────────────────────
-- TT-14: Activity log (historial de actividad del tablero)
-- ─────────────────────────────────────────────────────────────

create table public.activity_log (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references public.boards(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete cascade,
  event_type text not null check (event_type in (
    'task_created',
    'task_completed',
    'task_assigned'
  )),
  actor_user_id uuid not null references auth.users(id) on delete cascade,
  target_user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

alter table public.activity_log enable row level security;

-- Lectura actividad: owner o miembro del tablero
create policy "Actividad - ver tableros (owner o miembro)"
  on public.activity_log for select
  using (
    exists (
      select 1
      from public.boards b
      where b.id = activity_log.board_id
        and (
          b.created_by = auth.uid()
          or exists (
            select 1
            from public.board_members bm
            where bm.board_id = b.id
              and bm.user_id = auth.uid()
          )
        )
    )
  );


-- RLS tasks
alter table public.tasks enable row level security;

create policy "Ver tareas (owner o miembro)"
  on public.tasks for select
  using (
    exists (
      select 1
      from public.boards b
      where b.id = tasks.board_id
        and (
          b.created_by = auth.uid()
          or exists (
            select 1
            from public.board_members bm
            where bm.board_id = b.id
              and bm.user_id = auth.uid()
          )
        )
    )
  );


-- No creamos políticas de INSERT/UPDATE para el cliente.
-- Los inserts en activity_log serán vía triggers (security definer).


create policy "Crear tareas en mis tableros"
  on public.tasks for insert
  with check (
    board_id in (
      select id from public.boards where created_by = auth.uid()
    )
  );

create policy "Actualizar tareas"
  on public.tasks for update
  using (
    board_id in (
      select id from public.boards where created_by = auth.uid()
    )
  );

create policy "Eliminar tareas"
  on public.tasks for delete
  using (
    board_id in (
      select id from public.boards where created_by = auth.uid()
    )
  );

-- ─────────────────────────────────────────────────────────────
-- TT-14-2: Triggers para registrar actividad
-- ─────────────────────────────────────────────────────────────

-- task_created
create or replace function public.activity_log_task_created()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into public.activity_log (
    board_id,
    task_id,
    event_type,
    actor_user_id,
    target_user_id
  ) values (
    new.board_id,
    new.id,
    'task_created',
    new.created_by,
    null
  );

  return new;
end;
$$;

drop trigger if exists trg_activity_task_created on public.tasks;
create trigger trg_activity_task_created
after insert on public.tasks
for each row
execute function public.activity_log_task_created();

-- task_completed (cuando status cambia a completed)
create or replace function public.activity_log_task_completed()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.status = 'completed' and old.status is distinct from new.status then
    insert into public.activity_log (
      board_id,
      task_id,
      event_type,
      actor_user_id,
      target_user_id
    ) values (
      new.board_id,
      new.id,
      'task_completed',
      new.created_by,
      null
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_activity_task_completed on public.tasks;
create trigger trg_activity_task_completed
after update of status
on public.tasks
for each row
execute function public.activity_log_task_completed();

-- ─────────────────────────────────────────────────────────────
-- Assignación
-- ─────────────────────────────────────────────────────────────

-- board_members (miembros con acceso al tablero)
create table public.board_members (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references public.boards(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text,
  joined_at timestamptz default now(),
  unique (board_id, user_id)
);

alter table public.board_members enable row level security;

-- Miembros pueden leer el tablero a través de board_members
create policy "Board members - leer" on public.board_members
  for select
  using (
    board_id in (
      select b.id from public.boards b where b.created_by = auth.uid()
    )
    or exists (
      select 1 from public.board_members bm
      where bm.board_id = board_members.board_id
        and bm.user_id = auth.uid()
    )
  );

-- Insert solo cuando el miembro se une por invite (app usa insert desde cliente)
create policy "Board members - crear" on public.board_members
  for insert
  with check (
    board_id in (
      select b.id from public.boards b where b.created_by = auth.uid()
    )
    or true
  );

-- tasks.assigned_user_id (solo 1 asignado)
alter table public.tasks
  add column if not exists assigned_user_id uuid references auth.users(id);

-- Miembros del tablero pueden leer assigned_user_id
create policy "Tareas - leer (owner o miembro)" on public.tasks
  for select
  using (
    exists (
      select 1
      from public.boards b
      where b.id = tasks.board_id
        and (
          b.created_by = auth.uid()
          or exists (
            select 1 from public.board_members bm
            where bm.board_id = b.id
              and bm.user_id = auth.uid()
          )
        )
    )
  );

-- Miembros del tablero pueden actualizar tareas (incl. assigned_user_id)
create policy "Tareas - actualizar (owner o miembro)" on public.tasks
  for update
  using (
    exists (
      select 1
      from public.boards b
      where b.id = tasks.board_id
        and (
          b.created_by = auth.uid()
          or exists (
            select 1 from public.board_members bm
            where bm.board_id = b.id
              and bm.user_id = auth.uid()
          )
        )
    )
  )
  with check (
    exists (
      select 1
      from public.boards b
      where b.id = tasks.board_id
        and (
          b.created_by = auth.uid()
          or exists (
            select 1 from public.board_members bm
            where bm.board_id = b.id
              and bm.user_id = auth.uid()
          )
        )
    )
  );


-- Trigger task_assigned: cuando assigned_user_id cambia
create or replace function public.activity_log_task_assigned()
returns trigger
language plpgsql
security definer
as $$
begin
  if new.assigned_user_id is distinct from old.assigned_user_id then
    insert into public.activity_log (
      board_id,
      task_id,
      event_type,
      actor_user_id,
      target_user_id
    ) values (
      new.board_id,
      new.id,
      'task_assigned',
      auth.uid(),
      new.assigned_user_id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_activity_task_assigned on public.tasks;
create trigger trg_activity_task_assigned
after update of assigned_user_id
on public.tasks
for each row
execute function public.activity_log_task_assigned();


-- Habilitar Realtime
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.boards;
alter publication supabase_realtime add table public.notification_events;
alter publication supabase_realtime add table public.activity_log;


-- ─────────────────────────────────────────────────────────────
-- Retorna counts por estado y porcentaje completadas
-- ─────────────────────────────────────────────────────────────

create or replace function public.get_board_stats(board_uuid uuid)
returns table (
  total integer,
  pending integer,
  in_progress integer,
  completed integer,
  percentage double precision
)
language sql
security definer
as $$
  select
    count(*)::int as total,
    count(*) filter (where status = 'pending')::int as pending,
    count(*) filter (where status = 'in_progress')::int as in_progress,
    count(*) filter (where status = 'completed')::int as completed,
    case
      when count(*) = 0 then 0.0
      else (count(*) filter (where status = 'completed')::double precision / count(*)::double precision)
    end as percentage
  from public.tasks
  where board_id = board_uuid;
$$;

