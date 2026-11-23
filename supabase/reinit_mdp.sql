-- =====================================================================
--  TEAMS MBOCK — réinitialisation d'un mot de passe par un administrateur,
--  sans e-mail (utile quand l'envoi d'e-mails ne fonctionne pas).
--  À coller dans Supabase ▸ SQL Editor ▸ New query, puis « Run ».
--
--  Règles :
--   - l'administrateur principal (super) peut réinitialiser tout le monde ;
--   - un administrateur peut réinitialiser seulement les simples membres ;
--   - le mot de passe doit faire 8 caractères et mêler lettres et chiffres.
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

create or replace function public.admin_reinit_mdp(cible uuid, nouveau text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  role_cible text;
begin
  if not public.est_admin() then
    raise exception 'Réservé aux administrateurs.';
  end if;

  select role into role_cible from public.profils where id = cible;
  if role_cible is null then
    raise exception 'Compte introuvable.';
  end if;
  if role_cible in ('admin', 'super') and not public.est_super() then
    raise exception 'Seul l''administrateur principal peut réinitialiser un administrateur.';
  end if;

  if length(nouveau) < 8 or nouveau !~ '[A-Za-zÀ-ÿ]' or nouveau !~ '[0-9]' then
    raise exception 'Le mot de passe doit faire au moins 8 caractères et mêler lettres et chiffres.';
  end if;

  update auth.users
     set encrypted_password = extensions.crypt(nouveau, extensions.gen_salt('bf')),
         updated_at = now()
   where id = cible;
end;
$$;

revoke all on function public.admin_reinit_mdp(uuid, text) from public, anon;
grant execute on function public.admin_reinit_mdp(uuid, text) to authenticated;
