import sys
import csv

csv_reader = csv.reader(sys.stdin, delimiter=',')

for row in csv_reader:
    if len(row) < 9 or row[0] == 'track_name':
        continue
    artist = row[1]
    try:
        streams = int(float(row[8]))
    except ValueError:
        continue
    print("%s\t%s" % (artist, streams))