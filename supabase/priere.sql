-- =====================================================================
--  TEAMS MBOCK — évolutions de la page « Prier »
--  À coller dans Supabase ▸ SQL Editor ▸ New query, puis « Run ».
--  Entièrement réexécutable (même si une version antérieure a déjà tourné).
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. Sujets de prière « d'équipe » (non liés à une personne)
-- ---------------------------------------------------------------------
alter table public.prieres alter column membre_id drop not null;

-- ---------------------------------------------------------------------
--  2. Heures de prière (avec créneau début / fin)
-- ---------------------------------------------------------------------
create table if not exists public.priere_heures (
  id             uuid primary key default gen_random_uuid(),
  heures         numeric(6,2) not null check (heures > 0),
  heure_debut    time,
  heure_fin      time,
  date_priere    date not null default current_date,
  note           text not null default '',
  auteur         text not null,
  auteur_id      uuid references auth.users on delete set null,
  cree_le        timestamptz not null default now()
);

-- Colonnes ajoutées après coup (si la table existait déjà sans le créneau).
alter table public.priere_heures add column if not exists heure_debut time;
alter table public.priere_heures add column if not exists heure_fin   time;

create index if not exists idx_heures_date on public.priere_heures (date_priere);

grant select, insert, update, delete on public.priere_heures to authenticated;

alter table public.priere_heures enable row level security;

drop policy if exists heures_lecture on public.priere_heures;
create policy heures_lecture on public.priere_heures
  for select to authenticated using (true);

drop policy if exists heures_ajout on public.priere_heures;
create policy heures_ajout on public.priere_heures
  for insert to authenticated with check (auth.uid() = auteur_id);

drop policy if exists heures_maj on public.priere_heures;
create policy heures_maj on public.priere_heures
  for update to authenticated using (true) with check (true);

drop policy if exists heures_suppr on public.priere_heures;
create policy heures_suppr on public.priere_heures
  for delete to authenticated using (auth.uid() = auteur_id or public.est_admin());

-- ---------------------------------------------------------------------
--  3. Paramètres d'équipe (clé/valeur)
--     Sert à stocker l'objectif d'heures de prière. Lecture pour tous,
--     écriture réservée aux administrateurs.
-- ---------------------------------------------------------------------
create table if not exists public.parametres (
  id      uuid primary key default gen_random_uuid(),
  cle     text unique not null,
  valeur  text not null default '',
  maj_par text,
  maj_le  timestamptz not null default now()
);

grant select, insert, update, delete on public.parametres to authenticated;

alter table public.parametres enable row level security;

drop policy if exists param_lecture on public.parametres;
create policy param_lecture on public.parametres
  for select to authenticated using (true);

drop policy if exists param_ajout on public.parametres;
create policy param_ajout on public.parametres
  for insert to authenticated with check (public.est_admin());

drop policy if exists param_maj on public.parametres;
create policy param_maj on public.parametres
  for update to authenticated using (public.est_admin()) with check (public.est_admin());

-- ---------------------------------------------------------------------
--  4. Temps réel
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['priere_heures', 'parametres'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
      raise notice 'Temps réel activé sur %', t;
    exception
      when duplicate_object then raise notice 'Temps réel déjà actif sur % (rien à faire)', t;
      when undefined_object then raise notice 'Publication supabase_realtime absente : à activer via Database ▸ Replication';
    end;
  end loop;
end;
$$;
