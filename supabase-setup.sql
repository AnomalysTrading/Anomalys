-- ANOMALYS TRADING — esquema seguro para GitHub Pages + Supabase.
-- Ejecutá todo en Supabase > SQL Editor > New query.
-- El catálogo y el historial son de lectura pública. Solo admins escriben.
-- Solo un OWNER puede administrar la lista de administradores.

create extension if not exists pgcrypto;

create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admins add column if not exists role text not null default 'admin';
alter table public.admins drop constraint if exists admins_role_check;
alter table public.admins add constraint admins_role_check check (role in ('owner','admin'));

create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  category text not null default 'Otro' check (category in ('Cuchillo','Asesino','Cabaña','Otro')),
  value numeric(12,2) not null default 0 check (value >= 0),
  rarity text not null default '',
  image_url text,
  description text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.item_history (
  id bigint generated always as identity primary key,
  item_id uuid,
  item_name text not null,
  action text not null check (action in ('INSERT','UPDATE','DELETE')),
  old_value numeric(12,2),
  new_value numeric(12,2),
  changed_at timestamptz not null default now()
);

create or replace function public.is_anomalys_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

create or replace function public.is_anomalys_owner()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid() and role = 'owner');
$$;

create or replace function public.touch_item_updated_at()
returns trigger language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists items_touch_updated_at on public.items;
create trigger items_touch_updated_at before update on public.items
for each row execute function public.touch_item_updated_at();

create or replace function public.record_item_history()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    insert into public.item_history(item_id,item_name,action,old_value,new_value)
    values (new.id,new.name,'INSERT',null,new.value);
    return new;
  elsif TG_OP = 'UPDATE' then
    if old.name is distinct from new.name or old.value is distinct from new.value or old.category is distinct from new.category then
      insert into public.item_history(item_id,item_name,action,old_value,new_value)
      values (new.id,new.name,'UPDATE',old.value,new.value);
    end if;
    return new;
  else
    insert into public.item_history(item_id,item_name,action,old_value,new_value)
    values (old.id,old.name,'DELETE',old.value,null);
    return old;
  end if;
end;
$$;

drop trigger if exists items_record_history on public.items;
create trigger items_record_history after insert or update or delete on public.items
for each row execute function public.record_item_history();

alter table public.admins enable row level security;
alter table public.items enable row level security;
alter table public.item_history enable row level security;

drop policy if exists "Public can read items" on public.items;
create policy "Public can read items" on public.items for select using (true);
drop policy if exists "Admins can insert items" on public.items;
create policy "Admins can insert items" on public.items for insert with check (public.is_anomalys_admin());
drop policy if exists "Admins can update items" on public.items;
create policy "Admins can update items" on public.items for update using (public.is_anomalys_admin()) with check (public.is_anomalys_admin());
drop policy if exists "Admins can delete items" on public.items;
create policy "Admins can delete items" on public.items for delete using (public.is_anomalys_admin());

drop policy if exists "Public can read history" on public.item_history;
create policy "Public can read history" on public.item_history for select using (true);

-- La cuenta puede consultar su propia fila; el propietario puede consultar todas.
drop policy if exists "Users read own admin row or owner reads all" on public.admins;
create policy "Users read own admin row or owner reads all"
on public.admins for select to authenticated
using (user_id = auth.uid() or public.is_anomalys_owner());

-- Solo OWNER puede agregar admins normales o quitar admins normales.
-- La interfaz no permite crear/quitar owners.
drop policy if exists "Owner adds admins" on public.admins;
create policy "Owner adds admins" on public.admins for insert to authenticated
with check (public.is_anomalys_owner() and role = 'admin');
drop policy if exists "Owner removes admins" on public.admins;
create policy "Owner removes admins" on public.admins for delete to authenticated
using (public.is_anomalys_owner() and role = 'admin');
drop policy if exists "No admin updates" on public.admins;
create policy "No admin updates" on public.admins for update to authenticated
using (false) with check (false);

grant usage on schema public to anon, authenticated;
grant select on public.items to anon, authenticated;
grant insert, update, delete on public.items to authenticated;
grant select on public.item_history to anon, authenticated;
grant select, insert, delete on public.admins to authenticated;
grant execute on function public.is_anomalys_admin() to anon, authenticated;
grant execute on function public.is_anomalys_owner() to anon, authenticated;

-- PASO DE CONFIGURACIÓN DEL CREADOR:
-- 1. Creá tu cuenta en Authentication > Users.
-- 2. Copiá su UUID y ejecutá la consulta de abajo, reemplazando el texto:
-- insert into public.admins (user_id, role)
-- values ('UUID-DE-TU-USUARIO', 'owner')
-- on conflict (user_id) do update set role = 'owner';
--
-- Si ya corriste una versión anterior del SQL y ya estás en admins,
-- la misma consulta te convierte en owner. No la ejecutes con UUID ajeno.

-- Apariencia global de Anomalys: fondo y logo del juego personalizables.
-- Este bloque también se puede ejecutar por separado si ya instalaste el SQL anterior.
create table if not exists public.site_appearance (
  id smallint primary key default 1 check (id = 1),
  background_url text,
  background_color text not null default '#0b0a0b' check (background_color ~ '^#[0-9A-Fa-f]{6}$'),
  game_image_url text,
  game_name text not null default 'Anomalys',
  updated_at timestamptz not null default now()
);
alter table public.site_appearance enable row level security;
drop policy if exists "Public can read site appearance" on public.site_appearance;
create policy "Public can read site appearance" on public.site_appearance for select using (true);
drop policy if exists "Admins can create site appearance" on public.site_appearance;
create policy "Admins can create site appearance" on public.site_appearance for insert to authenticated with check (public.is_anomalys_admin());
drop policy if exists "Admins can update site appearance" on public.site_appearance;
create policy "Admins can update site appearance" on public.site_appearance for update to authenticated using (public.is_anomalys_admin()) with check (public.is_anomalys_admin());
grant select on public.site_appearance to anon, authenticated;
grant insert, update on public.site_appearance to authenticated;
