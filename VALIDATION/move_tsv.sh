set -e
echo ===MOVE_FROM_LOCAL:
hdfs dfs -mkdir -p /user/root/spotify/nifi
hdfs dfs -rm -f /user/root/spotify/nifi/Spotify_Most_Streamed_Songs.csv
hdfs dfs -moveFromLocal /home/staging/Spotify_Most_Streamed_Songs.csv /user/root/spotify/nifi/
hdfs dfs -ls -R /user/root/spotify/nifi
echo ===WC_HDFS:
hdfs dfs -cat /user/root/spotify/nifi/Spotify_Most_Streamed_Songs.csv | wc -l
echo MOVE_DONE