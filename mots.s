# ============================================================
# TP2 - Dictionnaire de mots
# INF2171 - Automne 2026
# RISC-V 64 bits
# Auteur : LABE Judes Et Thierry
# Code permanent : LABM64310600 et BECT90050208
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

.align 3
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

str_err_dict:
    .string "Erreur :  dictionnaire plein\n"

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
    
    la   a0, input
    la   a1, dictionnaire
    la   t0, compte
    ld   a2, 0(t0)
    jal  ra, Imprimer

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
    MAP_DIACRITIQUE 0x80, 'A'   # À
    MAP_DIACRITIQUE 0x82, 'A'   # Â
    MAP_DIACRITIQUE 0x84, 'A'   # Ä
    MAP_DIACRITIQUE 0x87, 'C'   # Ç
    MAP_DIACRITIQUE 0x88, 'E'   # È
    MAP_DIACRITIQUE 0x89, 'E'   # É
    MAP_DIACRITIQUE 0x8A, 'E'   # Ê
    MAP_DIACRITIQUE 0x8B, 'E'   # Ë
    MAP_DIACRITIQUE 0x8E, 'I'   # Î
    MAP_DIACRITIQUE 0x8F, 'I'   # Ï
    MAP_DIACRITIQUE 0x94, 'O'   # Ô
    MAP_DIACRITIQUE 0x96, 'O'   # Ö
    MAP_DIACRITIQUE 0x99, 'U'   # Ù
    MAP_DIACRITIQUE 0x9B, 'U'   # Û
    MAP_DIACRITIQUE 0x9C, 'U'   # Ü

map_fin:
    ret
    
    
# ------------------------------------------------------------
# 7.7 ROUTINE : Comparer
# ------------------------------------------------------------
# Entrées (ABI RV64) :
#   a0 = adresse du premier mot (&a)
#   a1 = adresse du second mot (&b)
#   a2 = longueur du premier mot (en octets)
#
# Sortie :
#   a0 < 0 si premier mot a < second mot b
#   a0 = 0 si les deux mots sont identiques
#   a0 > 0 si premier mot a > second mot b
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
    addi sp, sp, -64
    sd   ra, 56(sp)
    sd   s0, 48(sp)
    sd   s1, 40(sp)     
    sd   s2, 32(sp)   
    sd   s3, 24(sp)      
    sd   s4, 16(sp)    
    sd   s5, 8(sp)       

    mv   s0, a0		# adresse premier mot a
    mv   s1, a1		# adresse du second mot b
    mv   s2, a2		# Longueur a comparer
    li   s3, 0		# index

comp_boucle:
    bgeu s3, s2, comp_identique
    
    # Lecture octects
    add t0, s0, s3
    lbu s4, 0(t0)
    add t0, s1, s3
    lbu s5, 0(t0)
    
    # Octets identique = continuer
    beq s4, s5, comp_avancer
    
    # Verifier accent premier mot a
    li t0, 0xC3
    beq s4, t0, comp_accent_a
    
    # Verifier accent premier mot b
    beq s5, t0, comp_accent_b
    
    # Comparer octet brut
    sub a0, s4, s5
    j comp_fin
    
comp_avancer:
    # avancer Index
    addi s3, s3, 1
    j comp_boucle

comp_accent_a:
    # Recupere deuxieme octet UTF8
    add t0, s0, s3
    lbu a0,1(t0)
    jal ra, Map
    # comparer le caractere avec celui de b
    beq a0, s5, comp_positif
    sub a0, a0, s5
    j comp_fin

comp_accent_b:
    # Recupere deuxieme octet UTF8
    add t0, s1, s3
    lbu a0, 1(t0)
    jal ra, Map
    # comparer le caractere avec celui de b
    beq a0, s4, comp_negatif
    sub a0, s4, a0
    j comp_fin

comp_positif:
    li a0, 1
    j comp_fin

comp_negatif:
    li a0, -1
    j comp_fin

comp_identique:
    li a0, 0 

