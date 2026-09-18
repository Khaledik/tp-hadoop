# Incident — EXPLAIN échoue sur les agrégations de tables partitionnées (Hive 4.1.0)

> **Type** : incident / correctif
> **Stack** : Hadoop 3.3.6 + HBase 2.5.15 + ZooKeeper 3.8.6 + Hive 4.1.0 (`Dockerfile.debian`)
> **Date** : 2026-09-16
> **Statut** : corrigé à chaud sur `hadoop-master` — à intégrer à l'image (voir [Prévention](#prévention--intégration-à-limage-à-faire-plustard))

## Symptôme

Depuis **Beeline**, l'EXPLAIN d'une requête **avec agrégation** portant sur une **table partitionnée** échoue systématiquement :

```
0: jdbc:hive2://localhost:10000> EXPLAIN SELECT COUNT(*) FROM spotify_part WHERE released_year = 2022;
Error: Error running query; Query ID: root_20260916130159_ed21af34-08de-4714-9500-826c7c36abf6 (state=,code=0)
```

Faits observés, qui ont guidé le diagnostic :

| Test | Résultat |
|---|---|
| `EXPLAIN SELECT COUNT(*) FROM spotify_part WHERE released_year = 2022;` | **Échec** `Error running query` |
| `EXPLAIN SELECT COUNT(*) FROM spotify_part;` (sans filtre) | **Échec** — le bug ne dépend pas du filtre de partition |
| `EXPLAIN SELECT COUNT(*) FROM spotify;` (table **non** partitionnée) | Succès |
| `EXPLAIN SELECT track_name FROM spotify_part;` (sans agrégation) | Succès |
| `SELECT COUNT(*) FROM spotify_part WHERE released_year = 2022;` | Succès (**402** lignes) — le **plan d'exécution réel fonctionne**, l'élagage de partition marche |

La donnée est lue et agrégée normalement ; c'est **la compilation de l'EXPLAIN** qui casse, et uniquement quand l'agrégation est présente (chemin du calcul d'estimation de stats) sur une table partitionnée.

## Diagnostic

Beeline masque l'exception réelle (bug connu [HIVE-26345](https://issues.apache.org/jira/browse/HIVE-26345) : seuls code et state sont remontés, `state=,code=0`). La vraie trace est dans le log HiveServer2 (`/home/hiveserver2.log`) :

```text
java.lang.NoClassDefFoundError: org/apache/tez/mapreduce/hadoop/InputSplitInfo
        at org.apache.hadoop.hive.ql.optimizer.stats.annotation.StatsRulesProcFactory$GroupByStatsRule.checkMapSideAggregation(...)
```

## Cause racine

Le tarball `apache-hive-4.1.0-bin` est **incomplet pour ce chemin de code** :

- `/opt/hive/lib/` contient `tez-api-0.10.5.jar` et `hive-llap-tez-4.1.0.jar`, mais **pas** de `tez-mapreduce-*.jar` ;
- la classe `org.apache.tez.mapreduce.hadoop.InputSplitInfo` n'existe dans **aucun** des deux jars présents (vérifié : `jar tf <jar> | grep InputSplitInfo` → aucune sortie) ;
- l'optimiseur de statistiques de Hive 4 (`StatsRulesProcFactory$GroupByStatsRule`) référence cette classe Tez **de façon inconditionnelle**, même quand le moteur d'exécution est `mr` (`hive.execution.engine=mr`) — pas Tez ;
- conséquence : toute compilation d'EXPLAIN passant par l'estimation de stats (agrégations) sur une table partitionnée plante au chargement de la classe.

Ce n'est ni une erreur de requête ni un problème de données — y compris la partition `__HIVE_DEFAULT_PARTITION__` (ligne d'en-tête des données, soulevée pendant l'analyse) qui s'est avérée **hors sujet**.

## Correctif immédiat (conteneur déjà déployé)

Installer le jar manquant, version **identique à `tez-api` déjà présent** (0.10.5) :

### 1. Côté hôte — télécharger et copier dans le conteneur

```bash
curl -O https://repo1.maven.org/maven2/org/apache/tez/tez-mapreduce/0.10.5/tez-mapreduce-0.10.5.jar
docker cp tez-mapreduce-0.10.5.jar hadoop-master:/opt/hive/lib/
```

### 2. Côté master — redémarrer HiveServer2

```bash
pkill -f HiveServer2        # ou : kill -9 <PID du processus RunJar HiveServer2>
./start-hive.sh             # relance le service sur le port 10000
```

> Le `tez-mapreduce-0.10.5.jar` vivant dans `/opt/hive/lib/`, dans cette image `/opt/hive` est **image-native** (pas un bind mount) : la correction **survit au redémarrage du conteneur** mais est **perdue à la reconstruction de l'image** — d'où la prévention ci-dessous.

## Vérification

```sql
EXPLAIN SELECT COUNT(*) FROM spotify_part WHERE released_year = 2022;
```

Résultat attendu : le plan affiche bien l'élagage de partition

```text
Statistics: Num rows: 402
TableScan ... released_year=2022
```

et ne mentionne **que** `released_year=2022` — les autres dossiers ne sont pas lus (objectif pédagogique de l'EX 05, partie II.3).

## Prévention — intégration à l'image (à faire plus tard)

À intégrer au `Dockerfile.debian`, dans le stage builder, juste après le téléchargement de Hive :

```dockerfile
# Hive 4.1.0 livre tez-api mais pas tez-mapreduce : classe requise par
# StatsRulesProcFactory$GroupByStatsRule (compile d'un EXPLAIN agrégé sur table
# partitionnée, même en moteur MR) -> NoClassDefFoundError InputSplitInfo.
RUN curl -fsSL https://repo1.maven.org/maven2/org/apache/tez/tez-mapreduce/0.10.5/tez-mapreduce-0.10.5.jar \
    -o /opt/hive/lib/tez-mapreduce-0.10.5.jar
```

(Le `Dockerfile.rocky` ne contient pas Hive : rien à faire.)

## Références

- [HIVE-26345](https://issues.apache.org/jira/browse/HIVE-26345) — Beeline masque l'exception réelle (`Error running query (state=,code=0)`)
- Maven Central — `org/apache/tez/tez-mapreduce/0.10.5/tez-mapreduce-0.10.5.jar`
- Annexes de diagnostic écartées (hors cause) : partition `__HIVE_DEFAULT_PARTITION__` (en-tête de fichier), CBO, encodage des sessions Beeline