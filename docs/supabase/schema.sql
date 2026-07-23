-- Niam Supabase Schema
-- Apply in: Supabase Dashboard → SQL Editor → Run

-- ============================================================
-- EXTENSIONS
-- ============================================================
create extension if not exists "uuid-ossp";

-- ============================================================
-- official_recipes
-- Read-only curated recipes seeded by the app developer.
-- All users can read; only service_role can insert/update/delete.
-- ============================================================
create table if not exists official_recipes (
    id              uuid primary key default uuid_generate_v4(),
    title           text not null,
    cuisine         text not null,
    scenes          text[] not null default '{}',
    main_ingredients    jsonb not null default '[]',
    side_ingredients    jsonb not null default '[]',
    seasonings          jsonb not null default '[]',
    steps               text[] not null default '{}',
    notes               text not null default '',
    servings            int,
    prep_time_minutes   int not null default 0,
    cook_time_minutes   int not null default 0,
    calories_per_serving int,
    created_at      timestamptz not null default now()
);

-- RLS: everyone can read, nobody can write via client
alter table official_recipes enable row level security;

create policy "Anyone can read official recipes"
    on official_recipes for select
    using (true);

-- ============================================================
-- published_recipes
-- User-published community recipes.
-- ============================================================
create table if not exists published_recipes (
    id              uuid primary key default uuid_generate_v4(),
    author_id       uuid not null,
    author_name     text not null default '',
    title           text not null,
    cuisine         text not null,
    scenes          text[] not null default '{}',
    main_ingredients    jsonb not null default '[]',
    side_ingredients    jsonb not null default '[]',
    seasonings          jsonb not null default '[]',
    steps               text[] not null default '{}',
    notes               text not null default '',
    servings            int,
    prep_time_minutes   int not null default 0,
    cook_time_minutes   int not null default 0,
    calories_per_serving int,
    likes_count     int not null default 0,
    saves_count     int not null default 0,
    is_visible      boolean not null default true,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

alter table published_recipes enable row level security;

create policy "Anyone can read visible published recipes"
    on published_recipes for select
    using (is_visible = true);

create policy "Authenticated users can publish"
    on published_recipes for insert
    to authenticated
    with check (auth.uid() = author_id);

create policy "Authors can update their own recipes"
    on published_recipes for update
    to authenticated
    using (auth.uid() = author_id);

create policy "Authors can delete their own recipes"
    on published_recipes for delete
    to authenticated
    using (auth.uid() = author_id);

-- ============================================================
-- community_profiles
-- Public display info for community users.
-- ============================================================
create table if not exists community_profiles (
    id          uuid primary key references auth.users(id) on delete cascade,
    display_name text not null default '',
    created_at  timestamptz not null default now()
);

alter table community_profiles enable row level security;

create policy "Anyone can read community profiles"
    on community_profiles for select
    using (true);

create policy "Users can upsert their own profile"
    on community_profiles for insert
    to authenticated
    with check (auth.uid() = id);

create policy "Users can update their own profile"
    on community_profiles for update
    to authenticated
    using (auth.uid() = id);

-- ============================================================
-- recipe_saves
-- Tracks which users saved which published recipes.
-- ============================================================
create table if not exists recipe_saves (
    user_id     uuid not null references auth.users(id) on delete cascade,
    recipe_id   uuid not null references published_recipes(id) on delete cascade,
    saved_at    timestamptz not null default now(),
    primary key (user_id, recipe_id)
);

alter table recipe_saves enable row level security;

create policy "Users can read their own saves"
    on recipe_saves for select
    to authenticated
    using (auth.uid() = user_id);

create policy "Users can save recipes"
    on recipe_saves for insert
    to authenticated
    with check (auth.uid() = user_id);

create policy "Users can unsave recipes"
    on recipe_saves for delete
    to authenticated
    using (auth.uid() = user_id);

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists idx_official_recipes_cuisine on official_recipes(cuisine);
create index if not exists idx_published_recipes_author on published_recipes(author_id);
create index if not exists idx_published_recipes_cuisine on published_recipes(cuisine);
create index if not exists idx_published_recipes_created on published_recipes(created_at desc);
