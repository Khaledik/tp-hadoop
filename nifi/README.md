# Conteneur NiFi (séquence 07 du cours)

## Démarrage

NiFi est un service du `docker-compose.yml` — rien à builder, l'image
officielle `apache/nifi:2.11.0` est utilisée telle quelle :

```bash
cp nifi/credentials.env.example nifi/credentials.env   # une seule fois
docker compose up -d          # ou : docker compose up -d nifi
# UI : https://localhost:8443/nifi
```

### Le login (à ne pas rater avant une séance)

NiFi 2.x impose le **HTTPS** (certificat auto-signé : le navigateur propose
« accepter le risque », une fois), **puis** un écran de connexion — il n'y a
plus de mode anonyme. Le couple est lu dans `nifi/credentials.env` :

```
SINGLE_USER_CREDENTIALS_USERNAME=etudiant
SINGLE_USER_CREDENTIALS_PASSWORD=...   # 12 caracteres MINIMUM
```

`credentials.env` n'est **pas versionné** (seul le `.example` l'est) :
aucun secret en dur dans git.

**Le piège, mesuré sur `apache/nifi:2.11.0`** : si le fichier est absent
**ou si le mot de passe fait moins de 12 caractères**, NiFi affiche
`ERROR: Password must be at least 12 characters`, **démarre quand même**, et
négocie un couple aléatoire qu'il écrit dans les logs :

```bash
docker logs hadoop-nifi | grep -A1 "Generated Username"
```

Le couple change à chaque recréation du conteneur : le cours perd la main sur
son propre écran de login. D'où le fichier local et la longueur minimale.

## Volumes montés

| Chemin hôte | Chemin conteneur | Rôle |
|---|---|---|
| `nifi/input/` | `/opt/nifi/input` | entrée des fichiers à ingérer (**GetFile**) |
| `nifi/output/` | `/opt/nifi/output` | sortie du flux (**PutFile**) |
| `nifi/output/` | `/home/staging` *(dans le **master**)* | le même dossier, côté Hadoop |
| `nifi/errors/` | `/opt/nifi/errors` | relations `failure` câblées |
| `nifi/hadoop/` | `/opt/nifi/hadoop` | configuration Hadoop du cluster |

Le double montage de `nifi/output/` est ce qui permet d'enchaîner sans copier
de fichier à la main :

```bash
# depuis le master
hdfs dfs -moveFromLocal /home/staging/Spotify_Most_Streamed_Songs.csv /user/root/spotify/clean/
```

## Pourquoi le flux s'arrête à `PutFile`

L'image officielle **n'embarque aucun bundle Hadoop** : `PutHDFS` n'est pas
connu de l'instance, et il n'y a rien à « activer ». Vérifiable :

```bash
docker exec hadoop-nifi sh -c "ls /opt/nifi/nifi-current/work/nar/extensions/ | wc -l"
# 118
docker exec hadoop-nifi sh -c "ls /opt/nifi/nifi-current/work/nar/extensions/ | grep -ci hdfs"
# 0
```

Le cours assume donc `GetFile → ConvertRecord → PutFile`, puis le dépôt HDFS à
la main : le geste HDFS reste visible (voir EX/07 du cours). Le montage
`nifi/hadoop/` est conservé — inutile tant que `PutHDFS` n'est pas installé,
mais requis dès qu'on ajoute le bundle.

### Ajouter le bundle (hors périmètre du cours)

Le chemin d'autoload est lu dans `conf/nifi.properties` :

```
nifi.nar.library.autoload.directory=/opt/nifi/nifi-current/nar_extensions
```

Monter `./nifi/nar_extensions` sur ce chemin, y déposer un
`nifi-hadoop-processors` compilé pour **2.11**, redémarrer. À valider **hors
groupe** : un NAR mal compilé peut empêcher NiFi de démarrer, et emporter la
séance avec lui.

## Pourquoi la branche 2.x ?

Le cluster local tourne sur **Hadoop 3.3.6** : NiFi 2.x (Java 21 embarqué
dans l'image, client Hadoop 3.x) est le couple cohérent — l'argument
d'ancienne note « rester en 1.x pour un Hadoop 2.x » ne s'applique plus.

## Données

Déposer le CSV Spotify à ingérer directement dans `nifi/input/` :

```bash
cp /chemin/vers/Spotify_Most_Streamed_Songs.csv nifi/input/
```

Gardez une **copie ailleurs** : `Keep Source File = false` supprime le fichier
d'entrée après capture, et une démo rejouée se retrouve les mains vides.
