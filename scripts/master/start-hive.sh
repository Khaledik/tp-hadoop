#!/bin/bash

echo "[INFO] Starting HiveServer2 (Derby metastore embarqué)..."

# Le metastore Derby vit dans /home/metastore_db (persiste via le bind mount).
# Une seule session à la fois (verrou Derby) : cf. README.
mkdir -p /home/metastore_db 2>/dev/null

# Initialisation du schéma du metastore au premier lancement uniquement
# (HiveServer2 refuse de démarrer sur un metastore sans schéma).
if [ -z "$(ls -A /home/metastore_db 2>/dev/null)" ]; then
    echo "[INFO] Initialisation du schéma Derby (première fois, ~1 min)..."
    $HIVE_HOME/bin/schematool -dbType derby -initSchema \
        > /home/schematool.log 2>&1 \
        || echo "[WARN] schematool a échoué — voir /home/schematool.log"
fi

# Entrepôt HDFS des tables managées et des CREATE DATABASE (idempotent ;
# silencieux si start-hive.sh est lancé avant le DFS).
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse 2>/dev/null

# hiveserver2 hérite de hadoop-env.sh (HADOOP_HEAPSIZE 192 / Metaspace 64m —
# trop juste pour Hive : OutOfMemoryError au chargement des classes). Ces
# variables surchargent les valeurs par défaut : l'entrypoint les écrit en
# "paramétrable" dans hadoop-env.sh, et l'environnement prime dessus.
export HADOOP_HEAPSIZE=512
export HADOOP_METASPACE_MAX=256m

$HIVE_HOME/bin/hive --service hiveserver2 > /home/hiveserver2.log 2>&1 &

# Attendre que le port JDBC réponde (jusqu'à ~60 s)
for i in $(seq 1 30); do
    if nc -z localhost 10000 2>/dev/null; then
        echo "[INFO] HiveServer2 is up (jdbc:hive2://localhost:10000)."
        echo "[INFO] Se connecter avec : beeline -u jdbc:hive2://localhost:10000"
        exit 0
    fi
    sleep 2
done

echo "[WARN] HiveServer2 ne répond pas encore sur le port 10000."
echo "[INFO] Logs : /home/hiveserver2.log"
exit 0
