import sys

current_year = None
total = 0

for line in sys.stdin:
    line = line.strip()
    parts = line.split('\t', 1)
    if len(parts) < 2:
        continue
    key = parts[0]
    try:
        val = int(parts[1])
    except ValueError:
        continue
    if current_year == key:
        total += val
    else:
        if current_year is not None:
            print("%s\t%s" % (current_year, total))
        current_year = key
        total = val

if current_year is not None:
    print("%s\t%s" % (current_year, total))