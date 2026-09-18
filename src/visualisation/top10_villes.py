import happybase
import matplotlib.pyplot as plt

# Connexion à HBase via Thrift
connection = happybase.Connection("hadoop-master", 9090)

table = connection.table("ventes_ville")

resultats = []

# Lecture de toutes les villes de la table HBase
for row_key, data in table.scan():
    ville = row_key.decode("utf-8")

    total = int(
        data[b"stats:total_articles"].decode("utf-8")
    )

    resultats.append((ville, total))

connection.close()

# Tri par nombre d'articles décroissant
resultats.sort(key=lambda x: x[1], reverse=True)

# On garde seulement les 10 premières villes
top10 = resultats[:10]

print("Top 10 des villes :")

for ville, total in top10:
    print(f"{ville} : {total}")

# Vérification de LE MANS
for ville, total in resultats:
    if ville == "LE MANS":
        print(f"\nLE MANS : {total}")
        break

# Création du fichier texte
with open("top10.txt", "w", encoding="utf-8") as fichier:
    fichier.write("Top 10 des villes par nombre d'articles commandés\n\n")

    for position, (ville, total) in enumerate(top10, start=1):
        fichier.write(f"{position}. {ville} : {total}\n")

# Préparation des données du graphique
villes = [ville for ville, total in top10]
totaux = [total for ville, total in top10]

# Création du graphique
plt.figure(figsize=(12, 6))

plt.bar(villes, totaux)

plt.title("Top 10 des villes par nombre d'articles commandés")
plt.xlabel("Ville")
plt.ylabel("Nombre d'articles")

plt.xticks(rotation=45, ha="right")

plt.tight_layout()

# Export au format PDF
plt.savefig("resultat.pdf")

print("\nFichiers générés :")
print("- top10.txt")
print("- resultat.pdf")