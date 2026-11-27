.eqv prstr      4
.eqv print_int  1
.eqv print_char 11
.eqv exit       10

.data
.align 3

# Tampon input contenant : "abc" (0..2), "le" (4..5), "rà" (7..9)
# Octets de input : 'a','b','c',' ', 'l','e',' ', 'r', 0xC3, 0xA0, 0x00
input_buf:
    .byte 0x61, 0x62, 0x63, 0x20, 0x6C, 0x65, 0x20, 0x72, 0xC3, 0xA0, 0x00

.align 3
# Dictionnaire de 3 entrées triées (24 octets chacune : pos, len, freq)
# Entrée 0 : "abc" -> pos=0, len=3, freq=2
# Entrée 1 : "le"  -> pos=4, len=2, freq=5
# Entrée 2 : "rà"  -> pos=7, len=3, freq=1
dict_3:
    .dword 0, 3, 2
    .dword 4, 2, 5
    .dword 7, 3, 1

# Mots cibles de test
c_a:        .string "a"
c_abd:      .string "abd"
c_le:       .string "le"
c_ra_acc:   .byte 0x72, 0xC3, 0xA0, 0x00    # "rà"
c_zzz:      .string "zzz"

str_t:      .string "rech #"
str_arrow:  .string " -> idx="
str_found:  .string ", found="

.text
#.globl main

main:
    # 1. Dictionnaire vide (n=0), cible "le" -> idx=0, found=0
    la   a0, dict_3
    li   a1, 0
    la   a2, c_le
    li   a3, 2
    la   a4, input_buf
    li   a5, 1
    jal  ra, exec_rech

    # 2. Mot présent au milieu ("le", len=2) -> idx=1, found=1
    la   a0, dict_3
    li   a1, 3
    la   a2, c_le
    li   a3, 2
    la   a4, input_buf
    li   a5, 2
    jal  ra, exec_rech

    # 3. Mot absent au début ("a", len=1) -> idx=0, found=0
    la   a0, dict_3
    li   a1, 3
    la   a2, c_a
    li   a3, 1
    la   a4, input_buf
    li   a5, 3
    jal  ra, exec_rech

    # 4. Mot absent au milieu ("abd", len=3) -> idx=1, found=0
    la   a0, dict_3
    li   a1, 3
    la   a2, c_abd
    li   a3, 3
    la   a4, input_buf
    li   a5, 4
    jal  ra, exec_rech

    # 5. Mot absent à la fin ("zzz", len=3) -> idx=3, found=0
    la   a0, dict_3
    li   a1, 3
    la   a2, c_zzz
    li   a3, 3
    la   a4, input_buf
    li   a5, 5
    jal  ra, exec_rech

    # 6. Mot présent avec accent ("rà", len=3) -> idx=2, found=1
    la   a0, dict_3
    li   a1, 3
    la   a2, c_ra_acc
    li   a3, 3
    la   a4, input_buf
    li   a5, 6
    jal  ra, exec_rech

    li   a7, exit
    ecall

# Helper : appelle Rechercher(a0..a4) avec num_test en a5
exec_rech:
    addi sp, sp, -80
    sd   ra, 72(sp)
    sd   s0, 64(sp)
    sd   s1, 56(sp)
    sd   a0, 0(sp)
    sd   a1, 8(sp)
    sd   a2, 16(sp)
    sd   a3, 24(sp)
    sd   a4, 32(sp)
    sd   a5, 40(sp)

    la   a0, str_t
    li   a7, prstr
    ecall

    ld   a0, 40(sp)
    li   a7, print_int
    ecall

    la   a0, str_arrow
    li   a7, prstr
    ecall

    ld   a0, 0(sp)
    ld   a1, 8(sp)
    ld   a2, 16(sp)
    ld   a3, 24(sp)
    ld   a4, 32(sp)
    jal  ra, Rechercher
    mv   s0, a0             # idx / insert pos
    mv   s1, a1             # found (0 ou 1)

    mv   a0, s0
    li   a7, print_int
    ecall

    la   a0, str_found
    li   a7, prstr
    ecall

    mv   a0, s1
    li   a7, print_int
    ecall

    li   a0, 10
    li   a7, print_char
    ecall

    ld   ra, 72(sp)
    ld   s0, 64(sp)
    ld   s1, 56(sp)
    addi sp, sp, 80
    ret

# ============================================================
# Rechercher
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
    bge s5, s6, rech_absent

    # Calcul de l'index du milieu	
    add  s7, s5, s6
    srli s7, s7, 1       # mid = (low + high) / 2

    # Adresse entrée mid : dictionnaire + mid * 24
    slli t0, s7, 4
    slli t1, s7, 3
    add  t0, t0, t1
    add  t0, s0, t0
    # Recuperer le mot dans le dictionnaire
    ld   t2, 0(t0)       # position du mot
    ld   s8, 8(t0)       # longueur du mot
    add  t2, s4, t2      # adresse du mot
    
    # Determiner la longueur minimale
    mv a2, s3
    bleu s3, s8, rech_comparer
    mv a2, s8
    
