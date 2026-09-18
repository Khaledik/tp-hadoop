set -e
export HADOOP_HOME=/opt/hadoop
export PATH=$PATH:/opt/hadoop/bin
hdfs dfs -rm -r -f output/streams_year_2r
hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \
  -D mapreduce.job.reduces=2 \
  -file mapper_year.py -mapper "python3 mapper_year.py" \
  -file reducer_year.py -reducer "python3 reducer_year.py" \
  -input input/Spotify_Most_Streamed_Songs.csv \
  -output output/streams_year_2r
echo ===PARTS:
hdfs dfs -ls output/streams_year_2r
echo ===MERGE_SORT:
hdfs dfs -cat output/streams_year_2r/part-* | sort -n | head -8
echo "..."
echo ===2023:
hdfs dfs -cat output/streams_year_2r/part-* | grep -P '^2023\t'
echo ===DOI:
hdfs dfs -cat output/streams_year_2r/part-* | grep -P '^1975\t|^1984\t'