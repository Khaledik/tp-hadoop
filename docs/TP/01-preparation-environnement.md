# 01 - Préparation de l'environnement

## Objectif

Avant de commencer les traitements, j'ai d'abord remis le cluster Hadoop en route et vérifié que les différents services fonctionnaient correctement.

Ensuite, j'ai déposé le fichier de données dans le master puis dans HDFS afin de pouvoir l'utiliser dans les prochaines parties du TP.

---

## 1. Démarrage des conteneurs

J'ai lancé les conteneurs avec Docker Compose :

```powershell
docker compose up -d
```

Puis j'ai vérifié que les conteneurs étaient bien lancés :

```powershell
docker ps
```

Les principaux conteneurs utilisés sont :

```text
hadoop-master
hadoop-slave1
hadoop-slave2
hadoop-nifi
```

---

## 2. Connexion au master

Je me suis connecté au conteneur master avec :

```powershell
docker exec -it hadoop-master bash
```

J'arrive ensuite dans :

```text
root@hadoop-master:/home#
```

---

## 3. Démarrage et vérification des services

Depuis le master, j'ai lancé les services du cluster avec :

```bash
./start-all.sh
```

Le script démarre notamment :

- ZooKeeper
- HDFS
- YARN
- MapReduce JobHistory
- HBase
- Thrift
- HBase REST
- HiveServer2

À la fin, j'ai obtenu :

```text
[INFO] HiveServer2 is up (jdbc:hive2://localhost:10000).
[INFO] All services started successfully.
```

J'ai ensuite vérifié les processus du master avec :

```bash
jps
```

Résultat obtenu :

```text
1776 RESTServer
52 QuorumPeerMain
262 NameNode
695 ResourceManager
2521 Jps
1513 HMaster
475 SecondaryNameNode
2076 RunJar
1692 ThriftServer
1036 JobHistoryServer
```

Les principaux services sont donc bien présents.

Ce que je retiens :

- `NameNode` : gère HDFS et sait où se trouvent les blocs de données
- `SecondaryNameNode` : réalise les checkpoints du NameNode
- `ResourceManager` : gère les ressources YARN
- `JobHistoryServer` : conserve l'historique des jobs MapReduce
- `HMaster` : gère HBase
- `ThriftServer` : permet notamment d'utiliser HBase depuis Python avec HappyBase
- `RESTServer` : expose l'API REST HBase
- `QuorumPeerMain` : correspond à ZooKeeper
- `RunJar` : correspond ici au processus HiveServer2

J'ai également vérifié les deux slaves depuis mon poste :

```powershell
docker exec hadoop-slave1 jps
docker exec hadoop-slave2 jps
```

On y retrouve principalement :

```text
DataNode
NodeManager
HRegionServer
```

- `DataNode` : stocke les blocs HDFS
- `NodeManager` : exécute les tâches YARN
- `HRegionServer` : stocke et sert les données HBase

### Interfaces Web

Plusieurs interfaces permettent aussi de vérifier l'état du cluster :

| Service | Adresse |
|---|---|
| HDFS / NameNode | http://localhost:9870 |
| YARN / ResourceManager | http://localhost:8088 |
| MapReduce JobHistory | http://localhost:19888 |
| NodeManager slave1 | http://localhost:8041 |
| NodeManager slave2 | http://localhost:8042 |
| HBase Master | http://localhost:16010 |
| HiveServer2 | http://localhost:10002 |
| NiFi | https://localhost:8443/nifi |

---

## 4. Dépôt du fichier de données dans le master

Les fichiers fournis pour le TP sont rangés dans :

```text
data/raw/
```

avec :

```text
data/raw/dataw_fro03.csv
data/raw/dataw_fro03_mini_1000.csv
```

Pour cette partie, j'utilise uniquement le fichier principal `dataw_fro03.csv`.

Le fichier `dataw_fro03_mini_1000.csv` sera utilisé plus tard pour la partie NiFi.

Depuis PowerShell, à la racine du projet :

```powershell
docker cp .\data\raw\dataw_fro03.csv hadoop-master:/home/dataw_fro03.csv
```

Puis je retourne dans le master :

```powershell
docker exec -it hadoop-master bash
```

Je vérifie que le fichier est bien présent :

```bash
ls -lh /home/dataw_fro03.csv
```

Le fichier est maintenant présent dans le système de fichiers du conteneur master.

---

## 5. Dépôt et vérification dans HDFS

Je crée un dossier dédié au TP dans HDFS :

```bash
hdfs dfs -mkdir -p /user/root/tp_hadoop/input
```

Puis je dépose le fichier :

```bash
hdfs dfs -put -f /home/dataw_fro03.csv /user/root/tp_hadoop/input/
```

Je vérifie ensuite qu'il est bien présent :

```bash
hdfs dfs -ls -h /user/root/tp_hadoop/input
```

Le fichier est maintenant stocké dans HDFS et pourra être utilisé par les jobs Hadoop.

---

## 6. Vérification du contenu depuis HDFS

Le sujet demande d'afficher les 5 premières et les 5 dernières lignes directement depuis HDFS.

### 5 premières lignes

```bash
hdfs dfs -cat /user/root/tp_hadoop/input/dataw_fro03.csv | head -5
```

### 5 dernières lignes

```bash
hdfs dfs -cat /user/root/tp_hadoop/input/dataw_fro03.csv | tail -5
```

Ces commandes permettent de vérifier que le fichier a bien été transféré et qu'il est lisible depuis HDFS.

J'ai gardé une capture des résultats pour le rendu.

---

## 7. Analyse de la source de données

Le fichier contient des informations sur les clients, les commandes et les articles commandés.

Pour la suite du TP, les champs qui vont surtout être utiles sont :

```text
villecli
datcde
qte
```

avec :

```text
villecli - ville du client
datcde   - date de la commande
qte      - quantité commandée
```

Pour calculer le nombre d'articles commandés par ville, il faudra additionner `qte` pour chaque `villecli`.

Pour le calcul par ville et par année, il faudra également récupérer l'année contenue dans `datcde`.

### Dictionnaire des données

| Colonne | Description |
|---|---|
| `codcli` | Identifiant du client |
| `genrecli` | Civilité / genre du client |
| `nomcli` | Nom du client |
| `prenomcli` | Prénom du client |
| `cpcli` | Code postal du client |
| `villecli` | Ville du client |
| `codcde` | Identifiant de la commande |
| `datcde` | Date de la commande |
| `timbrecli` | Information liée au timbre / frais client |
| `timbrecde` | Information liée au timbre / frais commande |
| `Nbcolis` | Nombre de colis |
| `cheqcli` | Information liée au règlement client |
| `barchive` | Indicateur d'archivage |
| `bstock` | Indicateur de stock |
| `codobj` | Identifiant de l'objet |
| `qte` | Quantité commandée |
| `Colis` | Information liée au colis |
| `libobj` | Libellé de l'objet |
| `Tailleobj` | Taille de l'objet |
| `Poidsobj` | Poids de l'objet |
| `points` | Nombre de points |
| `indispobj` | Indicateur d'indisponibilité |
| `libcondit` | Libellé du conditionnement |
| `prixcond` | Prix du conditionnement |
| `puobj` | Prix unitaire de l'objet |

---

## Conclusion

Le cluster est démarré et les principaux services ont été vérifiés.

Le fichier `dataw_fro03.csv` est présent dans le master puis a été déposé dans HDFS dans :

```text
/user/root/tp_hadoop/input/dataw_fro03.csv
```

Les premières et dernières lignes ont également été vérifiées directement depuis HDFS.