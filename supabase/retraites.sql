-- =====================================================================
--  TEAMS MBOCK — ajout de la table « retraites » (page Retraites)
--  À coller dans Supabase ▸ SQL Editor ▸ New query, puis « Run ».
--  Peut être exécuté après le schéma principal ; réexécutable sans risque.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. Table des retraites d'équipe
-- ---------------------------------------------------------------------
create table if not exists public.retraites (
  id             uuid primary key default gen_random_uuid(),
  titre          text not null default '',
  lieu           text not null default '',
  date_debut     date not null default current_date,
  date_fin       date,                            -- null = retraite d'un seul jour
  participants   integer not null default 0,
  invites        integer not null default 0,      -- personnes invitées
  conversions    integer not null default 0,      -- décisions / conversions
  baptemes       integer not null default 0,      -- baptêmes
  theme          text not null default '',
  note           text not null default '',        -- programme, orateurs, infos pratiques…
  images         jsonb not null default '[]'::jsonb,  -- URLs des photos (Supabase Storage)
  ajoute_par     text not null,
  ajoute_par_id  uuid references auth.users on delete set null,
  cree_le        timestamptz not null default now()
);

-- Colonnes ajoutées après coup (si la table existait déjà sans elles).
alter table public.retraites add column if not exists invites     integer not null default 0;
alter table public.retraites add column if not exists conversions integer not null default 0;
alter table public.retraites add column if not exists baptemes    integer not null default 0;
alter table public.retraites add column if not exists images      jsonb not null default '[]'::jsonb;

create index if not exists idx_retraites_debut on public.retraites (date_debut);

-- ---------------------------------------------------------------------
--  2. Privilèges d'accès par l'API
-- ---------------------------------------------------------------------
grant select, insert, update, delete on public.retraites to authenticated;

-- ---------------------------------------------------------------------
--  3. Row Level Security
--     Chacun lit et ajoute, la modification est libre,
--     la suppression réservée à l'auteur ou aux administrateurs.
-- ---------------------------------------------------------------------
alter table public.retraites enable row level security;

drop policy if exists retraites_lecture on public.retraites;
create policy retraites_lecture on public.retraites
  for select to authenticated using (true);

drop policy if exists retraites_ajout on public.retraites;
create policy retraites_ajout on public.retraites
  for insert to authenticated with check (auth.uid() = ajoute_par_id);

drop policy if exists retraites_maj on public.retraites;
create policy retraites_maj on public.retraites
  for update to authenticated using (true) with check (true);

drop policy if exists retraites_suppr on public.retraites;
create policy retraites_suppr on public.retraites
  for delete to authenticated using (auth.uid() = ajoute_par_id or public.est_admin());

-- ---------------------------------------------------------------------
--  4. Temps réel
--     Ajouter une table déjà publiée lève une erreur qui annulerait tout
--     le script (l'éditeur SQL travaille en transaction) : on l'ignore.
-- ---------------------------------------------------------------------
do $$
begin
  begin
    execute 'alter publication supabase_realtime add table public.retraites';
    raise notice 'Temps réel activé sur retraites';
  exception
    when duplicate_object then
      raise notice 'Temps réel déjà actif sur retraites (rien à faire)';
    when undefined_object then
      raise notice 'Publication supabase_realtime absente : à activer via Database ▸ Replication';
  end;
end;
$$;
