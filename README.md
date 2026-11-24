# TP2 --- Dictionnaire de mots

Projet réalisé dans le cadre du cours **INF2171** --- Automne 2026.

Le programme est écrit en **assembleur RISC-V 64 bits**. Il vise à lire
un fichier texte, en extraire les mots et construire un dictionnaire de
mots distincts avec leur position, leur longueur et leur fréquence.

> **État du dépôt : point de reprise en cours de développement.**\
> Le code contient plusieurs routines déjà présentes, mais l'intégration
> complète du dictionnaire n'est pas terminée. Consultez la section
> [État du projet](#état-du-projet).

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

## Organisation du code

Le fichier `mots.s` est organisé en sections commentées :

  -----------------------------------------------------------------------
  Section                             Contenu
  ----------------------------------- -----------------------------------
  Constantes                          Limites du tampon et du
                                      dictionnaire, codes des appels
                                      système

  Segment `.data`                     Tampon de lecture, espace du
                                      dictionnaire, compteur et messages

  `main`                              Vérification des arguments,
                                      ouverture, lecture et fermeture du
                                      fichier

  Gestion des erreurs                 Messages pour les arguments,
                                      l'ouverture, la lecture et la
                                      taille du fichier

  `Delimiteur`                        Détection des espaces, caractères
                                      de contrôle et ponctuation

  `Séparer`                           Parcours du tampon, repérage des
                                      mots et appel à `Insérer`

  `Map`                               Mappage de certains caractères
                                      accentués UTF-8 et conversion ASCII
                                      majuscule/minuscule

  `Comparer`                          Comparaison de mots selon les
                                      règles implémentées dans la routine
  -----------------------------------------------------------------------

### Structure prévue d'une entrée du dictionnaire

Chaque entrée occupe **24 octets** :

  Champ                           Taille
  --------------------------- ----------
  Position dans le texte        8 octets
  Longueur du mot en octets     8 octets
  Fréquence                     8 octets

L'espace réservé à 200 entrées est donc de 4800 octets.

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

## État du projet

### Implémenté ou présent dans le fichier

-   Lecture du fichier dans un tampon et ajout du caractère nul de fin.
-   Vérification de la taille maximale prévue du fichier.
-   Gestion de plusieurs erreurs d'ouverture et de lecture.
-   Routine `Delimiteur`.
-   Routine `Séparer` pour repérer les mots et exclure les chiffres
    ASCII.
-   Routine `Map` pour certains caractères UTF-8 accentués et les
    majuscules ASCII.
-   Routine `Comparer` avec comparaison des caractères mappés et
    départage selon les octets bruts.

### À poursuivre

-   Remplacer le bouchon temporaire de `Insérer` par l'insertion réelle
    dans le dictionnaire.
-   Intégrer `Rechercher` conformément au prototype de l'énoncé.
-   Maintenir l'ordre trié et mettre à jour la fréquence des mots
    répétés.
-   Finaliser l'affichage du dictionnaire.
-   Vérifier les signatures des routines et les conventions d'appel dans
    tout le programme.
-   Exécuter les tests d'intégration et les cas limites, notamment la
    capacité maximale.

**Important :** une routine présente dans le fichier n'est pas
nécessairement intégrée ou validée dans le programme complet. Vérifiez
ses paramètres et ses registres avant de poursuivre.

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

## Collaboration

Ce dépôt sert de **point de reprise** pour continuer le TP en
collaboration.

Avant de modifier le code :

1.  Lire les commentaires et les prototypes des routines.
2.  Vérifier l'énoncé officiel du TP.
3.  Identifier les routines déjà testées et celles qui restent à
    intégrer.
4.  Effectuer les modifications dans une branche dédiée.
5.  Tester chaque routine, puis le programme complet avant de fusionner.

## Auteurs

-   Judes --- travail initial
-   Collaborateur --- poursuite et intégration du projet

------------------------------------------------------------------------

*Ce README décrit l'état actuel du point de reprise. Il doit être
actualisé au fur et à mesure de l'avancement.*
