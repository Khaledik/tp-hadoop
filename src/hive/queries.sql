USE tp_hadoop;

-- Vérification du moteur Hive
SET hive.execution.engine;

-- Q1 : classement des villes
SELECT
    ville,
    SUM(qte) AS total_articles
FROM ventes
GROUP BY ville
ORDER BY total_articles DESC
LIMIT 10;

-- Q2 : classement ville#année
SELECT
    CONCAT(ville, '#', SUBSTR(date_commande, 1, 4)) AS ville_annee,
    SUM(qte) AS total_articles
FROM ventes
GROUP BY
    ville,
    SUBSTR(date_commande, 1, 4)
ORDER BY total_articles DESC
LIMIT 10;

-- Plan d'exécution Q1
EXPLAIN
SELECT
    ville,
    SUM(qte) AS total_articles
FROM ventes
GROUP BY ville
ORDER BY total_articles DESC
LIMIT 10;

-- Plan d'exécution Q2
EXPLAIN
SELECT
    CONCAT(ville, '#', SUBSTR(date_commande, 1, 4)) AS ville_annee,
    SUM(qte) AS total_articles
FROM ventes
GROUP BY
    ville,
    SUBSTR(date_commande, 1, 4)
ORDER BY total_articles DESC
LIMIT 10;