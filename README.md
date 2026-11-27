# TP2 — Dictionnaire de mots

Projet réalisé dans le cadre du cours **INF2171** — Automne 2026.

Le programme est écrit en **assembleur RISC-V 64 bits**. Il permet de lire un fichier texte, d'en extraire les mots et de construire un dictionnaire trié de mots distincts contenant leur position, leur longueur et leur fréquence d'apparition.

## 1. Objectif du projet

À partir d'un fichier texte fourni en argument, le programme doit :

1. Lire le contenu du fichier dans un tampon mémoire.
2. Parcourir le texte et séparer les mots.
3. Reconnaître les délimiteurs et exclure les chiffres.
4. Construire un dictionnaire trié de mots distincts.
5. Enregistrer pour chaque entrée sa position, sa longueur et sa fréquence.
6. Rechercher les mots dans le dictionnaire et afficher les résultats.

Ce travail pratique permet de mettre en application les notions de programmation en assembleur, de gestion de la mémoire, d'appels système, de conventions d'appel et d'algorithmes de recherche et d'insertion.

## 2. Environnement et limites

- **Langage :** RISC-V 64 bits
- **Assembleur / simulateur :** RARS
- **Fichier principal :** `mots.s`
- **Capacité maximale du tampon :** 2048 octets
- **Nombre maximal d'entrées distinctes :** 200
- **Taille d'une entrée du dictionnaire :** 24 octets

### 2.1 Structure d'une entrée du dictionnaire

Chaque entrée du dictionnaire contient trois champs de 8 octets, soit un total de 24 octets.

| Champ | Taille |
|---|---|
| Position dans le texte | 8 octets |
| Longueur du mot en octets | 8 octets |
| Fréquence d'apparition | 8 octets |
| **Total par entrée** | **24 octets** |

L'espace mémoire réservé au dictionnaire est de 4800 octets, ce qui permet de stocker au maximum 200 entrées.

La position et la longueur sont exprimées en octets, et non en nombre de caractères visibles. Cette distinction est importante pour les caractères accentués encodés en UTF-8.

## 3. Algorithme général

### 3.1 Détection des délimiteurs — `Delimiteur`

La routine `Delimiteur` reçoit un octet et détermine s'il correspond à un délimiteur. La macro `TEST_DELIM` permet de tester différents caractères de séparation en réutilisant les mêmes instructions afin de délimiter les mots dans le texte.

### 3.2 Séparation des mots — `Separer`

La routine parcourt le texte octet par octet. Lorsqu'elle rencontre le début d'un mot, elle mémorise sa position et poursuit jusqu'au prochain délimiteur. La longueur du mot est calculée à partir des positions de début et de fin, puis la routine appelle `Insérer` pour rechercher le mot dans le dictionnaire ou l'ajouter. Les chiffres sont exclus conformément aux règles du travail pratique.

### 3.3 Gestion des caractères UTF-8 — `Map`

Les caractères ASCII occupent un octet, tandis que les caractères accentués courants en UTF-8 sont encodés sur deux octets, avec `0xC3` comme premier octet. La routine `Map` utilise la macro `MAP_DIACRITIQUE` pour associer le deuxième octet à sa lettre correspondante en ASCII (minuscule ou majuscule) lors des comparaisons.

### 3.4 Comparaison des mots — `Comparer`

La routine `Comparer` reçoit les adresses des deux mots à comparer ainsi que la longueur de comparaison, et retourne une valeur négative, nulle ou positive selon l'ordre relatif des deux mots :

1. Si les octets sont identiques, l'index avance.
2. Si l'octet courant du premier mot vaut `0xC3`, son deuxième octet est converti avec `Map` puis comparé à l'octet du deuxième mot.
3. Si l'octet courant du deuxième mot vaut `0xC3`, la conversion est appliquée de la même façon pour ce mot.
4. Sinon, le résultat est déterminé par la différence entre les deux octets comparés.
5. Si toute la longueur est parcourue sans différence, la routine retourne zéro.

La comparaison est utilisée par la recherche binaire pour maintenir l'ordre du dictionnaire.

