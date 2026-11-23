# TEAMS MBOCK

Tableau de bord de suivi des membres de l'équipe Mbock et des sorties
d'évangélisation, en France.

**En ligne : https://sdkeny.github.io/TEAMS-MBOCK/**

## Ce que fait le tableau de bord

L'application est organisée en **cinq pages**, accessibles par le menu en
haut de l'écran :

- **Accueil** — page de présentation : bandeau avec compteurs animés, texte
  « Qui sommes-nous », galerie de photos de l'équipe, et la liste des
  **membres connectés en ce moment** (présence en temps réel).
- **Effectifs** — les 22 villes de l'équipe avec leurs effectifs réels, en
  graphique ; une **courbe d'évolution** (membres cumulés par année) et un
  **histogramme des nouveaux membres par année** ; une **carte de répartition**
  en France ; enfin la liste des membres ville par ville, avec recherche et
  filtres. Chaque personne est *Nouveau*, *En intégration*, *Membre* ou
  *À relancer*. N'importe quel membre connecté peut enregistrer une personne.
- **Prier** — on y **ajoute un sujet de prière** directement (pour l'équipe,
  ou lié à une personne), on le marque *exaucé*, et on **enregistre des heures
  de prière** en saisissant l'**heure de début et de fin** (la durée se calcule
  seule, veillées à cheval sur minuit comprises). Le total se cumule pour toute
  l'équipe, avec un **objectif d'heures** (défini par un administrateur) et une
  barre de progression. Sujets en cours, sujets exaucés et journal des heures :
  la vue à projeter en réunion de prière.
- **Évangélisation** — le journal des sorties : date, ville, lieu, nombre
  d'évangélistes, personnes rencontrées et décisions, avec un compte-rendu
  facultatif. Des indicateurs résument l'activité (total, ce mois-ci…).
- **Retraites** — les temps de ressourcement de l'équipe, séparés en
  *à venir* et *passées* : titre, dates, lieu, participants, thème et
  programme. La prochaine retraite est mise en avant.

Le reste est transversal : **commentaires** (un fil de suivi par personne) et
**export** JSON complet ou CSV pour Excel, réservé aux administrateurs.

### Photos de l'équipe

La galerie de la page d'accueil affiche des emplacements de démonstration
tant qu'aucune photo n'est fournie. Pour vos vraies photos : placez-les dans
un dossier `images/` à côté de `index.html`, puis renseignez la liste
`PHOTOS` en haut du script (`{ src: "images/…jpg", cap: "légende" }`).

## Accès

Chaque personne crée son accès à la première ouverture. Les mots de passe se
terminent par `.mbock`, avec au moins 6 caractères et un mélange
lettres/chiffres avant le suffixe. Ils ne sont jamais stockés en clair :
seule une empreinte PBKDF2-HMAC-SHA256 (600 000 itérations, sel aléatoire
par personne) est conservée.

L'administrateur principal est **Désiré KENY**, inscrit dans le code. Lui seul
nomme les autres administrateurs, dans la limite de 4 au total. Les
administrateurs sont les seuls à pouvoir exporter et importer les fichiers.

## Limites à connaître

Cette page fonctionne **sans serveur**. Deux conséquences :

1. **Les données ne sont pas partagées.** Tout est enregistré dans le
   navigateur de chaque personne (`localStorage`). Ce que Grenoble saisit
   n'apparaît pas chez Lyon. Pour transmettre l'ensemble, un administrateur
   exporte le JSON et le fait importer aux autres.
2. **Le portail protège l'usage, pas les données.** Quelqu'un qui ouvre les
   outils développeur peut lire le contenu du navigateur sans mot de passe.
   Les mots de passe et les rôles organisent le travail de l'équipe ; ils ne
   résistent pas à une personne déterminée.

Un partage réel et un contrôle d'accès véritable demandent un backend
(Supabase ou Firebase).

## Données publiées

Ce dépôt ne contient **que l'application et un jeu de test** : 152 fiches aux
noms fictifs, générées pour remplir chaque ville à son effectif réel. Aucune
donnée personnelle d'un membre de l'équipe ne s'y trouve, et le `.gitignore`
est configuré pour que les exports n'y arrivent jamais par inadvertance.

## Fichiers

| Fichier | Rôle |
|---|---|
| `index.html` | L'application entière — HTML, CSS et JavaScript. |
| `supabase/schema.sql` | Le schéma de la base partagée, à exécuter une fois. |
| `supabase/sorties.sql` | Ajoute la table des sorties d'évangélisation. À exécuter dans l'éditeur SQL de Supabase pour activer la page **Évangélisation** (tant qu'elle n'est pas exécutée, la page s'affiche vide sans bloquer le reste). |
| `supabase/retraites.sql` | Ajoute la table des retraites d'équipe. À exécuter de la même façon pour activer la page **Retraites**. |
| `supabase/priere.sql` | Rend les sujets de prière détachables d'une personne (sujets d'équipe) et ajoute la table des **heures de prière**. À exécuter pour activer ces fonctions de la page **Prier**. |
| `supabase/objectifs.sql` | Ajoute la table des **objectifs** d'heures (plusieurs, nommés) et relie chaque heure à un objectif. À exécuter pour activer les objectifs de la page **Prier**. |
| `supabase/reinit_mdp.sql` | Permet à l'administrateur principal de **donner un nouveau mot de passe** à un membre depuis le site (bouton « Mot de passe » du panneau Administrateurs), sans e-mail. |
