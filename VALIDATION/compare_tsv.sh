set -e
ls -la /home/staging
echo ===SORT_UNIQ_TSV_NIFI:
cat /home/staging/Spotify_Most_Streamed_Songs.csv | sort -u | wc -l
echo ===SORT_UNIQ_CLEAN:
cat /home/spotify-clean.tsv | sort -u | wc -l
echo ===ROWS:
echo "nifi_lines=$(wc -l < /home/staging/Spotify_Most_Streamed_Songs.csv)"
echo "clean_lines=$(wc -l < /home/spotify-clean.tsv)"
head -1 /home/staging/Spotify_Most_Streamed_Songs.csv > /tmp/h_nifi
head -1 /home/spotify-clean.tsv > /tmp/h_clean
echo ===HEADERS_DIFF:
if diff /tmp/h_nifi /tmp/h_clean > /dev/null; then echo "HEADERS_OK"; else echo "HEADERS_DIFFER"; diff /tmp/h_nifi /tmp/h_clean; fi
echo ===DATA_DIFF:
tail -n +2 /home/staging/Spotify_Most_Streamed_Songs.csv > /tmp/nifi_nohead
tail -n +2 /home/spotify-clean.tsv > /tmp/clean_nohead
if diff /tmp/nifi_nohead /tmp/clean_nohead > /dev/null; then echo "DATA_IDENTICAL"; else echo "DATA_DIFFERS"; diff /tmp/nifi_nohead /tmp/clean_nohead | head -20; fi
echo DONE