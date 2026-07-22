-- =====================================================================
--  TEAMS MBOCK — schéma de la base partagée
--  À coller dans Supabase ▸ SQL Editor ▸ New query, puis « Run ».
--  Exécutable une seule fois, sur un projet neuf.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. Tables
-- ---------------------------------------------------------------------

-- Un profil par personne connectée. Le rôle décide de qui peut exporter.
create table if not exists public.profils (
  id       uuid primary key references auth.users on delete cascade,
  nom      text not null,
  role     text not null default 'membre' check (role in ('membre', 'admin', 'super')),
  cree_le  timestamptz not null default now()
);

-- Villes de l'équipe : coordonnées réelles et effectif recensé (objectif).
create table if not exists public.villes (
  nom       text primary key,
  lat       double precision,
  lon       double precision,
  effectif  integer not null default 0
);

create table if not exists public.membres (
  id              uuid primary key default gen_random_uuid(),
  prenom          text not null,
  nom             text not null,
  ville           text not null,
  statut          text not null default 'Nouveau'
                  check (statut in ('Nouveau', 'En intégration', 'Membre', 'À relancer')),
  tel             text not null default '',
  email           text not null default '',
  date_rencontre  date not null default current_date,
  note            text not null default '',
  ajoute_par      text not null,
  ajoute_par_id   uuid references auth.users on delete set null,
  cree_le         timestamptz not null default now()
);

create table if not exists public.commentaires (
  id         uuid primary key default gen_random_uuid(),
  membre_id  uuid not null references public.membres on delete cascade,
  texte      text not null,
  auteur     text not null,
  auteur_id  uuid references auth.users on delete set null,
  cree_le    timestamptz not null default now()
);

create table if not exists public.prieres (
  id         uuid primary key default gen_random_uuid(),
  membre_id  uuid not null references public.membres on delete cascade,
  texte      text not null,
  auteur     text not null,
  auteur_id  uuid references auth.users on delete set null,
  confie_le  date not null default current_date,
  exauce     boolean not null default false,
  exauce_le  date
);

create index if not exists idx_membres_ville      on public.membres (ville);
create index if not exists idx_commentaires_membre on public.commentaires (membre_id);
create index if not exists idx_prieres_membre      on public.prieres (membre_id);

-- ---------------------------------------------------------------------
--  2. Création automatique du profil à l'inscription
-- ---------------------------------------------------------------------
create or replace function public.creer_profil()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profils (id, nom)
  values (new.id, coalesce(nullif(trim(new.raw_user_meta_data->>'nom'), ''), new.email));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.creer_profil();

-- ---------------------------------------------------------------------
--  3. Qui est administrateur ?
--     security definer : la fonction lit profils sans repasser par RLS,
--     ce qui éviterait une récursion infinie dans les politiques.
-- ---------------------------------------------------------------------
create or replace function public.est_admin()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.profils
    where id = auth.uid() and role in ('admin', 'super')
  );
$$;

create or replace function public.est_super()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.profils
    where id = auth.uid() and role = 'super'
  );
$$;

-- ---------------------------------------------------------------------
--  3 bis. Privilèges d'accès par l'API
--     Posés explicitement pour que le schéma fonctionne même si l'option
--     « Exposer automatiquement de nouvelles tables » est décochée.
--     Ces droits sont volontairement larges : c'est le RLS de la section
--     suivante qui filtre réellement, ligne par ligne.
--     « anon » (visiteur non connecté) ne reçoit rien : sans compte, aucune
--     donnée n'est accessible.
-- ---------------------------------------------------------------------
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.profils      to authenticated;
grant select, insert, update, delete on public.villes       to authenticated;
grant select, insert, update, delete on public.membres      to authenticated;
grant select, insert, update, delete on public.commentaires to authenticated;
grant select, insert, update, delete on public.prieres      to authenticated;
grant execute on function public.est_admin() to authenticated;
grant execute on function public.est_super() to authenticated;

-- ---------------------------------------------------------------------
--  4. Row Level Security
--     Rien n'est lisible sans être connecté. Tout passe par ces règles,
--     y compris depuis la clé publique visible dans le code du site.
-- ---------------------------------------------------------------------
alter table public.profils      enable row level security;
alter table public.villes       enable row level security;
alter table public.membres      enable row level security;
alter table public.commentaires enable row level security;
alter table public.prieres      enable row level security;

-- Profils : chacun voit l'équipe, ne modifie que son propre nom.
drop policy if exists profils_lecture on public.profils;
create policy profils_lecture on public.profils
  for select to authenticated using (true);

drop policy if exists profils_maj_soi on public.profils;
create policy profils_maj_soi on public.profils
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from public.profils where id = auth.uid()));

-- Seul l'administrateur principal distribue les rôles.
drop policy if exists profils_roles_super on public.profils;
create policy profils_roles_super on public.profils
  for update to authenticated
  using (public.est_super())
  with check (public.est_super());

-- Villes : tout le monde lit, les administrateurs ajustent.
drop policy if exists villes_lecture on public.villes;
create policy villes_lecture on public.villes
  for select to authenticated using (true);

