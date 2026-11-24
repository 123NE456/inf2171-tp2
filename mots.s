# ============================================================
# TP2 - Dictionnaire de mots
# INF2171 - Automne 2026
# RISC-V 64 bits
# Auteur : JUDES
# ============================================================
# ETAT DU TRAVAIL - VERSION DE PASSATION
# ------------------------------------------------------------
# Modules présents :
#   - lecture du fichier et contrôle de taille (2048 octets)
#   - Delimiteur
#   - Séparer
#   - Map
#   - Comparer
#
# A TERMINER AVANT DE CONSIDERER LE TP COMME FINAL :
#   1. Remplacer le bouchon de test Insérer par la vraie insertion
#      ordonnée (avec détection de capacité et fréquence des doublons).
#   2. Intégrer Rechercher (recherche binaire) avec le prototype
#      officiel de l'énoncé.
#   3. Ajouter l'affichage final du dictionnaire trié.
#   4. Tester l'ensemble avec les fichiers fournis et des cas limites.
#
# IMPORTANT : la routine Insérer ci-dessous affiche encore les mots
# découpés. Elle ne construit PAS encore le dictionnaire.
# Cette version est un point de reprise pour le binôme, pas une
# version finale prête à remettre.
# ============================================================


# ============================================================
# SECTION 1 - CONSTANTES
# ============================================================

.eqv MAXCHAR 2048
.eqv MAXMOTS 200

.eqv open    1024
.eqv read    63
.eqv close   57
.eqv prstr   4
.eqv print_int 1
.eqv print_char 11
.eqv exit    10


# ============================================================
# SECTION 2 - SEGMENT DATA
# ============================================================

.data
.align 3

# ------------------------------------------------------------
# 2.1 Tampon de lecture
# ------------------------------------------------------------

# Contient le texte lu depuis le fichier.
# 2049 octets pour pouvoir ajouter le '\0'.

input:
    .space 2049


# ------------------------------------------------------------
# 2.2 Dictionnaire
# ------------------------------------------------------------

# Chaque entrée contient :
#   position  : 8 octets
#   longueur  : 8 octets
#   fréquence : 8 octets
#
# Une entrée = 24 octets
# 200 entrées = 4800 octets

dictionnaire:
    .space 4800

# Nombre de mots distincts
compte:
    .dword 0


# ------------------------------------------------------------
# 2.3 Messages d'erreur et de test
# ------------------------------------------------------------

str_err_args:
    .string "Erreur : nombre d'arguments invalide\n"

str_err_ouverture:
    .string "Erreur : impossible d'ouvrir le fichier\n"

str_err_flong:
    .string "Erreur : fichier trop gros pour le tampon\n"

str_err_lecture:
    .string "Erreur : impossible de lire le fichier\n"

str_sep_pos:
    .string "pos="

str_sep_len:
    .string " len="

str_sep_mot:
    .string " mot="


# ============================================================
# SECTION 3 - SEGMENT TEXT
# ============================================================

.text
.globl main


# ============================================================
# SECTION 4 - MAIN
# ============================================================

