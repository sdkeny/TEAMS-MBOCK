-- =====================================================================
--  TEAMS MBOCK — objectifs d'heures de prière (plusieurs, nommés)
--  À coller dans Supabase ▸ SQL Editor ▸ New query, puis « Run ».
--  Entièrement réexécutable.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. Table des objectifs (chacun a un nom et un nombre d'heures visé)
-- ---------------------------------------------------------------------
create table if not exists public.objectifs (
  id          uuid primary key default gen_random_uuid(),
  nom         text not null,
  cible       numeric(8,2),                 -- heures visées (facultatif)
  cree_par    text,
  cree_par_id uuid references auth.users on delete set null,
  cree_le     timestamptz not null default now()
);

grant select, insert, update, delete on public.objectifs to authenticated;
alter table public.objectifs enable row level security;

drop policy if exists objectifs_lecture on public.objectifs;
create policy objectifs_lecture on public.objectifs
  for select to authenticated using (true);

drop policy if exists objectifs_ecriture on public.objectifs;
create policy objectifs_ecriture on public.objectifs
  for all to authenticated using (true) with check (true);

-- ---------------------------------------------------------------------
--  2. On relie chaque heure de prière à un objectif (facultatif)
--     « set null » : supprimer un objectif ne détruit pas les heures,
--     elles redeviennent « sans objectif ».
-- ---------------------------------------------------------------------
alter table public.priere_heures
  add column if not exists objectif_id uuid references public.objectifs on delete set null;

create index if not exists idx_heures_objectif on public.priere_heures (objectif_id);

-- ---------------------------------------------------------------------
--  3. Temps réel
-- ---------------------------------------------------------------------
do $$
begin
  begin
    execute 'alter publication supabase_realtime add table public.objectifs';
    raise notice 'Temps réel activé sur objectifs';
  exception
    when duplicate_object then raise notice 'Temps réel déjà actif sur objectifs';
    when undefined_object then raise notice 'Publication supabase_realtime absente : à activer via Database ▸ Replication';
  end;
end;
$$;
