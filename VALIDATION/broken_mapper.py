import sys
import csv

csv_reader = csv.reader(sys.stdin, delimiter=',')

for row in csv_reader:
    if len(row) < 9 or row[0] == 'track_name':
        continue
    released_year = row[3]
    streams = int(row[8])
    if released_year.isdigit():
        print("%s\t%s" % (released_year, streams))