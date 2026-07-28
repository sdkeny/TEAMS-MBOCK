-- =====================================================================
--  TEAMS MBOCK — ajout de la table « sorties » (page Évangélisation)
--  À coller dans Supabase ▸ SQL Editor ▸ New query, puis « Run ».
--  Peut être exécuté après le schéma principal ; réexécutable sans risque.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. Table des sorties d'évangélisation
-- ---------------------------------------------------------------------
create table if not exists public.sorties (
  id             uuid primary key default gen_random_uuid(),
  date_sortie    date not null default current_date,
  ville          text not null,
  lieu           text not null default '',        -- quartier, place, université…
  equipe         integer not null default 0,      -- nombre d'évangélistes présents
  contacts       integer not null default 0,      -- personnes rencontrées
  decisions      integer not null default 0,      -- personnes ayant pris une décision
  note           text not null default '',
  ajoute_par     text not null,
  ajoute_par_id  uuid references auth.users on delete set null,
  cree_le        timestamptz not null default now()
);

create index if not exists idx_sorties_ville on public.sorties (ville);
create index if not exists idx_sorties_date  on public.sorties (date_sortie);

-- ---------------------------------------------------------------------
--  2. Privilèges d'accès par l'API
-- ---------------------------------------------------------------------
grant select, insert, update, delete on public.sorties to authenticated;

-- ---------------------------------------------------------------------
--  3. Row Level Security
--     Même logique que les membres : chacun lit et ajoute,
--     la modification est libre, la suppression réservée aux admins.
-- ---------------------------------------------------------------------
alter table public.sorties enable row level security;

drop policy if exists sorties_lecture on public.sorties;
create policy sorties_lecture on public.sorties
  for select to authenticated using (true);

drop policy if exists sorties_ajout on public.sorties;
create policy sorties_ajout on public.sorties
  for insert to authenticated with check (auth.uid() = ajoute_par_id);

drop policy if exists sorties_maj on public.sorties;
create policy sorties_maj on public.sorties
  for update to authenticated using (true) with check (true);

drop policy if exists sorties_suppr on public.sorties;
create policy sorties_suppr on public.sorties
  for delete to authenticated using (auth.uid() = ajoute_par_id or public.est_admin());

-- ---------------------------------------------------------------------
--  4. Temps réel
--     Ajouter une table déjà publiée lève une erreur qui annulerait tout
--     le script (l'éditeur SQL travaille en transaction) : on l'ignore.
-- ---------------------------------------------------------------------
do $$
begin
  begin
    execute 'alter publication supabase_realtime add table public.sorties';
    raise notice 'Temps réel activé sur sorties';
  exception
    when duplicate_object then
      raise notice 'Temps réel déjà actif sur sorties (rien à faire)';
    when undefined_object then
      raise notice 'Publication supabase_realtime absente : à activer via Database ▸ Replication';
  end;
end;
$$;
