USE spotify_db;

CREATE TABLE IF NOT EXISTS spotify_part (
  track_name STRING,
  artist_name STRING,
  streams BIGINT
)
PARTITIONED BY (released_year INT)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';

SET hive.exec.dynamic.partition = true;
SET hive.exec.dynamic.partition.mode = nonstrict;

INSERT OVERWRITE TABLE spotify_part PARTITION (released_year)
SELECT track_name, artist_name, streams, released_year
FROM spotify;

SHOW PARTITIONS spotify_part;

SELECT 'NB_PARTITIONS' AS x, COUNT(*) AS c FROM (SELECT DISTINCT released_year FROM spotify_part) t;
SELECT 'NB_DEFAULT' AS x, COUNT(*) AS c FROM spotify_part WHERE released_year IS NULL;
!quit