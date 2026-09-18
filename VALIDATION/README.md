# VALIDATION — kit de validation du cluster

> Ce dossier regroupe les scripts et artefacts de référence pour **valider le
> déploiement du cluster de cours Hadoop**. Le rapport détaillé de la première
> validation est dans l'historique git. Tout est **réutilisable tel quel** sur
> `hadoop-master` (`/home` en bind mount = `scripts/master/`) — exécuté côté
> Docker, aucune installation n'est nécessaire.

> ℹ️ Les artefacts sont également historiquement présents sous `scripts/master/`
> (copie de travail effective sur le master) ; ce dossier `VALIDATION/` est la
> **source de référence versionnée**.

## MapReduce (séquence 04)

| Fichier | Usage |
|---|---|
| `mapper.py`, `reducer.py` | TP 04 — total de streams **par artiste** (644 artistes). `int()` protégé : ligne 576 ignorée. |
| `run_artist_job.sh` | Soumission streaming vers `output/artists/` (1 reducer). |
| `mapper_year.py`, `reducer_year.py` | Exercices MR ex. 1 — total de streams **par année** (50 années). |
| `run_annual_2r.sh` | Même job avec `-D mapreduce.job.reduces=2` → 2 part-files (validation du shuffle multi-reducers). |
| `broken_mapper.py`, `run_broken_job.sh` | Job en échec pédagogique : `int()` **non** protégé → `subprocess failed with code 1` sur l'UI YARN. |

## Hive (séquence 05)

| Fichier | Usage |
|---|---|
| `hive_valid1.sql` | COUNT / COUNT(streams) / SUM et années 1975, 1984, 2023 — crée `spotify_tsv` partitionnée par année. |
| `hive_valid2.sql` | Passage en revue des 51 partitions (50 années + `__HIVE_DEFAULT_PARTITION__` pour l'en-tête). |
| `hive_tsv_valid.sql` | Mêmes aggrégats sur le TSV produit par **NiFi** (contrôle de non-dégradation). |

## HBase (séquence 06)

| Fichier | Usage |
|---|---|
| `hb_test.py` | Roundtrip **HappyBase 1.3.0** sur Thrift 9090 (create/put/scan/delete). |
| `biblio.hb` | Exercice « bibliothèque » de l'EX 06 — rejouable via `hbase shell /home/biblio.hb`, non destructif. |
| `biblio.out` | Sortie de référence du bloc ci-dessus. |

## NiFi (séquence 07) — scripts d'API REST (PowerShell, depuis l'hôte)

Pré-requis : définir `$env:NIFI_USER` / `$env:NIFI_PASS` (valeurs du déploiement
local dans `Hadoop/nifi/credentials.env`, **hors git**). Les scripts interrogent
`https://localhost:8443/nifi-api`.

| Fichier | Usage |
|---|---|
| `nifi-rebuild2.ps1` | (Re)construit le flux complet GetFile → ConvertRecord → PutFile + voie failure par l'API. |
| `nifi-status.ps1` | État (run/stop) de tous les processeurs du PG racine. |
| `nifi-start2.ps1` | Démarre tous les processeurs. |
| `nifi-null.ps1` | Démonstration PUT-fusion : une propriété se **vide** par `null` JSON (le `""` ne suffit pas). |
| `nifi-prov2.ps1` | Interroge la provenance (événements RÉCEPTION/émission récents). |

Pièges couverts par ces scripts (détail dans l'annexe de l'EX 07) :
auth par jeton Bearer (pas de Basic), propriétés nommées avec espaces
(`Record Writer`, `Include Zero Record FlowFiles`), `TIMER_DRIVEN` seul
supporté, suppression de connexion = queue vide + STOPPED.

## Chaîne NiFi → HDFS → Hive

| Fichier | Usage |
|---|---|
| `compare_tsv.sh` | `diff` entre le TSV NiFi et la référence `spotify-clean.tsv` (attendu : 4 artefacts de quoting seulement). |
| `move_tsv.sh` | `hdfs dfs -put` du TSV NiFi vers `/user/root/spotify/clean/` (le « dernier saut » du flux). |
| `spotify-clean.tsv` | Référence TSV « propre » (154 641 octets, 1 en-tête + 953 chansons). |