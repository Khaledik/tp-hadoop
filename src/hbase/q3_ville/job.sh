#!/bin/bash

INPUT="/user/root/tp_hadoop/input/dataw_fro03.csv"
OUTPUT="/user/root/tp_hadoop/output/q3_hbase"

# Suppression de l'ancienne sortie Hadoop
hdfs dfs -rm -r -f "$OUTPUT"

# Lancement du job
hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar \
-file mapper.py -mapper "python3 mapper.py" \
-file reducer_hbase.py -reducer "python3 reducer_hbase.py" \
-input "$INPUT" \
-output "$OUTPUT"