-- ============================================================
-- ANAAM'S BAKE STUDIO - Supabase setup
-- Run this ONCE in: Supabase Dashboard -> SQL Editor -> New query
-- Paste everything, press RUN. Green "Success" means done.
-- ============================================================

-- ---------- TABLES ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  emoji text not null default '🧑‍🍳',
  role text not null default 'Taster',
  photo_path text,
  created_at timestamptz default now()
);

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null references public.profiles(id) on delete cascade,
  data jsonb not null,
  created_at timestamptz default now()
);

create table public.bakes (
  id uuid primary key default gen_random_uuid(),
  baker uuid not null references public.profiles(id) on delete cascade,
  data jsonb not null,
  photo_path text,
  created_at timestamptz default now()
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  bake_id uuid not null references public.bakes(id) on delete cascade,
  reviewer uuid not null references public.profiles(id) on delete cascade,
  stars int not null check (stars between 1 and 5),
  comment text not null,
  photo_path text,
  created_at timestamptz default now(),
  unique (bake_id, reviewer)
);

-- ---------- ROW LEVEL SECURITY ----------
alter table public.profiles enable row level security;
alter table public.recipes  enable row level security;
alter table public.bakes    enable row level security;
alter table public.reviews  enable row level security;

-- Profiles: every logged-in family member can see all, but only edit their own
create policy "family reads profiles"  on public.profiles for select to authenticated using (true);
create policy "create own profile"     on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "edit own profile"       on public.profiles for update to authenticated using (id = auth.uid());

-- Recipes: everyone reads, you manage your own
create policy "family reads recipes"   on public.recipes for select to authenticated using (true);
create policy "add own recipe"         on public.recipes for insert to authenticated with check (owner = auth.uid());
create policy "edit own recipe"        on public.recipes for update to authenticated using (owner = auth.uid());
create policy "delete own recipe"      on public.recipes for delete to authenticated using (owner = auth.uid());

-- Bakes: everyone reads, you manage your own
create policy "family reads bakes"     on public.bakes for select to authenticated using (true);
create policy "log own bake"           on public.bakes for insert to authenticated with check (baker = auth.uid());
create policy "edit own bake"          on public.bakes for update to authenticated using (baker = auth.uid());
create policy "delete own bake"        on public.bakes for delete to authenticated using (baker = auth.uid());

-- Reviews: everyone reads; you may NOT review your own bake (house rule, enforced!)
create policy "family reads reviews"   on public.reviews for select to authenticated using (true);
create policy "review others bakes"    on public.reviews for insert to authenticated
  with check (
    reviewer = auth.uid()
    and not exists (select 1 from public.bakes b where b.id = bake_id and b.baker = auth.uid())
  );
create policy "edit own review"        on public.reviews for update to authenticated using (reviewer = auth.uid());
create policy "delete own review"      on public.reviews for delete to authenticated using (reviewer = auth.uid());

-- ---------- PHOTO STORAGE (private bucket) ----------
insert into storage.buckets (id, name, public) values ('photos', 'photos', false);

create policy "family sees photos" on storage.objects for select to authenticated
  using (bucket_id = 'photos');
create policy "upload to own folder" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "replace own photos" on storage.objects for update to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "delete own photos" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- Done! Now: Authentication -> Sign In / Providers -> turn OFF "Allow new users to sign up"
-- Then:  Authentication -> Users -> Add user (one per family member, tick Auto Confirm)
