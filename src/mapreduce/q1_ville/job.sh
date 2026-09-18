#!/bin/bash

# Fichier d'entrée dans HDFS
INPUT="/user/root/tp_hadoop/input/dataw_fro03.csv"

# Dossier de sortie du job
OUTPUT="/user/root/tp_hadoop/output/q1_ville"

# Suppression de l'ancienne sortie si elle existe
hdfs dfs -rm -r -f "$OUTPUT"

# Lancement du job MapReduce
hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
-file mapper.py -mapper "python3 mapper.py" \
-file reducer.py -reducer "python3 reducer.py" \
-input "$INPUT" \
-output "$OUTPUT"

echo ""
echo "Premières lignes du résultat :"
hdfs dfs -cat ${OUTPUT}/part-* | head

echo ""
echo "Top 10 des villes :"
hdfs dfs -cat ${OUTPUT}/part-* | sort -t$'\t' -k2,2nr | head -10