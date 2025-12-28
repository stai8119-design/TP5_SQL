WITH 
stats_mensuelles AS (
    SELECT 
        YEAR(date_debut) as annee,
        MONTH(date_debut) as mois,
        COUNT(*) as total_emprunts,
        COUNT(DISTINCT abonne_id) as abonnes_actifs,
        COUNT(DISTINCT ouvrage_id) as ouvrages_empruntes_distincts
    FROM EMPRUNT
    WHERE YEAR(date_debut) = 2025
    GROUP BY YEAR(date_debut), MONTH(date_debut)
),
total_collection AS (
    SELECT COUNT(*) as nb_total_ouvrages FROM OUVRAGE
),
classement_ouvrages AS (
    SELECT 
        YEAR(e.date_debut) as annee,
        MONTH(e.date_debut) as mois,
        o.titre,
        COUNT(*) as nb_emprunts_par_titre,
        ROW_NUMBER() OVER (
            PARTITION BY YEAR(e.date_debut), MONTH(e.date_debut) 
            ORDER BY COUNT(*) DESC
        ) as rang
    FROM EMPRUNT e
    JOIN OUVRAGE o ON e.ouvrage_id = o.id
    WHERE YEAR(e.date_debut) = 2025
    GROUP BY YEAR(e.date_debut), MONTH(e.date_debut), o.id, o.titre
),
top_3_titres AS (
    SELECT 
        annee, 
        mois, 
        GROUP_CONCAT(CONCAT(titre, ' (', nb_emprunts_par_titre, ')') SEPARATOR ', ') as top_ouvrages
    FROM classement_ouvrages
    WHERE rang <= 3
    GROUP BY annee, mois
)
SELECT 
    sm.annee,
    sm.mois,
    sm.total_emprunts,
    sm.abonnes_actifs,
    ROUND(sm.total_emprunts / sm.abonnes_actifs, 2) as moyenne_par_abonne,
    ROUND(sm.ouvrages_empruntes_distincts * 100.0 / tc.nb_total_ouvrages, 2) as pct_empruntes,
    COALESCE(t3.top_ouvrages, 'Aucun emprunt') as les_3_ouvrages_stars
FROM stats_mensuelles sm
CROSS JOIN total_collection tc
LEFT JOIN top_3_titres t3 ON sm.annee = t3.annee AND sm.mois = t3.mois
ORDER BY sm.annee, sm.mois;