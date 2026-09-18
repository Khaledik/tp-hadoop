import csv

input_file = "data/raw/dataw_fro03.csv"
output_file = "results/hive/ventes_hive.tsv"

with open(input_file, "r", encoding="utf-8") as source:
    reader = csv.reader(source)

    with open(output_file, "w", encoding="utf-8", newline="") as destination:
        writer = csv.writer(destination, delimiter="\t")

        for row in reader:
            # On ignore l'en-tête et les lignes trop courtes
            if len(row) < 16 or row[0] == "codcli":
                continue

            ville = row[5]
            date_commande = row[7]

            try:
                qte = int(float(row[15]))
            except ValueError:
                continue

            # Pas d'en-tête dans le TSV
            writer.writerow([ville, date_commande, qte])