drop policy if exists villes_ecriture on public.villes;
create policy villes_ecriture on public.villes
  for all to authenticated using (public.est_admin()) with check (public.est_admin());

-- Membres : chacun lit tout, chacun peut ajouter et corriger.
-- La suppression reste aux administrateurs.
drop policy if exists membres_lecture on public.membres;
create policy membres_lecture on public.membres
  for select to authenticated using (true);

drop policy if exists membres_ajout on public.membres;
create policy membres_ajout on public.membres
  for insert to authenticated with check (auth.uid() = ajoute_par_id);

drop policy if exists membres_maj on public.membres;
create policy membres_maj on public.membres
  for update to authenticated using (true) with check (true);

drop policy if exists membres_suppr on public.membres;
create policy membres_suppr on public.membres
  for delete to authenticated using (public.est_admin());

-- Commentaires : chacun lit et écrit ; on ne modifie/efface que les siens
-- (un administrateur peut retirer un commentaire déplacé).
drop policy if exists commentaires_lecture on public.commentaires;
create policy commentaires_lecture on public.commentaires
  for select to authenticated using (true);

drop policy if exists commentaires_ajout on public.commentaires;
create policy commentaires_ajout on public.commentaires
  for insert to authenticated with check (auth.uid() = auteur_id);

drop policy if exists commentaires_suppr on public.commentaires;
create policy commentaires_suppr on public.commentaires
  for delete to authenticated using (auth.uid() = auteur_id or public.est_admin());

-- Sujets de prière : chacun lit, ajoute, et peut marquer « exaucé ».
drop policy if exists prieres_lecture on public.prieres;
create policy prieres_lecture on public.prieres
  for select to authenticated using (true);

drop policy if exists prieres_ajout on public.prieres;
create policy prieres_ajout on public.prieres
  for insert to authenticated with check (auth.uid() = auteur_id);

drop policy if exists prieres_maj on public.prieres;
create policy prieres_maj on public.prieres
  for update to authenticated using (true) with check (true);

drop policy if exists prieres_suppr on public.prieres;
create policy prieres_suppr on public.prieres
  for delete to authenticated using (auth.uid() = auteur_id or public.est_admin());

-- ---------------------------------------------------------------------
--  5. Temps réel : ce qui est diffusé à tous les navigateurs ouverts
-- ---------------------------------------------------------------------
-- Selon les projets, la publication « supabase_realtime » couvre déjà toutes
-- les tables. Y rajouter une table déjà membre lève une erreur qui, l'éditeur
-- SQL travaillant en transaction, annulerait TOUT le script. On ignore donc
-- ce cas, ainsi que l'absence éventuelle de la publication.
do $$
declare
  t text;
begin
  foreach t in array array['membres', 'commentaires', 'prieres', 'profils'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
      raise notice 'Temps réel activé sur %', t;
    exception
      when duplicate_object then
        raise notice 'Temps réel déjà actif sur % (rien à faire)', t;
      when undefined_object then
        raise notice 'Publication supabase_realtime absente : à activer via Database ▸ Replication';
    end;
  end loop;
end;
$$;

-- ---------------------------------------------------------------------
--  6. Les 22 villes de l'équipe (source : fichier Excel de l'équipe)
-- ---------------------------------------------------------------------
insert into public.villes (nom, lat, lon, effectif) values
  ('Grenoble',        45.1842335,  5.7155400, 40),
  ('Lyon',            45.7579507,  4.8351239, 21),
  ('Marseille',       43.2803390,  5.3806376, 15),
  ('IDF',             48.6807825,  2.5026637, 12),
  ('Bordeaux',        44.8637178, -0.5860121,  9),
  ('Aix en Provence', 43.5360054,  5.3879121,  9),
  ('Nancy',           48.6880574,  6.1734322,  8),
  ('Annemasse',       46.1890335,  6.2476091,  7),
  ('Valence',         44.9234167,  4.9163851,  6),
  ('Dijon',           47.3318698,  5.0322191,  6),
  ('Lille',           50.6310806,  3.0468401,  4),
  ('Nice',            43.7031953,  7.2528120,  3),
  ('Strasbourg',      48.5690969,  7.7620787,  2),
  ('Compiegne',       49.4006159,  2.8546645,  2),
  ('Rennes',          48.1159343, -1.6884477,  1),
  ('Poitiers',        46.5846304,  0.3714621,  1),
  ('Nimes',           43.8321558,  4.3428586,  1),
  ('Nevers',          46.9852047,  3.1597652,  1),
  ('Montpellier',     43.6100081,  3.8741693,  1),
  ('Laval',           48.0577943, -0.7691828,  1),
  ('Chambery',        45.5822346,  5.9063526,  1),
  ('Angers',          47.4818960, -0.5629347,  1)
on conflict (nom) do nothing;

-- =====================================================================
--  APRÈS avoir créé votre compte sur le site, exécutez cette ligne
--  pour devenir administrateur principal (remplacez l'adresse) :
--
--    update public.profils set role = 'super'
--    where id = (select id from auth.users where email = 'VOTRE@EMAIL.COM');
--
--  Vérification :
--    select p.nom, p.role, u.email from public.profils p
--    join auth.users u on u.id = p.id order by p.role;
-- =====================================================================
