# TP Hadoop - Analyse des ventes par ville

**Auteur : Khaled IKHLEF**

## Présentation

Ce projet correspond au TP final Hadoop réalisé à partir du fichier de ventes `dataw_fro03.csv`.

L'objectif est de manipuler plusieurs outils de l'écosystème Hadoop autour d'un même jeu de données afin de comparer leurs rôles et de vérifier la cohérence des résultats obtenus.

Les technologies utilisées sont :

- Docker
- HDFS
- YARN
- MapReduce avec Hadoop Streaming
- Python
- HBase
- HappyBase
- Matplotlib
- Hive
- NiFi

---

## Objectifs du TP

Le projet répond principalement aux questions suivantes :

### Q1 - Quelles villes commandent le plus d'articles ?

Le calcul est d'abord réalisé avec MapReduce.

Le résultat principal obtenu est :

```text
LE MANS = 3019 articles
```

### Q2 - Quelle ville#année commande le plus d'articles ?

Le classement montre une égalité en première position :

```text
BEAUFORT EN VALLEE#2012 = 305
LE MANS#2010 = 305
```

### Q3 - Retrouver le total d'articles d'une ville avec HBase

Les résultats de Q1 sont enregistrés dans HBase avec :

```text
rowkey = ville
stats:total_articles = total commandé
```

La valeur obtenue pour `LE MANS` est également :

```text
3019
```

### Q4 - Refaire les classements avec Hive

Les calculs Q1 et Q2 sont reproduits avec des requêtes SQL Hive.

Les résultats obtenus sont identiques à ceux des jobs MapReduce.

Le moteur d'exécution configuré dans l'environnement est :

```text
hive.execution.engine=mr
```

Hive utilise donc MapReduce pour exécuter les traitements dans ce cluster.

### Q5 - Ingérer de nouvelles données avec NiFi

Un mini fichier CSV est traité avec le flow :

```text
GetFile
   ↓
ConvertRecord
   ↓
PutFile
```

NiFi transforme le CSV en TSV contenant uniquement :

```text
villecli
datcde
qte
```

Le fichier généré contient :

```text
999 lignes
```

Après son ajout dans le dossier HDFS lu par Hive, le nombre de lignes passe de :

```text
135274
```

à :

```text
136273
```

soit :

```text
+999 lignes
```

---

## Documentation

Le TP est documenté étape par étape dans les fichiers suivants :