comp_fin:
    ld   ra, 56(sp)
    ld   s0, 48(sp)
    ld   s1, 40(sp)     
    ld   s2, 32(sp)   
    ld   s3, 24(sp)      
    ld   s4, 16(sp)    
    ld   s5, 8(sp) 
    addi sp, sp, 64
    ret
# ============================================================
# 7.8 ROUTINE : Recherche
# ============================================================
# Entrées :
#   a0 = &ligne
#   a1 = début du mot
#   a2 = longueur du mot
#   a3 = &dictionnaire
#   a4 = décompte
# Sorties :
#   a0 = index trouvé ou position d'insertion
#   a1 = 1 si trouvé, 0 sinon
# ============================================================
Rechercher:
    addi sp, sp, -80

    sd   ra, 72(sp)
    sd   s0, 64(sp)
    sd   s1, 56(sp)
    sd   s2, 48(sp)
    sd   s3, 40(sp)
    sd   s4, 32(sp)
    sd   s5, 24(sp)
    sd   s6, 16(sp)
    sd   s7, 8(sp)
    sd   s8, 0(sp)

    mv   s0, a3          # adresse dictionnaire
    mv   s1, a4          # nombre d'entrées
    add  s2, a0, a1	 # adresse mot cible
    mv   s3, a2         # longueur mot cible
    mv   s4, a0          # adresse ligne

    li   s5, 0           # i = 0
    addi s6, s1, -1      # j = compte  -1

rech_boucle:
    bgt s5, s6, rech_absent

    # Calcul de l'index du milieu	
    add  s7, s5, s6
    srli s7, s7, 1       # mid = (low + high) / 2

    # Adresse entrée mid : dictionnaire + mid * 24
    slli t0, s7, 4
    slli t1, s7, 3
    add t0, t0, t1
    add t0, s0, t0
    # Recuperer le mot dans le dictionnaire
    ld  t2, 0(t0)       # position du mot
    ld  s8, 8(t0)       # longueur du mot
    add t2, s4, t2      # adresse du mot
    
    # Determiner la longueur minimale
    mv a2, s3
    bleu s3, s8, rech_comparer
    mv a2, s8
rech_comparer:
    mv   a0, s2
    mv   a1, t2
    jal  ra, Comparer

    bltz a0, rech_gauche
    bgtz a0, rech_droite

    # Comparer les longueurs
    beq  s3, s8, rech_trouve
    bltu s3, s8, rech_gauche
    j    rech_droite

rech_gauche:
    addi s6, s7, -1
    j    rech_boucle

rech_droite:
    addi s5, s7, 1
    j    rech_boucle

rech_trouve:
    mv   a0, s7
    li   a1, 1
    j    rech_fin

rech_absent:
    mv   a0, s5		
    li   a1, 0

rech_fin:
    ld ra, 72(sp)
    ld s0, 64(sp)
    ld s1, 56(sp)
    ld s2, 48(sp)
    ld s3, 40(sp)
    ld s4, 32(sp)
    ld s5, 24(sp)
    ld s6, 16(sp)
    ld s7, 8(sp)
    ld s8, 0(sp)

    addi sp, sp, 80
    ret

# ------------------------------------------------------------
# 7.9 ROUTINE : Inserer
# ------------------------------------------------------------
#	Entrées (ABI RV64) :
#	a1: debut mot
#	a2: longueur mot
#	a3: adresse dictionnaire
#	a4: adresse decompte
#-------------------------------------------------------------
Insérer:
    addi sp, sp, -64
    sd   ra, 56(sp)
    sd   s0, 48(sp)
    sd   s1, 40(sp)     
    sd   s2, 32(sp)   
    sd   s3, 24(sp)      
    sd   s4, 16(sp)    
    sd   s5, 8(sp)  
    
    # Sauvegarder les informations
    mv s0, a1	 # valeur debut mot
    mv s1, a2    # valeur longueur mot
    mv s2, a3    # adresse dictionnaire
    mv s3, a4    # adresse decompte
    ld s4, 0(s3) # valeur decompte
    
    # Rechercher mot dans le dictionnaire
    mv a4,s4
    jal ra, Rechercher
    mv s5, a0 # index trouver dans recherche
    
    # calcul de l'adresse : index * 24
    slli t0, s5, 4
    slli t1, s5, 3
    add t0, t0, t1
    add t0, s2, t0
    
    # verifier si le mot exister pour augmenter sa frequence 
    bnez a1, inserer_frequence
    
    # verifier capacite  du dictionnaire
    li t1 MAXMOTS
    bgeu s4, t1, inserer_plein
    
    # adresse case libre
    slli t1, s4, 4
    slli t2, s4, 3
    add t1, t1, t2
    add t1, s2, t1
   
