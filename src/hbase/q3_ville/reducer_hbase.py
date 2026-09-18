import sys
import happybase

# Connexion au serveur Thrift HBase du master
connection = happybase.Connection("hadoop-master", 9090)

# Table dans laquelle les résultats seront enregistrés
table = connection.table("ventes_ville")

current_ville = None
total = 0


def save_ville(ville, total_articles):
    # La ville devient la rowkey
    table.put(
        ville.encode("utf-8"),
        {
            b"stats:total_articles": str(total_articles).encode("utf-8")
        }
    )

    # On garde également une sortie MapReduce classique
    print(f"{ville}\t{total_articles}")


for line in sys.stdin:
    line = line.strip()

    if not line:
        continue

    try:
        ville, qte = line.split("\t", 1)
        qte = int(qte)
    except ValueError:
        continue

    # Même ville : on continue à additionner
    if ville == current_ville:
        total += qte

    else:
        # Quand la ville change, on sauvegarde la précédente
        if current_ville is not None:
            save_ville(current_ville, total)

        current_ville = ville
        total = qte


# Enregistrement de la dernière ville
if current_ville is not None:
    save_ville(current_ville, total)


connection.close()