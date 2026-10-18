-- Execute once in your own Supabase project > SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.farms (
 id uuid primary key default gen_random_uuid(), name text not null default 'ฟาร์มปลาดุกบ้านเรา',
 owner_id uuid not null references auth.users(id), join_code text not null unique default upper(encode(gen_random_bytes(12),'hex')),
 created_at timestamptz not null default now()
);
create table if not exists public.farm_members (
 farm_id uuid not null references public.farms(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null check(role in ('owner','caregiver')),
 primary key(farm_id,user_id)
);
create table if not exists public.batches (
 id uuid primary key default gen_random_uuid(), farm_id uuid not null references public.farms(id) on delete cascade,
 label text not null, start_date date not null default current_date,
 stocked integer not null check(stocked>=0), initial_g numeric not null default 10 check(initial_g>=0),
 fry_cost numeric not null default 0 check(fry_cost>=0), feed_price numeric not null default 30 check(feed_price>=0),
 feed_rate numeric not null default 3 check(feed_rate>=0 and feed_rate<=15),
 pond_length numeric not null default 3 check(pond_length>0), pond_width numeric not null default 2 check(pond_width>0), water_depth_cm numeric not null default 60 check(water_depth_cm>0),
 filter_mode text not null default 'B' check(filter_mode in ('A','B')), status text not null default 'active' check(status in ('active','closed')),
 created_at timestamptz not null default now()
);
create table if not exists public.entries (
 id uuid primary key default gen_random_uuid(), farm_id uuid not null references public.farms(id) on delete cascade,
 batch_id uuid not null references public.batches(id) on delete cascade,
 entry_date date not null default current_date,
 kind text not null check(kind in ('feed','death','sample','expense','sale','water','filter','check')),
 qty numeric not null default 0 check(qty>=0), amount numeric not null default 0 check(amount>=0),
 fish_count integer not null default 0 check(fish_count>=0),
 details jsonb not null default '{}'::jsonb,
 note text not null default '', created_by uuid not null default auth.uid(), created_at timestamptz not null default now()
);
create table if not exists public.equipment (
 id uuid primary key default gen_random_uuid(), farm_id uuid not null references public.farms(id) on delete cascade,
 label text not null, amount numeric not null check(amount>=0), bought_on date default current_date,
 created_at timestamptz not null default now()
);
create index if not exists entries_batch_date_idx on public.entries(batch_id,entry_date desc);
create index if not exists batches_farm_idx on public.batches(farm_id);
create or replace function public.is_farm_member(p_farm uuid) returns boolean language sql stable security definer set search_path = public as $$
 select exists(select 1 from public.farm_members where farm_id=p_farm and user_id=auth.uid());
$$;
create or replace function public.is_farm_owner(p_farm uuid) returns boolean language sql stable security definer set search_path = public as $$
 select exists(select 1 from public.farms where id=p_farm and owner_id=auth.uid());
$$;
create or replace function public.create_family_farm(p_name text) returns uuid language plpgsql security definer set search_path = public as $$
 declare fid uuid;
 begin
 if auth.uid() is null then raise exception 'Login required'; end if;
 insert into public.farms(name,owner_id) values (left(coalesce(nullif(trim(p_name),''),'ฟาร์มปลาดุกบ้านเรา'),100),auth.uid()) returning id into fid;
 insert into public.farm_members(farm_id,user_id,role) values(fid,auth.uid(),'owner'); return fid;
 end $$;
create or replace function public.join_family_farm(p_code text) returns uuid language plpgsql security definer set search_path = public as $$
 declare fid uuid;
 begin
 if auth.uid() is null then raise exception 'Login required'; end if;
 select id into fid from public.farms where join_code=upper(trim(p_code));
 if fid is null then raise exception 'Invalid join code'; end if;
 insert into public.farm_members(farm_id,user_id,role) values(fid,auth.uid(),'caregiver') on conflict(farm_id,user_id) do nothing;
 return fid;
 end $$;
revoke all on function public.is_farm_member(uuid),public.is_farm_owner(uuid),public.create_family_farm(text),public.join_family_farm(text) from public;
grant execute on function public.is_farm_member(uuid),public.is_farm_owner(uuid),public.create_family_farm(text),public.join_family_farm(text) to authenticated;
alter table public.farms enable row level security;
alter table public.farm_members enable row level security;
alter table public.batches enable row level security;
alter table public.entries enable row level security;
alter table public.equipment enable row level security;
create policy "farm members read farms" on public.farms for select to authenticated using (public.is_farm_member(id));
create policy "farm owner updates farm" on public.farms for update to authenticated using(public.is_farm_owner(id)) with check(public.is_farm_owner(id));
create policy "members read members" on public.farm_members for select to authenticated using(public.is_farm_member(farm_id));
create policy "owners remove caregiver" on public.farm_members for delete to authenticated using (public.is_farm_owner(farm_id) and user_id <> auth.uid());
create policy "members read batches" on public.batches for select to authenticated using(public.is_farm_member(farm_id));
create policy "owners insert batches" on public.batches for insert to authenticated with check(public.is_farm_owner(farm_id));
create policy "owners update batches" on public.batches for update to authenticated using(public.is_farm_owner(farm_id)) with check(public.is_farm_owner(farm_id));
create policy "members read entries" on public.entries for select to authenticated using(public.is_farm_member(farm_id));
create policy "members insert entries" on public.entries for insert to authenticated with check(public.is_farm_member(farm_id) and created_by=auth.uid() and exists(select 1 from public.batches b where b.id=batch_id and b.farm_id=farm_id and b.status='active'));
create policy "owners delete entries" on public.entries for delete to authenticated using(public.is_farm_owner(farm_id));
create policy "members read equipment" on public.equipment for select to authenticated using(public.is_farm_member(farm_id));
create policy "owners insert equipment" on public.equipment for insert to authenticated with check(public.is_farm_owner(farm_id));
create policy "owners delete equipment" on public.equipment for delete to authenticated using(public.is_farm_owner(farm_id));
-- Ensure FK consistency even for API callers, not only UI clients.
create or replace function public.guard_entry_batch() returns trigger language plpgsql set search_path = public as $$
 begin
 if not exists(select 1 from public.batches where id=NEW.batch_id and farm_id=NEW.farm_id) then raise exception 'Batch/farm mismatch'; end if;
 return NEW;
 end $$;
drop trigger if exists guard_entry_batch_trigger on public.entries;
create trigger guard_entry_batch_trigger before insert or update on public.entries for each row execute function public.guard_entry_batch();
