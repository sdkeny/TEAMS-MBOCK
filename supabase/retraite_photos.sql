-- =====================================================================
--  TEAMS MBOCK — photos des retraites (Supabase Storage)
--  À coller dans Supabase ▸ SQL Editor ▸ New query, puis « Run ».
--  Crée l'espace de stockage des photos + la colonne « images ».
--  Réexécutable sans risque.
-- =====================================================================

-- ---------------------------------------------------------------------
--  1. Colonne pour stocker les URLs des photos sur la table des retraites
-- ---------------------------------------------------------------------
alter table public.retraites
  add column if not exists images jsonb not null default '[]'::jsonb;

-- ---------------------------------------------------------------------
--  2. Espace de stockage (« bucket ») public pour les photos
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('retraites', 'retraites', true)
on conflict (id) do update set public = true;

-- ---------------------------------------------------------------------
--  3. Règles d'accès aux fichiers
--     Lecture : publique (bucket public). Envoi / suppression : membres
--     connectés seulement.
-- ---------------------------------------------------------------------
drop policy if exists "retraites_photos_read"   on storage.objects;
create policy "retraites_photos_read" on storage.objects
  for select using (bucket_id = 'retraites');

drop policy if exists "retraites_photos_upload" on storage.objects;
create policy "retraites_photos_upload" on storage.objects
  for insert to authenticated with check (bucket_id = 'retraites');

drop policy if exists "retraites_photos_delete" on storage.objects;
create policy "retraites_photos_delete" on storage.objects
  for delete to authenticated using (bucket_id = 'retraites');
