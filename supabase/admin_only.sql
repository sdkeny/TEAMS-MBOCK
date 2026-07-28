-- =====================================================================
--  TEAMS MBOCK — réserver aux administrateurs :
--  la création/modification/suppression des objectifs ET des heures.
--  La lecture reste ouverte à toute l'équipe.
--  À coller dans Supabase ▸ SQL Editor ▸ New query, puis « Run ».
-- =====================================================================

-- ---------------------------------------------------------------------
--  0. Sécurité : s'assurer que TON compte est bien administrateur,
--     pour ne pas te bloquer toi-même. (Adapte l'e-mail si besoin.)
-- ---------------------------------------------------------------------
update public.profils set role = 'super'
where id = (select id from auth.users where email = 'sevarainkeny@gmail.com');

-- ---------------------------------------------------------------------
--  1. Objectifs : lecture pour tous, écriture réservée aux admins
-- ---------------------------------------------------------------------
drop policy if exists objectifs_ecriture on public.objectifs;
drop policy if exists objectifs_admin    on public.objectifs;
create policy objectifs_admin on public.objectifs
  for all to authenticated using (public.est_admin()) with check (public.est_admin());
-- (la politique objectifs_lecture « select using(true) » reste en place)

-- ---------------------------------------------------------------------
--  2. Heures de prière : lecture pour tous, écriture réservée aux admins
-- ---------------------------------------------------------------------
drop policy if exists heures_ajout    on public.priere_heures;
drop policy if exists heures_maj       on public.priere_heures;
drop policy if exists heures_suppr     on public.priere_heures;
drop policy if exists heures_admin_ins on public.priere_heures;
drop policy if exists heures_admin_upd on public.priere_heures;
drop policy if exists heures_admin_del on public.priere_heures;

create policy heures_admin_ins on public.priere_heures
  for insert to authenticated with check (public.est_admin());
create policy heures_admin_upd on public.priere_heures
  for update to authenticated using (public.est_admin()) with check (public.est_admin());
create policy heures_admin_del on public.priere_heures
  for delete to authenticated using (public.est_admin());
-- (la politique heures_lecture « select using(true) » reste en place)

-- ---------------------------------------------------------------------
--  Vérification : qui est administrateur ?
--    select nom, role from public.profils order by role;
-- =====================================================================