inserer_decaler:
    # arret lorsqu'on atteint une adresse d'insertion
    beq t1, t0, inserer_nouveau
    
    # adresse du precedent
    addi t2, t1, -24
     
     # copier des valeurs
     ld t3, 0(t2)
     ld t4, 8(t2)
     ld t5, 16(t2)
     sd t3, 0(t1)
     sd t4, 8(t1)
     sd t5, 16(t1)
     
     # reculer d'un triplet
     addi t1, t1, -24
     j inserer_decaler
inserer_nouveau:
     # Enregistrer position et longueur
     sd s0, 0(t0)
     sd s1, 8(t0)
     
     # Mettre la frequence a zero     
     sd zero, 16(t0)
      
     # Augmenter le nombre de mots differents
     addi s4, s4, 1
     sd s4, 0(s3)
inserer_frequence:
     # Augmenter frequence du mot
     ld t1, 16(t0)
     addi t1, t1, 1
     sd t1, 16(t0)
     j inserer_fin
inserer_plein:
     la a0 ,str_err_dict
     j ecrire_erreur
inserer_fin:
     ld ra, 56(sp)
     ld s0, 48(sp)
     ld s1, 40(sp)
     ld s2, 32(sp)
     ld s3, 24(sp)
     ld s4, 16(sp)
     ld s5, 8(sp)
      
     addi sp,sp,64
     ret
# ------------------------------------------------------------
# 7.10 ROUTINE : Imprimer
# ------------------------------------------------------------
#	Entrées (ABI RV64) :
#       a0: adresse texte
#	a1: adresse dictionnaire
#	a2: nombre de mots differents
#-------------------------------------------------------------
Imprimer:
    addi sp, sp, -48
    sd   s0, 40(sp)
    sd   s1, 32(sp)
    sd   s2, 24(sp)
    sd   s3, 16(sp)
    sd   s4, 8(sp)
    sd   s5, 0(sp)

    mv   s0, a0          # Adresse du texte
    mv   s1, a1          # Adresse du dictionnaire
    mv   s2, a2          # Nombre de mots distincts

imprimer_boucle:
    beqz s2, imprimer_fin

    # Récupérer la position et la longueur
    ld   s3, 0(s1)
    ld   s4, 8(s1)

    # Afficher la position
    mv   a0, s3
    li   a7, print_int
    ecall

    # Afficher un espace
    li   a0, 32
    li   a7, print_char
    ecall

    # Afficher la longueur
    mv   a0, s4
    li   a7, print_int
    ecall

    # Afficher un espace
    li   a0, 32
    li   a7, print_char
    ecall

    # Afficher la fréquence
    ld   a0, 16(s1)
    li   a7, print_int
    ecall

    # Afficher un espace
    li   a0, 32
    li   a7, print_char
    ecall

    # Calculer l'adresse du mot
    add  s5, s0, s3

imprimer_mot:
    beqz s4, imprimer_suivant

    # Afficher un octet du mot
    lbu  a0, 0(s5)
    li   a7, print_char
    ecall

    # Avancer dans le mot
    addi s5, s5, 1
    addi s4, s4, -1
    j    imprimer_mot

imprimer_suivant:
    # Retour à la ligne
    li   a0, 10
    li   a7, print_char
    ecall

    # Passer au prochain triplet
    addi s1, s1, 24
    addi s2, s2, -1
    j    imprimer_boucle

imprimer_fin:
    ld   s0, 40(sp)
    ld   s1, 32(sp)
    ld   s2, 24(sp)
    ld   s3, 16(sp)
    ld   s4, 8(sp)
    ld   s5, 0(sp)

    addi sp, sp, 48
    ret

    
