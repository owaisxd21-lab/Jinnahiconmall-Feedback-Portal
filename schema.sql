-- JINNAH ICON MALL FEEDBACK PORTAL — Premium Edition
-- Run this entire script in Supabase SQL Editor.
-- Safe to re-run even if you already ran an earlier version.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  role text not null default 'pending' check (role in ('pending','user','admin','owner')),
  created_at timestamptz not null default now()
);

-- Upgrading from an older version of this schema: widen the role values
-- and add the email column if they are not already there. This part is
-- safe to re-run and never changes anyone's existing role.
alter table public.profiles add column if not exists email text;
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('pending','user','admin','owner'));
-- ONE-TIME MANUAL STEP after upgrading from the old admin-only version:
-- your existing 'admin' account(s) had full access, so promote them to
-- 'owner' yourself (run once, not part of this script):
--   update public.profiles set role='owner' where role='admin';

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  feedback_id text not null unique,
  created_at timestamptz not null default now(),
  type text not null,
  area text,
  rating int not null check (rating between 1 and 5),
  name text,
  phone text,
  email text,
  message text not null,
  photo_path text,
  status text not null default 'New' check (status in ('New','In Review','Resolved')),
  admin_remark text
);

-- Automatically create a pending profile for new Auth users.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), new.email)
  on conflict (id) do update set email=excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- SECURITY DEFINER helpers prevent recursive RLS policies on profiles.
-- Three access tiers:
--   owner  - full access: edit status/remarks, delete feedback, manage team roles
--   admin  - can view feedback and, after reviewing it, add/edit the admin
--            remark; cannot delete feedback or change anyone's role
--   user   - read-only: can view the dashboard and feedback, no changes at all
create or replace function public.is_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'owner'
  );
$$;

-- Owner or admin: allowed to update a feedback row (owner: any field;
-- the admin dashboard only ever sends the admin_remark field for admins).
create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('owner','admin')
  );
$$;

-- Owner, admin, or user: allowed to view the dashboard and feedback.
create or replace function public.can_view_feedback()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('owner','admin','user')
  );
$$;

alter table public.profiles enable row level security;
alter table public.feedback enable row level security;

-- Rebuild policies cleanly. The old version used profiles inside a profiles
-- policy, which can cause RLS recursion and make an admin appear pending.
drop policy if exists "users read own profile" on public.profiles;
drop policy if exists "admins read profiles" on public.profiles;
drop policy if exists "owners read profiles" on public.profiles;
drop policy if exists "owners update profiles" on public.profiles;
create policy "users read own profile" on public.profiles
for select to authenticated
using (id = auth.uid());

-- Owner can see everyone's profile (needed for the Team & Access panel).
create policy "owners read profiles" on public.profiles
for select to authenticated
using (public.is_owner());

-- Owner can change anyone's role (approve pending accounts, promote/demote
-- between user/admin/owner). Admins and users cannot change roles.
create policy "owners update profiles" on public.profiles
for update to authenticated
using (public.is_owner())
with check (public.is_owner());

drop policy if exists "public can submit feedback" on public.feedback;
create policy "public can submit feedback" on public.feedback
for insert to anon, authenticated
with check (true);

drop policy if exists "admins read feedback" on public.feedback;
drop policy if exists "viewers read feedback" on public.feedback;
create policy "viewers read feedback" on public.feedback
for select to authenticated
using (public.can_view_feedback());

drop policy if exists "admins update feedback" on public.feedback;
drop policy if exists "staff update feedback" on public.feedback;
create policy "staff update feedback" on public.feedback
for update to authenticated
using (public.is_staff())
with check (public.is_staff());

drop policy if exists "admins delete feedback" on public.feedback;
drop policy if exists "owners delete feedback" on public.feedback;
create policy "owners delete feedback" on public.feedback
for delete to authenticated
using (public.is_owner());

-- Storage bucket for optional feedback photos.
insert into storage.buckets (id,name,public)
values ('feedback-photos','feedback-photos',false)
on conflict (id) do nothing;

drop policy if exists "public upload feedback photos" on storage.objects;
create policy "public upload feedback photos" on storage.objects
for insert to anon, authenticated
with check (bucket_id='feedback-photos');

drop policy if exists "admins read feedback photos" on storage.objects;
drop policy if exists "viewers read feedback photos" on storage.objects;
create policy "viewers read feedback photos" on storage.objects
for select to authenticated
using (bucket_id='feedback-photos' and public.can_view_feedback());

drop policy if exists "admins delete feedback photos" on storage.objects;
drop policy if exists "owners delete feedback photos" on storage.objects;
create policy "owners delete feedback photos" on storage.objects
for delete to authenticated
using (bucket_id='feedback-photos' and public.is_owner());

-- After your first Auth account exists, make it the owner with:
-- update public.profiles
-- set role='owner'
-- where id=(select id from auth.users where email='YOUR_OWNER_EMAIL');
