import sys
import csv

# Lecture du CSV depuis l'entrée standard
reader = csv.reader(sys.stdin)

for row in reader:
    # On ignore l'en-tête et les lignes trop courtes
    if len(row) < 16 or row[0] == "codcli":
        continue

    ville = row[5]
    date_commande = row[7]

    try:
        # qte est la colonne d'index 15
        qte = int(float(row[15]))

        # La date commence par l'année, par exemple 2004-10-22
        annee = date_commande[:4]

        # On vérifie rapidement que l'année est correcte
        int(annee)

    except ValueError:
        continue

    # Clé : ville#année
    print(f"{ville}#{annee}\t{qte}")