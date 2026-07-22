# TEAMS MBOCK

Tableau de bord de suivi des membres de l'équipe Mbock et des sorties
d'évangélisation, en France.

**En ligne : https://sdkeny.github.io/TEAMS-MBOCK/**

## Ce que fait le tableau de bord

- **Membres par ville** — les 22 villes de l'équipe, avec leurs effectifs et
  leurs coordonnées réelles, en graphique et sur une carte de France.
- **Suivi par étape** — chaque personne est *Nouveau*, *En intégration*,
  *Membre* ou *À relancer* ; la répartition est cliquable pour filtrer.
- **Ajout de membres** — n'importe quel membre connecté peut enregistrer une
  personne rencontrée en sortie. L'ajout est signé automatiquement.
- **Sujets de prière** — chaque personne confie ses sujets ; ils se marquent
  *exaucés*. Un panneau rassemble tous les sujets en cours, toutes villes
  confondues : c'est la vue à projeter en réunion de prière.
- **Commentaires** — un fil de suivi par personne.
- **Export** — sauvegarde JSON complète ou CSV pour Excel, réservé aux
  administrateurs.

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
| `index.html` | L'application entière — HTML, CSS et JavaScript, sans aucune dépendance externe. |

Pour l'utiliser hors ligne, il suffit de télécharger `index.html` et de
l'ouvrir dans un navigateur.
