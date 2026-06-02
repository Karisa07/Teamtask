create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  email      text not null,
  full_name  text,
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Perfil propio"
  on public.profiles for all
  using (auth.uid() = id);


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

-- ─────────────────────────────────────────────────────────────
-- TT-12-2: RPC de estadísticas por tablero (agregación)
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