rech_comparer:
    mv   a0, s2          # adresse du mot cible
    mv   a1, t3          # adresse mot dictionnaire
    jal  ra, Comparer
    # comparer les longueurs des préfixes identique
    bltz  a0, rech_trouve
    bgtz  a0, rech_droite
    j    rech_boucle
rech_gauche:
    addi s6, s7, -1      # j = m - 1
rech_droite:
    addi s5, s7, 1       # i = m + 1
    j    rech_boucle

rech_trouve:
    mv   a0, s7
    li   a1, 1
    j    rech_fin

rech_absent:
    mv   a0, s5		
    li   a1, 0

rech_fin:
    ld   ra, 72(sp)
    ld   s0, 64(sp)
    ld   s1, 56(sp)
    ld   s2, 48(sp)
    ld   s3, 40(sp)
    ld   s4, 32(sp)
    ld   s5, 24(sp)
    ld   s6, 16(sp)
    ld   s7, 8(sp)

    addi sp, sp, 80
    ret

Map:
    li   t0, 0xA0
    beq  a0, t0, map_a
    li   t0, 0xA2
    beq  a0, t0, map_a
    li   t0, 0xA4
    beq  a0, t0, map_a
    li   t0, 0x80
    beq  a0, t0, map_a
    li   t0, 0x82
    beq  a0, t0, map_a
    li   t0, 0x84
    beq  a0, t0, map_a

    li   t0, 0xA7
    beq  a0, t0, map_c
    li   t0, 0x87
    beq  a0, t0, map_c

    li   t0, 0xA8
    beq  a0, t0, map_e
    li   t0, 0xA9
    beq  a0, t0, map_e
    li   t0, 0xAA
    beq  a0, t0, map_e
    li   t0, 0xAB
    beq  a0, t0, map_e
    li   t0, 0x88
    beq  a0, t0, map_e
    li   t0, 0x89
    beq  a0, t0, map_e
    li   t0, 0x8A
    beq  a0, t0, map_e
    li   t0, 0x8B
    beq  a0, t0, map_e

    li   t0, 0xAE
    beq  a0, t0, map_i
    li   t0, 0xAF
    beq  a0, t0, map_i
    li   t0, 0x8E
    beq  a0, t0, map_i
    li   t0, 0x8F
    beq  a0, t0, map_i

    li   t0, 0xB4
    beq  a0, t0, map_o
    li   t0, 0xB6
    beq  a0, t0, map_o
    li   t0, 0x94
    beq  a0, t0, map_o
    li   t0, 0x96
    beq  a0, t0, map_o

    li   t0, 0xB9
    beq  a0, t0, map_u
    li   t0, 0xBB
    beq  a0, t0, map_u
    li   t0, 0xBC
    beq  a0, t0, map_u
    li   t0, 0x99
    beq  a0, t0, map_u
    li   t0, 0x9B
    beq  a0, t0, map_u
    li   t0, 0x9C
    beq  a0, t0, map_u

    li   t0, 0x41
    bltu a0, t0, map_fin
    li   t0, 0x5A
    bgtu a0, t0, map_fin
    addi a0, a0, 32
    ret

map_a:
    li   a0, 'a'
    ret
map_c:
    li   a0, 'c'
    ret
map_e:
    li   a0, 'e'
    ret
map_i:
    li   a0, 'i'
    ret
map_o:
    li   a0, 'o'
    ret
map_u:
    li   a0, 'u'
    ret
map_fin:
    ret

Comparer:
    addi sp, sp, -96
    sd   ra, 88(sp)
    sd   s0, 80(sp)
    sd   s1, 72(sp)
    sd   s2, 64(sp)
    sd   s3, 56(sp)
    sd   s4, 48(sp)
    sd   s5, 40(sp)
    sd   s6, 32(sp)
    sd   s7, 24(sp)
    sd   s8, 16(sp)
    sd   s9, 8(sp)

    mv   s0, a0
    mv   s1, a1
    mv   s2, a2
    mv   s3, a3
    li   s4, 0
    li   s5, 0
    li   s6, 0

comp_boucle:
    bgeu s4, s1, comp_fin_commun
    bgeu s5, s3, comp_fin_commun

    add  t0, s0, s4
    lbu  s7, 0(t0)
    li   s8, 0
    li   s9, 1

    li   t0, 0xC3
    bne  s7, t0, comp_a_ascii
    addi t1, s4, 1
    bgeu t1, s1, comp_a_ascii
    add  t0, s0, t1
    lbu  s8, 0(t0)
    mv   a0, s8
    jal  ra, Map
    mv   s6, a0
    li   s9, 2
    j    comp_b

comp_a_ascii:
    mv   a0, s7
    jal  ra, Map
    mv   s6, a0

comp_b:
    add  t0, s2, s5
    lbu  t2, 0(t0)
    li   t3, 0
    li   t4, 1

    li   t0, 0xC3
    bne  t2, t0, comp_b_ascii
    addi t1, s5, 1
    bgeu t1, s3, comp_b_ascii
    add  t0, s2, t1
    lbu  t3, 0(t0)

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

comp_comparer_car:
    bne  s6, a0, comp_diff_map

    bne  s7, t2, comp_diff_brut1
    bne  s8, t3, comp_diff_brut2

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
