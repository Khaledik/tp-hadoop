import sys

current_key = None
total = 0

for line in sys.stdin:
    line = line.strip()

    if not line:
        continue

    try:
        # Chaque ligne contient : ville#année + quantité
        key, qte = line.split("\t", 1)
        qte = int(qte)
    except ValueError:
        continue

    # Même clé : on additionne
    if key == current_key:
        total += qte

    else:
        # Quand la clé change, on affiche le total précédent
        if current_key is not None:
            print(f"{current_key}\t{total}")

        current_key = key
        total = qte

# Affichage de la dernière clé
if current_key is not None:
    print(f"{current_key}\t{total}")