### 3.5 Recherche binaire — `Rechercher`

La routine `Rechercher` localise un mot dans le dictionnaire à partir de l'adresse du tampon, de la position et de la longueur du mot, de l'adresse du dictionnaire et du nombre d'entrées :

1. Initialiser les bornes `i = 0` et `j = compte - 1`.
2. Tant que `i <= j`, calculer le milieu `m = (i + j) / 2`.
3. Calculer l'adresse de l'entrée à l'offset `m * 24` dans le dictionnaire.
4. Lire la position et la longueur de cette entrée, puis calculer son adresse dans le tampon.
5. Appeler `Comparer` avec la plus petite des deux longueurs.
6. Si le résultat est négatif, chercher à gauche (`j = m - 1`) ; s'il est positif, chercher à droite (`i = m + 1`).
7. Si le résultat est nul, comparer les longueurs : s'il y a égalité, le mot est trouvé.
8. Si l'intervalle devient vide, retourner `i` comme position d'insertion.

La recherche binaire permet de réduire le nombre de comparaisons nécessaires pour retrouver un mot.

### 3.6 Insertion — `Insérer`

La routine `Insérer` met à jour la fréquence d'un mot existant ou insère un nouveau mot trié :

1. Appeler `Rechercher` pour obtenir l'index du mot ou sa position d'insertion.
2. Si le mot est déjà présent, incrémenter sa fréquence sans modifier le nombre d'entrées.
3. Sinon, vérifier que le dictionnaire n'a pas atteint sa capacité maximale (200 entrées).
4. Calculer l'adresse d'insertion (`dictionnaire + index * 24`).
5. Décaler les entrées suivantes vers la droite pour libérer l'emplacement.
6. Enregistrer la position et la longueur du nouveau mot, puis initialiser sa fréquence à `1`.
7. Incrémenter le nombre d'entrées du dictionnaire.

Si le dictionnaire est plein et que le mot n'existe pas, le programme affiche un message d'erreur et termine l'exécution.

### 3.7 Affichage — `Imprimer`

La routine `Imprimer` parcourt chaque entrée du dictionnaire (pas de 24 octets) et affiche la position, la longueur en octets, la fréquence d'apparition ainsi que le mot correspondant.

## 4. Compilation et exécution

Placez `mots.s` et le fichier texte à analyser dans le répertoire de travail, puis lancez RARS en mode RV64 en passant le fichier en argument :

```bash
java -jar rars.jar rv64 mots.s pa fichier.txt
```

Exemple de fichier d'entrée :

```text
Bonjour le monde.
Bonjour, monde!
```

Le dictionnaire contient alors les mots distincts rencontrés dans le texte, avec leur position, leur longueur et leur fréquence.

## 5. Tests effectués

Le programme a été validé sur les jeux de test de référence fournis (`prefixes.txt`, `suffixes.txt`, `diacritiques.txt` selon l'erratum, et `long_texte.txt`), ainsi que sur des scénarios complémentaires :

- **Fichiers et encodage :** fichier vide, mot unique, séparateurs variés, ponctuation, exclusion des chiffres, mots répétés, tri alphabétique distinct de l'ordre d'apparition et caractères accentués UTF-8 (l'affichage des accents pouvant dépendre du support UTF-8 de la console).
- **Capacité mémoire :** fichier atteignant la limite de 2048 octets (par exemple 1024 occurrences d'un mot d'un octet) et fichier dépassant 2048 octets (message d'erreur attendu).
- **Limite du dictionnaire et erreurs d'E/S :** plus de 200 mots distincts (message d'erreur de dictionnaire plein), absence d'argument ou nombre d'arguments invalide, et fichier inexistant.

## 6. Conclusion

Ce travail pratique a permis de mettre en œuvre un dictionnaire de mots trié en assembleur RISC-V 64 bits combinant découpage de texte, gestion UTF-8, recherche binaire, insertion avec décalage et gestion des erreurs. Les tests réalisés confirment le bon comportement général du programme sur les cas nominaux et les cas limites.

## 7. Auteurs

- Judes et Thierry
