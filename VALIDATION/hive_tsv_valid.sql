DROP TABLE IF EXISTS spotify_tsv_nifi;
CREATE EXTERNAL TABLE spotify_tsv_nifi (
  track_name STRING,
  artist_name STRING,
  artist_count INT,
  released_year INT,
  released_month INT,
  released_day INT,
  in_spotify_playlists INT,
  in_spotify_charts INT,
  streams BIGINT,
  in_apple_playlists INT,
  in_apple_charts INT,
  in_deezer_playlists INT,
  in_deezer_charts INT,
  in_shazam_charts INT,
  bpm INT,
  key STRING,
  mode STRING,
  danceability INT,
  valence INT,
  energy INT,
  acousticness INT,
  instrumentalness INT,
  liveness INT,
  speechiness INT,
  cover_url STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE
LOCATION '/user/root/spotify/nifi';

SELECT 'TSV_NIFI_COUNT_STAR' AS mesure, COUNT(*) AS valeur FROM spotify_tsv_nifi;
SELECT 'TSV_NIFI_COUNT_STREAMS' AS mesure, COUNT(streams) AS valeur FROM spotify_tsv_nifi;
SELECT 'TSV_NIFI_SUM' AS mesure, SUM(streams) AS valeur FROM spotify_tsv_nifi;
!quit