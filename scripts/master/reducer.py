import sys

current_key = None
current_sum = 0

for line in sys.stdin:
    line = line.strip()
    parts = line.split('\t', 1)
    if len(parts) < 2:
        continue
    key = parts[0]
    try:
        value = int(parts[1])
    except ValueError:
        continue
    if current_key == key:
        current_sum += value
    else:
        if current_key:
            print("%s\t%s" % (current_key, current_sum))
        current_key = key
        current_sum = value

if current_key:
    print("%s\t%s" % (current_key, current_sum))