import sys

# On garde en mémoire la ville en cours
current_ville = None

# Total des quantités pour cette ville
total = 0

for line in sys.stdin:
    line = line.strip()

    # On ignore les lignes vides
    if not line:
        continue

    try:
        # Chaque ligne reçue contient : ville + quantité
        ville, qte = line.split("\t", 1)
        qte = int(qte)
    except ValueError:
        continue

    # Si on est toujours sur la même ville, on ajoute la quantité
    if ville == current_ville:
        total += qte

    else:
        # Quand la ville change, on affiche le total de la ville précédente
        if current_ville is not None:
            print(f"{current_ville}\t{total}")

        # On commence ensuite le calcul pour la nouvelle ville
        current_ville = ville
        total = qte

# Il faut aussi afficher la dernière ville après la boucle
if current_ville is not None:
    print(f"{current_ville}\t{total}")