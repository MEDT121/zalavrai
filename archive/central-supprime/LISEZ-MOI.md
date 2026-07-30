# Projet central — archivé

L'application a servi plusieurs écoles par l'intermédiaire d'un projet
Supabase central : licences, site public, commandes de cartes, et une Edge
Function qui vérifiait les codes de connexion.

Cette architecture a été abandonnée. La cause immédiate : l'empreinte du
code de connexion était calculée par **deux programmes distincts** qui
devaient rester d'accord. L'un a évolué, l'autre non, et tous les comptes
se sont fermés d'un coup, sans autre message que « Nom ou code incorrect ».

L'application sert désormais **une seule école** et parle directement à sa
base. Il n'y a plus de second service dont dépendre.

Ces fichiers sont conservés — sans être exécutés — pour le cas où le
fonctionnement multi-école reviendrait :

| Fichier | Rôle |
|---|---|
| `central_supabase_migration.sql` | tables du projet central |
| `central_card_orders.sql` | commandes de cartes |
| `central_rls_hardening.sql` | fermeture de la lecture client sur `schools` |
| `supabase_multitenant_migration.sql` | RLS par `school_id` sur la base école |

Pour réactiver : renseigner `CENTRAL_URL` / `CENTRAL_KEY` et `LOGIN_FN_URL`
dans `index.html`. Les trois écrans concernés — habillage, site vitrine,
annonces — se testent d'eux-mêmes et se réveilleront.