main:

    # --------------------------------------------------------
    # 4.1 Vérifier le nombre d'arguments
    # --------------------------------------------------------

    # Un seul argument est attendu : le nom du fichier.

    beqz a0, err_args

    addi t1, a0, -1
    bnez t1, err_args


    # --------------------------------------------------------
    # 4.2 Ouvrir le fichier
    # --------------------------------------------------------

    # a1 contient l'adresse du tableau argv.
    # argv[0] contient le nom du fichier.

    ld a0, 0(a1)

    # Mode lecture
    li a1, 0

    # Appel système open
    li a7, open
    ecall

    # Vérifier si open a retourné -1.

    li t1, -1
    beq a0, t1, err_ouverture

    # Sauvegarder le descripteur du fichier.

    mv t0, a0


    # --------------------------------------------------------
    # 4.3 Lire le fichier dans input
    # --------------------------------------------------------

    la a1, input

    # Lire jusqu'à MAXCHAR + 1 octets pour détecter un fichier > 2048 octets
    # tout en conservant de la place pour '\0' dans le tampon de 2049 octets.
    li a2, MAXCHAR
    addi a2, a2, 1

    # Appel système read
    mv a0, t0
    li a7, read
    ecall

    # a0 contient le nombre d'octets lus.

    # Vérifier une erreur de lecture.

    bltz a0, err_lecture

    # Sauvegarder la taille lue.

    mv t2, a0


    # --------------------------------------------------------
    # 4.4 Fermer le fichier
    # --------------------------------------------------------

    mv a0, t0
    li a7, close
    ecall


    # --------------------------------------------------------
    # 4.5 Vérifier la taille du fichier
    # --------------------------------------------------------

    # Refuser uniquement si le nombre d'octets lus dépasse strictement MAXCHAR (2048).

    li t1, MAXCHAR
    bgtu t2, t1, err_flong


    # --------------------------------------------------------
    # 4.6 Ajouter le caractère nul
    # --------------------------------------------------------

    # input + taille_lue = emplacement du '\0'

    la t1, input
    add t1, t1, t2

    sb zero, 0(t1)


    # --------------------------------------------------------
    # 4.7 Appel de Séparer (Insérer est encore un bouchon de test)
    # --------------------------------------------------------

    la   a0, input
    la   a1, dictionnaire
    la   a2, compte
    jal  ra, Séparer


    # --------------------------------------------------------
    # 4.8 Fin normale
    # --------------------------------------------------------

    j fin


# ============================================================
# SECTION 5 - GESTION DES ERREURS
# ============================================================

# ------------------------------------------------------------
# 5.1 Nombre d'arguments invalide
# ------------------------------------------------------------

err_args:
    la a0, str_err_args
    j ecrire_erreur


# ------------------------------------------------------------
# 5.2 Erreur d'ouverture
# ------------------------------------------------------------

err_ouverture:
    la a0, str_err_ouverture
    j ecrire_erreur


# ------------------------------------------------------------
# 5.3 Fichier trop gros
# ------------------------------------------------------------

err_flong:
    la a0, str_err_flong
    j ecrire_erreur


# ------------------------------------------------------------
# 5.4 Erreur de lecture
# ------------------------------------------------------------

err_lecture:
    # Fermer le fichier avant de quitter.

    mv a0, t0
    li a7, close
    ecall

    la a0, str_err_lecture
    j ecrire_erreur


# ------------------------------------------------------------
# 5.5 Afficher le message d'erreur
# ------------------------------------------------------------

ecrire_erreur:
    li a7, prstr
    ecall

    j fin


# ============================================================
# SECTION 6 - FIN DU PROGRAMME
# ============================================================

fin:
    li a7, exit
    ecall


# ============================================================
# SECTION 7 - ROUTINES DU TP
# ============================================================

# ------------------------------------------------------------
# 7.1 MACRO : TESTER UN DELIMITEUR EXACT
# ------------------------------------------------------------
# Si a0 correspond au caractère %c :
#   - retourne 0 immédiatement.
# Sinon :
#   - continue l'exécution.
#
# Registre temporaire utilisé : t0
# ------------------------------------------------------------

.macro TEST_DELIM (%c)
    li   t0, %c
    bne  a0, t0, fin_test_delim
    li   a0, 0
    ret
fin_test_delim:
.end_macro


# ------------------------------------------------------------
# 7.2 ROUTINE : Delimiteur
# ------------------------------------------------------------
# Entrée :
#   a0 = caractère ASCII (valeur non signée)
#
# Sortie :
#   a0 = 0 si délimiteur
#   a0 = caractère original sinon
#
# Les chiffres ne sont PAS traités ici.
# Ils seront exclus dans Séparer.
#
# Routine feuille : aucun appel à une autre routine.
# ------------------------------------------------------------