- [01 - Préparation de l'environnement](docs/01-preparation-environnement.md)
- [02 - MapReduce](docs/02-mapreduce.md)
- [03 - HBase](docs/03-hbase.md)
- [04 - Visualisation](docs/04-visualisation.md)
- [05 - Hive](docs/05-hive.md)
- [06 - NiFi](docs/06-nifi.md)

Chaque partie contient :

- le contexte
- les commandes utilisées
- le code
- les résultats obtenus
- les captures d'écran
- une conclusion

---

## Arborescence du projet

```text
.
├── README.md
│
├── data/
│   └── raw/
│       ├── dataw_fro03.csv
│       └── dataw_fro03_mini_1000.csv
│
├── docs/
│   ├── 01-preparation-environnement.md
│   ├── 02-mapreduce.md
│   ├── 03-hbase.md
│   ├── 04-visualisation.md
│   ├── 05-hive.md
│   └── 06-nifi.md
│
├── src/
│   ├── mapreduce/
│   │   ├── q1_ville/
│   │   │   ├── mapper.py
│   │   │   ├── reducer.py
│   │   │   └── job.sh
│   │   │
│   │   └── q2_ville_annee/
│   │       ├── mapper.py
│   │       ├── reducer.py
│   │       └── job.sh
│   │
│   ├── hbase/
│   │   └── q3_ville/
│   │       ├── mapper.py
│   │       ├── reducer_hbase.py
│   │       └── job.sh
│   │
│   ├── visualisation/
│   │   └── top10_villes.py
│   │
│   └── hive/
│       ├── prepare_tsv.py
│       └── queries.sql
│
├── results/
│   ├── hive/
│   │   └── ventes_hive.tsv
│   │
│   └── visualisation/
│       ├── part-00000
│       ├── top10.txt
│       └── resultat.pdf
│
└── screenshots/
    ├── 01-preparation/
    ├── 02-mapreduce/
    ├── 03-hbase/
    ├── 04-visualisation/
    ├── 05-hive/
    └── 06-nifi/
```

---

## Environnement Hadoop

Le cluster est exécuté avec Docker et contient :

```text
hadoop-master
hadoop-slave1
hadoop-slave2
hadoop-nifi
```

Les principaux services utilisés sont :

| Service | Rôle |
| --- | --- |
| HDFS | Stockage distribué des fichiers |
| YARN | Gestion des ressources et exécution des jobs |
| MapReduce | Traitement distribué |
| HBase | Base NoSQL distribuée |
| Thrift | Accès à HBase depuis HappyBase |
| Hive | Requêtes SQL sur les données HDFS |
| NiFi | Ingestion et transformation des fichiers |

---

## Chemins HDFS utilisés

Le fichier source principal est stocké dans :

```text
/user/root/tp_hadoop/input/dataw_fro03.csv
```

Les résultats MapReduce sont stockés dans :

```text
/user/root/tp_hadoop/output/q1_ville
/user/root/tp_hadoop/output/q2_ville_annee
/user/root/tp_hadoop/output/q3_hbase
```

Les données utilisées par Hive sont stockées dans :

```text
/user/root/tp_hadoop/hive/ventes
```

La table externe Hive pointe directement vers ce dossier.

---

## Résultats principaux

### Top 10 des villes

```text
1. LE MANS : 3019
2. CAEN : 2056
3. FLERS : 1480
4. LAVAL : 1422
5. VIRE NORMANDIE : 1405
6. CHERBOURG EN COTENTIN : 1362
7. ALENCON : 1166
8. ARGENTAN : 938
9. RENNES : 874
10. ATHIS VAL DE ROUVRE : 809
```

### Top ville#année

```text
BEAUFORT EN VALLEE#2012 = 305
LE MANS#2010 = 305
```

Il y a donc une égalité en première position.

---

## Validation croisée

Un des objectifs du projet est de vérifier que plusieurs outils donnent les mêmes résultats.

Pour Q1 :

```text
MapReduce
    ↓
LE MANS = 3019
    ↑
HBase
    ↑
HappyBase / Python
    ↑
Hive
```

Pour Q2 :

```text
MapReduce
    ↓
BEAUFORT EN VALLEE#2012 = 305
LE MANS#2010 = 305
    ↑
Hive
```

Les résultats obtenus sont donc cohérents entre les différents outils.

---

## Visualisation

Les résultats enregistrés dans HBase sont lus avec HappyBase depuis un script Python.

Le script génère :

```text
top10.txt
resultat.pdf
```

Le fichier `resultat.pdf` contient un graphique Matplotlib représentant les 10 villes ayant commandé le plus d'articles.

Les livrables sont disponibles dans :

```text
results/visualisation/
```

---

## Ingestion avec NiFi

Le flow NiFi utilisé est :

```text
GetFile
   ↓
ConvertRecord
   ↓
PutFile
```

Le rôle de chaque composant est :

| Composant | Rôle |
| --- | --- |
| GetFile | Récupère le mini CSV |
| ConvertRecord | Transforme le CSV en TSV et sélectionne les colonnes utiles |
| PutFile | Écrit le fichier transformé dans le dossier de sortie |

La sortie NiFi est ensuite rendue disponible dans le master puis déplacée dans HDFS.

Data Provenance permet de retrouver les événements :

```text
RECEIVE
CONTENT_MODIFIED
SEND
DROP
```

et le lineage permet de suivre le parcours complet du FlowFile.

---

## Matrice de contrôle

Cette matrice résume le rôle des différents composants utilisés dans le TP.

| Question | Composant | Rôle dans le projet |
| --- | --- | --- |
| Qui ingère ? | NiFi | Récupère le mini CSV avec `GetFile` et le transforme avec `ConvertRecord` |
| Qui déplace ? | PutFile + HDFS CLI | `PutFile` dépose le TSV dans le dossier de sortie, puis `hdfs dfs -moveFromLocal` le déplace dans HDFS |
| Qui stocke ? | HDFS / HBase | HDFS stocke les fichiers CSV, TSV et les sorties MapReduce. HBase stocke les résultats agrégés par ville |
| Qui calcule ? | MapReduce / Hive | MapReduce réalise les agrégations distribuées. Hive permet d'écrire les traitements en SQL et utilise ici MapReduce comme moteur |
| Qui sert ? | HiveServer2 / HBase Thrift | HiveServer2 permet d'interroger les données avec Beeline. Thrift permet à HappyBase d'accéder aux données HBase |

On peut résumer le parcours principal ainsi :

```text
NiFi
  ↓
ingestion et transformation
  ↓
HDFS
  ↓
stockage
  ↓
MapReduce / Hive
  ↓
calcul
  ↓
HBase
  ↓
stockage des résultats
  ↓
HappyBase / HiveServer2
  ↓
exploitation des données
```

---

## Livrables

Le projet contient :

- le code source des traitements MapReduce
- le reducer HBase avec HappyBase
- le script de visualisation Python
- les requêtes Hive
- les sorties `part-00000`
- le fichier `top10.txt`
- le graphique `resultat.pdf`
- les fichiers TSV
- les captures d'écran
- la documentation détaillée de chaque étape

---

## Conclusion

Ce TP m'a permis de manipuler plusieurs composants de l'écosystème Hadoop sur un même cas d'utilisation.

Le même jeu de données a été traité avec plusieurs approches :

```text
MapReduce
HBase
Hive
NiFi
Python
```

La validation croisée entre les outils permet de vérifier que les traitements restent cohérents.

Le projet montre également la différence entre les rôles des différents composants :

```text
NiFi      -> ingestion
HDFS      -> stockage
MapReduce -> calcul distribué
HBase     -> stockage NoSQL
Hive      -> requêtes SQL
Python    -> exploitation et visualisation
```

**Khaled IKHLEF**