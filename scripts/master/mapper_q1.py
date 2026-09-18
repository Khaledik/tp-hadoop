import sys
import csv

# On lit le fichier CSV ligne par ligne depuis l'entrée standard
reader = csv.reader(sys.stdin)

for row in reader:
    # On ignore les lignes trop courtes et l'en-tête du CSV
    if len(row) < 16 or row[0] == "codcli":
        continue

    # villecli est la colonne d'index 5
    ville = row[5]

    try:
        # qte est la colonne d'index 15
        # On convertit la valeur en entier pour pouvoir l'additionner ensuite
        qte = int(float(row[15]))
    except ValueError:
        # Si la quantité n'est pas valide, on ignore la ligne
        continue

    # Le mapper envoie : ville + quantité
    print(f"{ville}\t{qte}")