Delimiteur:

    # Fin du texte
    TEST_DELIM 0x00

    # Espaces et caractères de contrôle usuels
    TEST_DELIM 0x09       # Tabulation
    TEST_DELIM 0x0A       # Saut de ligne
    TEST_DELIM 0x0B       # Tabulation verticale
    TEST_DELIM 0x0C       # Saut de page
    TEST_DELIM 0x0D       # Retour chariot
    TEST_DELIM 0x20       # Espace

    # Ponctuation ASCII :
    # ! à /
    li   t0, 0x21
    bltu a0, t0, delim_fin
    li   t0, 0x2F
    bleu a0, t0, delim_zero

    # : à @
    li   t0, 0x3A
    bltu a0, t0, delim_fin
    li   t0, 0x40
    bleu a0, t0, delim_zero

    # [ à `
    li   t0, 0x5B
    bltu a0, t0, delim_fin
    li   t0, 0x60
    bleu a0, t0, delim_zero

    # { à ~
    li   t0, 0x7B
    bltu a0, t0, delim_fin
    li   t0, 0x7E
    bleu a0, t0, delim_zero

delim_fin:
    ret

delim_zero:
    li   a0, 0
    ret


# ------------------------------------------------------------
# 7.3 ROUTINE : Séparer
# ------------------------------------------------------------
# Entrées (ABI RV64) :
#   a0 = adresse du tampon de texte (&ligne / &input)
#   a1 = adresse du dictionnaire (&dictionnaire)
#   a2 = adresse du compteur de mots (&compte)
#
# Routine non-feuille : sauvegarde ra et les registres s0-s4
# sur la pile (48 octets alignés sur 16 octets).
# ------------------------------------------------------------

Séparer:
    addi sp, sp, -48
    sd   ra, 40(sp)
    sd   s0, 32(sp)       # s0 = adresse de base de la ligne (&ligne)
    sd   s1, 24(sp)       # s1 = adresse du dictionnaire (&dictionnaire)
    sd   s2, 16(sp)       # s2 = adresse du décompte (&compte)
    sd   s3, 8(sp)        # s3 = index courant (octet) dans la ligne
    sd   s4, 0(sp)        # s4 = position de début du mot courant

    mv   s0, a0
    mv   s1, a1
    mv   s2, a2
    li   s3, 0            # index initial = 0

separer_boucle_principale:
    # --------------------------------------------------------
    # 1. Sauter les délimiteurs et chiffres
    # --------------------------------------------------------
separer_sauter_delim:
    add  t0, s0, s3
    lbu  t1, 0(t0)        # lire l'octet courant (non signé)
    beqz t1, separer_fin  # fin de chaîne '\0' -> terminer

    # Tester si t1 est un délimiteur via Delimiteur(a0)
    mv   a0, t1
    jal  ra, Delimiteur
    beqz a0, separer_avance_saut   # a0 == 0 => délimiteur, on saute

    # Exclure les chiffres ASCII ('0' = 0x30 à '9' = 0x39)
    li   t0, 0x30
    bltu a0, t0, separer_debut_mot

    li   t0, 0x39
    bgtu a0, t0, separer_debut_mot

    # Si on arrive ici, c'est un chiffre
    j    separer_avance_saut

separer_avance_saut:
    addi s3, s3, 1
    j    separer_sauter_delim

    # --------------------------------------------------------
    # 2. Marquer le début du mot et avancer jusqu'à la fin
    # --------------------------------------------------------
separer_debut_mot:
    mv   s4, s3           # position de début du mot = s3

separer_parcourir_mot:
    addi s3, s3, 1        # passer au caractère suivant
    add  t0, s0, s3
    lbu  t1, 0(t0)
    beqz t1, separer_fin_mot       # fin de texte '\0' termine le mot

    # Vérifier si t1 est un délimiteur
    mv   a0, t1
    jal  ra, Delimiteur
    beqz a0, separer_fin_mot       # délimiteur trouvé -> fin du mot

    # Vérifier si t1 est un chiffre ASCII ('0'..'9')
    li   t0, 0x30
    bltu a0, t0, separer_parcourir_mot
    li   t0, 0x39
    bleu a0, t0, separer_fin_mot   # chiffre trouvé -> fin du mot

    j    separer_parcourir_mot

    # --------------------------------------------------------
    # 3. Calculer la longueur et appeler Insérer
    # --------------------------------------------------------
