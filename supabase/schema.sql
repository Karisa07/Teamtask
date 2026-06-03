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

-- RLS tasks
alter table public.tasks enable row level security;

create policy "Ver tareas de mis tableros"
  on public.tasks for select
  using (
    board_id in (
      select id from public.boards where created_by = auth.uid()
    )
  );

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

-- Habilitar Realtime
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.boards;
alter publication supabase_realtime add table public.notification_events;

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

