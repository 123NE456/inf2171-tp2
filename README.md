# TP2 --- Dictionnaire de mots

Projet réalisé dans le cadre du cours **INF2171** --- Automne 2026.

Le programme est écrit en **assembleur RISC-V 64 bits**. Il vise à lire
un fichier texte, en extraire les mots et construire un dictionnaire de
mots distincts avec leur position, leur longueur et leur fréquence.

## Objectif

À partir d'un fichier texte fourni en argument, le programme doit :

1.  Lire le contenu du fichier dans un tampon.
2.  Parcourir le texte et séparer les mots.
3.  Exclure les chiffres et reconnaître les délimiteurs.
4.  Construire un dictionnaire trié de mots distincts.
5.  Enregistrer pour chaque entrée sa position, sa longueur et sa
    fréquence.
6.  Rechercher les mots dans le dictionnaire et afficher le résultat.

Ce TP permet de pratiquer la programmation en assembleur, la gestion
mémoire, les appels système, les conventions d'appel et les algorithmes
de recherche et d'insertion.

## Environnement

-   **Langage :** RISC-V 64 bits
-   **Assembleur / simulateur :** RARS
-   **Fichier principal :** `mots.s`
-   **Capacité prévue du tampon :** 2048 octets
-   **Nombre maximal prévu d'entrées distinctes :** 200

### Structure prévue d'une entrée du dictionnaire

Chaque entrée occupe **24 octets** :

  Champ                           Taille
  --------------------------- ----------
  Position dans le texte        8 octets
  Longueur du mot en octets     8 octets
  Fréquence                     8 octets

L'espace réservé à 200 entrées est donc de 4800 octets.

## Algorithme général

### Gestion des délimiteurs (routine `Delimiteur`)

Cette routine fait la détection d'un octet reçu pour savoir s'il s'agit d'un délimiteur.
La macro `TEST_DELIM` permet de tester les caractères sans refaire les mêmes instructions.

### Séparation  des mots (routine `Separer`)

La routine parcourt octet par octet jusqu'a trouver le début d'un mot, mémorise sa position et avance au prochaine delimiteur. On calcule la longueur du mot en soustrayant la position du début à la position du caractère avant le délimiteur. On appelle la routine `Inserer` pour l'insertion du mot et on continue le parcours du texte jusqu'a la fin.

### Gestion des caractères UTF8

Tous les caractères ASCII font un octet, mais les caracteres avec accent ont deux octect et le premier octet est `0xC3`
La routine `Map` utilise la macro `MAP_DIACRITIQUE` pour l'association du deuxième caractere à la lettre correspondant en ASCII minuscule et majuscule.

### Comparer les mots (routine `Comparer`)

La routine `comparer` recoit les adresses des deux mots a comparer et la longueur de comparaison. On retourne une valeur négatif si le premier mot et avant le second, zero si les valeur sont pareil et positif si le premier mot et apres le second

1.  Si les octets sont identiques, l'index avance.
2.  Si le premier octet différent du premier mot est égal à `0xC3`, son deuxième octet est converti avec `Map`. La routine retourne la différence avec l'octet du deuxième mot, ou `1` si les valeurs correspondent.
3.  Si c'est l'octet du deuxième mot est égal à `0xC3`, la routine retourne la différence avec l'octet du premier mot. La routine retourne la différence, ou `-1` si les valeurs correspondent.
4.  Sinon, la routine retourne la différence entre les deux octets.
5.  Si toute la longueur est parcourue sans différence, elle retourne zéro.

### Fouille binaire (routine `Rechercher`)

La recherche permet de trouver un mot sans avoir a faire tous les entrées du dictionnaires
On recoit l'adresse du tampon, la position et la longueur du mot, l'adresse du dictionnaire et la valeur du décompte.

1.  Initialiser `i = 0` et `j = compte - 1`.
2.  Tant que `i <= j`, calculer le milieu `m = (i + j) / 2`.
3.  Calculer l'adresse de l'entrée : `dictionnaire + m * 24`.
4.  Lire la position et la longueur du mot de cette entrée, puis calculer son adresse dans le tampon.
5.  Appeler la routine `Comparer` avec la plus petite des deux longueurs.
6.  Si le résultat est négatif, on poursuit à gauche (`j = m - 1`). S'il est positif, poursuivre à droite (`i = m + 1`).
7.  Si le résultat est nul, on compare les longueurs  si elles sont égales alors le mot est trouvé.
8.  Si l'intervalle devient vide, on retourne `i` comme position d'insertion.

 ### Insertion (routine `Insérer`)

La routine reçoit les informations du mot, l'adresse du tampon, l'adresse du dictionnaire et l'adresse du décompte.

1. Appeler la routine `Rechercher` pour obtenir l'index du mot ou sa position d'insertion.
2. Si le mot existe déjà, augmenter sa fréquence sans modifier le décompte.
3. Si le mot n'existe pas, vérifier que le dictionnaire n'est pas plein.
4. Calculer l'adresse d'insertion en multipliant l'index par 24 et en ajoutant l'adresse du dictionnaire.
5. Décaler les triplets vers la droite en partant de la dernière entrée jusqu'à la position d'insertion pour éviter d'écraser les données.
6. Enregistrer la position et la longueur du nouveau mot et initialiser sa fréquence à zéro.
7. Augmenter le décompte et la fréquence du nouveau mot de 1.

Si le dictionnaire est plein et que le mot n'existe pas, le programme affiche un message d'erreur et termine son exécution.

### Affichage (routine `Imprimer`)

La routine parcourt les tiplets et pour chaque triplet, on affiche ca position, ca longueur et sa fréquence. Ensuite, on affiche le mot à l'adresse. Le pointeur du dictionnaire avance de 24 octets pour chaque triplet

## Compilation et exécution

Placez `mots.s` et le fichier texte à analyser dans votre dossier de
travail.

Avec le fichier JAR de RARS, assemblez en mode RV64 :

``` bash
java -jar rars.jar rv64 mots.s
```

Le programme est prévu pour recevoir le nom du fichier texte comme
argument. La méthode exacte de passage des arguments dépend du mode de
lancement et de la configuration de RARS utilisée.

Exemple de fichier d'entrée :

``` text
Bonjour le monde.
Bonjour, monde!
```

## Plan de tests pour la reprise

Tester progressivement :

-   Fichier vide.
-   Un seul mot.
-   Plusieurs mots séparés par espaces, tabulations et fins de ligne.
-   Ponctuation et apostrophes.
-   Chiffres au début, au milieu et à la fin d'une séquence.
-   Mots répétés : la fréquence doit être mise à jour sans créer de
    doublon.
-   Mots dont l'ordre de tri diffère de l'ordre d'apparition.
-   Mots avec lettres accentuées et majuscules.
-   Fichier de 2048 octets et fichier dépassant cette limite.
-   Dictionnaire contenant 200 mots distincts, puis tentative d'ajout
    d'un nouveau mot.

## Auteurs

-   Judes --- travail initial
-   Thierry --- poursuite et intégration du projet

------------------------------------------------------------------------