separer_fin_mot:
    sub  a2, s3, s4       # a2 = longueur en octets (fin - début)
    mv   a0, s0           # a0 = &ligne
    mv   a1, s4           # a1 = début
    mv   a3, s1           # a3 = &dictionnaire
    mv   a4, s2           # a4 = &compte
    jal  ra, Insérer

    # Continuer le parcours à partir de l'index courant s3
    j    separer_boucle_principale

separer_fin:
    ld   ra, 40(sp)
    ld   s0, 32(sp)
    ld   s1, 24(sp)
    ld   s2, 16(sp)
    ld   s3, 8(sp)
    ld   s4, 0(sp)
    addi sp, sp, 48
    ret


# ------------------------------------------------------------
# 7.4 BOUCHON TEMPORAIRE : Insérer (à remplacer par la vraie insertion)
# ------------------------------------------------------------
# Affiche simplement pos, len et le mot extrait pour valider
# le découpage de Séparer avant d'implémenter le vrai dictionnaire.
# Entrées :
#   a0 = &ligne
#   a1 = début
#   a2 = longueur
#   a3 = &dictionnaire
#   a4 = &compte
# ------------------------------------------------------------

Insérer:
    mv   t0, a0           # t0 = &ligne
    mv   t1, a1           # t1 = début
    mv   t2, a2           # t2 = longueur

    la   a0, str_sep_pos
    li   a7, prstr
    ecall

    mv   a0, t1
    li   a7, print_int
    ecall

    la   a0, str_sep_len
    li   a7, prstr
    ecall

    mv   a0, t2
    li   a7, print_int
    ecall

    la   a0, str_sep_mot
    li   a7, prstr
    ecall

    li   t3, 0            # compteur d'octets affichés
inserer_stub_boucle:
    bge  t3, t2, inserer_stub_fin
    add  t4, t0, t1
    add  t4, t4, t3
    lbu  a0, 0(t4)
    li   a7, print_char
    ecall
    addi t3, t3, 1
    j    inserer_stub_boucle

inserer_stub_fin:
    li   a0, 10           # '\n'
    li   a7, print_char
    ecall
    ret


# ------------------------------------------------------------
# 7.5 MACRO : MAPPAGE D'UN OCTET DIACRITIQUE UTF-8
# ------------------------------------------------------------
# Si a0 == %oct_utf8, remplace a0 par %base et retourne.
# Sinon, laisse a0 inchangé et passe à la suite.
# ------------------------------------------------------------

.macro MAP_DIACRITIQUE (%oct_utf8, %base)
    li   t0, %oct_utf8
    bne  a0, t0, fin_map_macro
    li   a0, %base
    ret
fin_map_macro:
.end_macro


# ------------------------------------------------------------
# 7.6 ROUTINE : Map
# ------------------------------------------------------------
# Entrée :
#   a0 = octet non signé (typiquement le 2e octet d'une séquence
#        UTF-8 commençant par 0xC3, ou un caractère ASCII)
#
# Sortie :
#   a0 = caractère de base correspondant (minuscule), ou a0
#        inchangé s'il n'est pas dans la table de mappage.
#
# Routine feuille : utilise uniquement t0.
# ------------------------------------------------------------

