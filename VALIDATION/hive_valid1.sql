CREATE DATABASE IF NOT EXISTS spotify_db;
USE spotify_db;

CREATE EXTERNAL TABLE IF NOT EXISTS spotify (
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
  in_deezer_playlists STRING,
  in_deezer_charts INT,
  in_shazam_charts STRING,
  bpm INT,
  `key` STRING,
  mode STRING,
  danceability_pct DOUBLE,
  valence_pct DOUBLE,
  energy_pct DOUBLE,
  acousticness_pct DOUBLE,
  instrumentalness_pct DOUBLE,
  liveness_pct DOUBLE,
  speechiness_pct DOUBLE,
  cover_url STRING
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
LOCATION '/user/root/spotify/clean';

SELECT 'COUNT_STAR' AS mesure, COUNT(*) AS valeur FROM spotify;
SELECT 'COUNT_STREAMS' AS mesure, COUNT(streams) AS valeur FROM spotify;
SELECT 'SUM_TOTAL' AS mesure, SUM(streams) AS valeur FROM spotify;
SELECT released_year, SUM(streams) AS total
FROM spotify
WHERE released_year IN (1975, 1984, 2023)
GROUP BY released_year ORDER BY released_year;
SELECT artist_name, SUM(streams) AS total
FROM spotify
GROUP BY artist_name
ORDER BY total DESC
LIMIT 6;
!quit