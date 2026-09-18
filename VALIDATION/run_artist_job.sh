#!/bin/bash
cd /home
hdfs dfs -rm -r -f output/artists > /dev/null 2>&1
hadoop jar "$HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar" \
  -D mapreduce.job.name=val-artists \
  -file mapper.py -mapper "python3 mapper.py" \
  -file reducer.py -reducer "python3 reducer.py" \
  -input input/Spotify_Most_Streamed_Songs.csv \
  -output output/artists