Map:
    # Minuscules accentuées courantes (après 0xC3)
    MAP_DIACRITIQUE 0xA0, 'a'   # à
    MAP_DIACRITIQUE 0xA2, 'a'   # â
    MAP_DIACRITIQUE 0xA4, 'a'   # ä
    MAP_DIACRITIQUE 0xA7, 'c'   # ç
    MAP_DIACRITIQUE 0xA8, 'e'   # è
    MAP_DIACRITIQUE 0xA9, 'e'   # é
    MAP_DIACRITIQUE 0xAA, 'e'   # ê
    MAP_DIACRITIQUE 0xAB, 'e'   # ë
    MAP_DIACRITIQUE 0xAE, 'i'   # î
    MAP_DIACRITIQUE 0xAF, 'i'   # ï
    MAP_DIACRITIQUE 0xB4, 'o'   # ô
    MAP_DIACRITIQUE 0xB6, 'o'   # ö
    MAP_DIACRITIQUE 0xB9, 'u'   # ù
    MAP_DIACRITIQUE 0xBB, 'u'   # û
    MAP_DIACRITIQUE 0xBC, 'u'   # ü

    # Majuscules accentuées courantes (après 0xC3)
    MAP_DIACRITIQUE 0x80, 'a'   # À
    MAP_DIACRITIQUE 0x82, 'a'   # Â
    MAP_DIACRITIQUE 0x84, 'a'   # Ä
    MAP_DIACRITIQUE 0x87, 'c'   # Ç
    MAP_DIACRITIQUE 0x88, 'e'   # È
    MAP_DIACRITIQUE 0x89, 'e'   # É
    MAP_DIACRITIQUE 0x8A, 'e'   # Ê
    MAP_DIACRITIQUE 0x8B, 'e'   # Ë
    MAP_DIACRITIQUE 0x8E, 'i'   # Î
    MAP_DIACRITIQUE 0x8F, 'i'   # Ï
    MAP_DIACRITIQUE 0x94, 'o'   # Ô
    MAP_DIACRITIQUE 0x96, 'o'   # Ö
    MAP_DIACRITIQUE 0x99, 'u'   # Ù
    MAP_DIACRITIQUE 0x9B, 'u'   # Û
    MAP_DIACRITIQUE 0x9C, 'u'   # Ü

    # Majuscules ASCII 'A'..'Z' -> minuscules 'a'..'z'
    li   t0, 0x41
    bltu a0, t0, map_fin
    li   t0, 0x5A
    bgtu a0, t0, map_fin
    addi a0, a0, 32

map_fin:
    ret
    
    
 # ------------------------------------------------------------
# 7.7 ROUTINE : Comparer
# ------------------------------------------------------------
# Entrées (ABI RV64) :
#   a0 = adresse du premier mot (&a)
#   a1 = longueur du premier mot (en octets)
#   a2 = adresse du second mot (&b)
#   a3 = longueur du second mot (en octets)
#
# Sortie :
#   a0 < 0 si premier mot < second mot
#   a0 = 0 si les deux mots sont identiques
#   a0 > 0 si premier mot > second mot
#
# Règles :
#   1. Lecture par caractère en respectant les frontières UTF-8
#      (0xC3 + 2e octet si i + 1 < len ; sinon octet isolé).
#   2. Comparaison des valeurs mappées via Map.
#   3. Si valeurs mappées égales, départage par octets bruts
#      (1er octet brut, puis 2e octet brut si deux accents).
#   4. Si tous les caractères communs sont égaux, départage
#      par longueur en octets (len_a - len_b).
#
# Routine non-feuille : appelle Map, cadre de 96 octets aligné
# sur 16 octets.
# ------------------------------------------------------------

Comparer:
    addi sp, sp, -96
    sd   ra, 88(sp)
    sd   s0, 80(sp)       # s0 = &a
    sd   s1, 72(sp)       # s1 = len_a
    sd   s2, 64(sp)       # s2 = &b
    sd   s3, 56(sp)       # s3 = len_b
    sd   s4, 48(sp)       # s4 = index courant dans a (i)
    sd   s5, 40(sp)       # s5 = index courant dans b (j)
    sd   s6, 32(sp)       # s6 = valeur mappée courante de a
    sd   s7, 24(sp)       # s7 = 1er octet brut de a
    sd   s8, 16(sp)       # s8 = 2e octet brut de a (si 2 octets, sinon 0)
    sd   s9, 8(sp)        # s9 = pas d'avancement de a (1 ou 2)

    mv   s0, a0
    mv   s1, a1
    mv   s2, a2
    mv   s3, a3
    li   s4, 0
    li   s5, 0

