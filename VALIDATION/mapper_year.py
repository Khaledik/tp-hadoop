import sys
import csv


def main():
    reader = csv.reader(sys.stdin, delimiter=',')
    for row in reader:
        if len(row) < 9:
            continue
        try:
            year = int(row[3])
        except ValueError:
            continue
        try:
            streams = int(row[8])
        except ValueError:
            continue
        print("%s\t%s" % (year, streams))


if __name__ == "__main__":
    main()