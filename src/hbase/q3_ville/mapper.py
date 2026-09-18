import sys
import csv

# Lecture du CSV ligne par ligne
reader = csv.reader(sys.stdin)

for row in reader:
    # On ignore l'en-tête et les lignes trop courtes
    if len(row) < 16 or row[0] == "codcli":
        continue

    ville = row[5]

    try:
        # Quantité commandée
        qte = int(float(row[15]))
    except ValueError:
        continue

    # Envoi de la ville et de la quantité au reducer
    print(f"{ville}\t{qte}")