comp_boucle:
    bgeu s4, s1, comp_fin_commun
    bgeu s5, s3, comp_fin_commun

    # --- Lire le caractère courant de a (à s4, borne s1) ---
    add  t0, s0, s4
    lbu  s7, 0(t0)        # 1er octet brut de a
    li   s8, 0            # 2e octet brut de a par défaut = 0
    li   s9, 1            # pas par défaut = 1 octet

    li   t0, 0xC3
    bne  s7, t0, comp_a_ascii
    addi t1, s4, 1
    bgeu t1, s1, comp_a_ascii   # 2e octet hors limite de a -> octet isolé
    add  t0, s0, t1
    lbu  s8, 0(t0)        # 2e octet brut de a
    mv   a0, s8
    jal  ra, Map
    mv   s6, a0           # s6 = valeur mappée de a
    li   s9, 2
    j    comp_b

comp_a_ascii:
    mv   a0, s7
    jal  ra, Map
    mv   s6, a0           # s6 = valeur mappée de a

    # --- Lire le caractère courant de b (à s5, borne s3) ---
    # On garde :
    #   t2 = 1er octet brut de b
    #   t3 = 2e octet brut de b (0 si 1 octet)
    #   t4 = pas de b (1 ou 2)
    #   a0 = valeur mappée de b
comp_b:
    add  t0, s2, s5
    lbu  t2, 0(t0)        # 1er octet brut de b
    li   t3, 0            # 2e octet brut de b par défaut = 0
    li   t4, 1            # pas de b par défaut = 1 octet

    li   t0, 0xC3
    bne  t2, t0, comp_b_ascii
    addi t1, s5, 1
    bgeu t1, s3, comp_b_ascii   # 2e octet hors limite de b -> octet isolé
    add  t0, s2, t1
    lbu  t3, 0(t0)        # 2e octet brut de b

    # Sauvegarder t2, t3, t4 avant jal ra, Map (t0-t6 peuvent être écrasés)
    addi sp, sp, -16
    sd   t2, 8(sp)
    sd   t3, 0(sp)
    mv   a0, t3
    jal  ra, Map
    ld   t2, 8(sp)
    ld   t3, 0(sp)
    addi sp, sp, 16
    li   t4, 2
    j    comp_comparer_car

comp_b_ascii:
    addi sp, sp, -16
    sd   t2, 8(sp)
    sd   t3, 0(sp)
    mv   a0, t2
    jal  ra, Map
    ld   t2, 8(sp)
    ld   t3, 0(sp)
    addi sp, sp, 16
    li   t4, 1

    # --- Règle 2 : comparer les valeurs mappées (s6 vs a0) ---
comp_comparer_car:
    bne  s6, a0, comp_diff_map

    # --- Règle 3 : départage par octets bruts ---
    bne  s7, t2, comp_diff_brut1
    bne  s8, t3, comp_diff_brut2

    # Caractères identiques : avancer les deux index
    add  s4, s4, s9
    add  s5, s5, t4
    j    comp_boucle

comp_diff_map:
    sub  a0, s6, a0
    j    comp_fin

comp_diff_brut1:
    sub  a0, s7, t2
    j    comp_fin

comp_diff_brut2:
    sub  a0, s8, t3
    j    comp_fin

    # --- Règle 4 : départage par longueur en octets ---
comp_fin_commun:
    sub  a0, s1, s3

comp_fin:
    ld   ra, 88(sp)
    ld   s0, 80(sp)
    ld   s1, 72(sp)
    ld   s2, 64(sp)
    ld   s3, 56(sp)
    ld   s4, 48(sp)
    ld   s5, 40(sp)
    ld   s6, 32(sp)
    ld   s7, 24(sp)
    ld   s8, 16(sp)
    ld   s9, 8(sp)
    addi sp, sp, 96
    ret