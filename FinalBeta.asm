.data
.space 65536			# espaço para bitmap de 128 x 128 pixels
matriz: .space 1024
minas: .asciiz "Digite o numero de minas: \n"
vermelho:.word 0xFFFF0100
espaço123: .asciiz"\n"
go: .asciiz "\nVocê ativou uma mina! \n"
stringL: .asciiz "Linha: \n"
stringC: .asciiz "Coluna: \n"
string3: .asciiz "Digite 0 para desistir, 1 para abrir casa, outro número para colocar/tirar bandeira:\n"
stringBandeira: .asciiz "Bandeira: \n"
stringCasa: .asciiz "Digite as coordenadas para abrir. \n"
stringBan: .asciiz "Digite as coordenadas para a bandeira. \n"
stringVitória: .asciiz "Parabéns, você abriu todo o tabuleiro sem ativar uma mina! \n"
.text
la $s5, matriz
li $s0, 0x10010000		# s0 = first Pixel of the screen
addi $s1, $s0, 65024 		# s1 = Ãºltima posiÃ§Ã£o do bitmap?
move $a0, $s0			# argumento 1 = first Pixel of the screen
jal desenhaGrade		# matriz[n][m] = n*16 + m

move $a0, $s5			# argumento a0 = matriz	
li $v0, 4			
la $a0, minas			# "Digite o numero de minas: \n"
syscall	
li $v0, 5			# cÃ³digo 5 le inteiro
syscall

move $s2, $v0			# s2 = numero de minas
move $a0, $s2			# argumento a0 = numero de minas

jal criaMatriz	
jal loopCalculaV2

la $a0, espaço123
li $v0, 4			
syscall

loopMenu:

la $a0, matriz		
jal printaMatriz

li $v0, 4			# cÃ³digo 4 imprime string
la $a0, string3			# "0 para desistir, 1 para colocar/tirar bandeira, outro numero para escolhar:\n"
syscall	
li $v0, 5			# codigo 5 le inteiro
syscall
beq $v0, $zero, fimmmm
bne $v0, 1, setarBandeira

li $v0, 4			# cÃ³digo 4 imprime string
la $a0, stringCasa
syscall

li $v0, 4			
la $a0, stringL			# "Linha: \n"
syscall	
li $v0, 5			
syscall
move $a1, $v0			# a1 = Linha
li $v0, 4			
la $a0, stringC			# "Coluna: \n"
syscall	
li $v0, 5			
syscall
move $a2, $v0			# a2 = Coluna

jal revelaCasa
jal condiçãoVitória
j loopMenu

setarBandeira:
li $v0, 4			# cÃ³digo 4 imprime string
la $a0, stringBan
syscall
li $v0, 4			
la $a0, stringL			# "Linha: \n"
syscall	
li $v0, 5			
syscall
move $a1, $v0			# a1 = Linha
li $v0, 4			
la $a0, stringC			# "Coluna: \n"
syscall	
li $v0, 5			
syscall
move $a2, $v0			# a2 = Coluna

li $a3, -2
jal setaNumero			# retorna v0 = 0 , se retirou uma bandeira

mul $a1, $a1, 64		# t1 = linha*16*4
mul $a2, $a2, 4			# t2 = coluna*1*4
add $a0, $s5, $a1		# $t3 = base + linha*64
add $a0, $a0, $a2		# t3 = base + linha*64 + coluna*4
beq $v0, 1, retirouBandeira

jal printCasa
j loopMenu

retirouBandeira:
jal converteMatrizToBitMap
jal drawPreto

j loopMenu
fimmmm:
jal printaMatrizBitMap
li $v0, 10			# cÃ³digo para encerrar
syscall				# chamada do encerramento


#####################################################################################################

condiçãoVitória:		# s5 = matriz

li $a0, 256			# número de casas
li $v0, 256
move $a2, $s5
				# s2 = número de minas
				# vitória acontece quando casasTotais - casasAbertas = número de minas
				# 256 - (número de -1) = s2
and $a3, $zero, $zero		# a3 = 0 = número de -1	

loopCV:
lw $a1, 0($a2)		# t1 = casa[aleatoria]
bne $a1, -1, CV
addi $a3, $a3, 1
CV:
addi $a0, $a0, -1		# --a0
addi $a2, $a2, 4		# ++ a2
beq $a0, $0, fimCV

j loopCV

fimCV:
sub $v0, $v0, $a3
beq $v0, $s2, Vitória

jr $ra
Vitória:
li $v0, 4			# código 4 imprime string
la $a0, stringVitória	
syscall
j fimmmm
#####################################################################################################

setaNumero:			
				# a1 = linha, a2 = coluna, a3 = numero
				# -1, apenas coloca, se for -2 faz lógica bandeira
				# retorna v0 = 0, se retirou uma bandeira  1
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

addi $sp,$sp, -4
sw $a2, 0($sp)			# push a2
addi $sp,$sp, -4
sw $a1, 0($sp)			# push a1

li $v0, 0			# retorna 1, se  n retirou uma bandeira, então...

la $v0, matriz			# t0 = endereço base

mul $a1, $a1, 64		# t1 = linha*64
mul $a2, $a2, 4			# t2 = coluna*4
add $v1, $v0, $a1		# $t3 = base + linha*64
add $v1, $v1, $a2		# t3 = base + linha*64 + coluna*4

beq $a3, -2, SNBandeira
sw $a3, ($v1)			# seta casa desejada

fimSN:		
lw $a1, 0($sp)		
addi $sp,$sp, 4
lw $a2, 0($sp)		
addi $sp,$sp, 4

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra

SNBandeira:
lw $a2, 0($v1)
beq $a2, -1, fimSN		# Não faz nada, pois casa já aberta :)
blt $a2, -1, tiraBandeira
addi $a2, $a2, -11		# bandeira irá diminuir -11 da casa
sw $a2, 0($v1)			# armazena a bandeira

j fimSN
tiraBandeira:
addi $a2, $a2, 11
sw $a2, 0($v1)			# armazena a bandeira
li $v0, 1
j fimSN
#####################################################################################################

revelaCasa:			# a1 = linha, a2 = COLUNA			
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

addi $sp,$sp, -4
sw $a2, 0($sp)			# push a2
addi $sp,$sp, -4
sw $a1, 0($sp)			# push a1
addi $sp,$sp, -4	
sw $t0, 0($sp)			# push t0
addi $sp,$sp, -4
sw $t1, 0($sp)			# push t1
addi $sp,$sp, -4
sw $t2, 0($sp)			# push t2
addi $sp,$sp, -4
sw $t3, 0($sp)			# push t3
addi $sp,$sp, -4
sw $t4, 0($sp)			# push t4

la $t0, matriz			# t0 = endereço base
move $t1, $a1
move $t2, $a2
mul $t1, $t1, 64		# t1 = linha*64
mul $t2, $t2, 4			# t2 = COLUNA*4
add $t3, $t0, $t1		# $t3 = base + linha*64
add $t3, $t3, $t2		# t3 = base + linha*64 + COLUNA*4

lw $t4, ($t3)			# carrega valor da casa
beq $t4, 9, gameover		# game over
beq $t4, 0, droga0		# recursão...
				# se não... apenas printa número
move $a0, $t3

jal printCasa
li $a3, -1
jal setaNumero			# seta -1 na casa recém aberta
j fimJogo

droga0:
move $a0, $t3
jal printCasa
li $a3, -1
jal setaNumero			# seta -1 na casa recém aberta
#########################################
beq $a1, 0, LINE0		# LINE 0
beq $a1, 15, LINE15		# LINE 15
beq $a2, 0, COLUNA0		# COLUNA0
beq $a2, 15, COLUNA15		# COLUNA15

# se nao, LINEPCOLUNAP
lw $t4, 4($t3)			# t4 =  [l][c+1] 
blt $t4, 0, r2aa

#addi $a1, $a1, 0
addi $a2, $a2, 1
jal revelaCasa
#addi $a1, $a1, 0
addi $a2, $a2, -1

r2aa:
lw $t4, -4($t3)		# t4 =  [l-1][c] 
blt $t4, 0, r2bb

addi $a1, $a1, 0
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, 1

r2bb:
lw $t4, -64($t3)		# t4 =  [l-1][c-1] 
blt $t4, 0, r2cc

addi $a1, $a1, -1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 0

r2cc:
lw $t4, 64($t3)		# t4 =  [l+1][c+1] 
blt $t4, 0, r2dd

addi $a1, $a1, 1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 0

r2dd:
lw $t4, 60($t3)		# t4 =  [l+1][c+1] 
blt $t4, 0, r2ee

addi $a1, $a1, 1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 1

r2ee:
lw $t4, -60($t3)		# t4 =  [l+1][c+1] 
blt $t4, 0, r2ff

addi $a1, $a1, 1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 1

r2ff:
lw $t4, 68($t3)		# t4 =  [l+1][c+1] 
blt $t4, 0, r2gg

addi $a1, $a1, 1
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, -1

r2gg:
lw $t4, -68($t3)		# t4 =  [l+1][c+1] 
blt $t4, 0, r2hh

addi $a1, $a1, -1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 1

r2hh:
j ENDV2ok
#**********************************************************
COLUNA15:
# só sobrou LinhaPColuna15
lw $t4, -4($t3)			# t4 =  [l][c-1] 
blt $t4, 0, w2aa

addi $a1, $a1, 0
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, 1

w2aa:
lw $t4, -64($t3)		# t4 =  [l-1][c] 
blt $t4, 0, w2bb

addi $a1, $a1, -1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 0

w2bb:
lw $t4, -68($t3)		# t4 =  [l-1][c-1] 
blt $t4, 0, w2cc

addi $a1, $a1, -1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 1

w2cc:
lw $t4, 64($t3)		# t4 =  [l+1][c+1] 
blt $t4, 0, w2dd

addi $a1, $a1, 1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 0

w2dd:
lw $t4, 60($t3)		# t4 =  [l+1][c+1] 
blt $t4, 0, w2ee

addi $a1, $a1, 1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 1

w2ee:
j ENDV2ok
#**********************************************************
COLUNA0:
# só sobrou caso LinhaPCOLUNA0
lw $t4, 4($t3)			# t4 =  [l][c+1] 
blt $t4, 0, q2aa
jal revelaCasa
q2aa:
lw $t4, -64($t3)			# t4 =  [l-1][c] 
blt $t4, 0, q2bb

addi $a1, $a1, -1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 0

q2bb:
lw $t4, -60($t3)		# t4 =  [l-1][c+1] 
blt $t4, 0, q2cc

addi $a1, $a1, -1
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, -1

q2cc:
lw $t4, 64($t3)			# t4 =  [l+1][c] 
blt $t4, 0, q2dd

addi $a1, $a1, 1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 0

q2dd:
lw $t4, 68($t3)			# t4 =  [l+1][c] 
blt $t4, 0, q2ee

addi $a1, $a1, 1
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, -1

q2ee:
j ENDV2ok
#**********************************************************
LINE15:
beq $a2, $zero, LINE15COLUNA0
beq $a2, 60, LINE15COLUNA15	# 4* 15
j LINE15COLUNAP

#------------------------------------------------------
LINE15COLUNA0:
lw $t4, 4($t3)			# t4 =  [l][c+1] 
blt $t4, 0, a2aa

addi $a1, $a1, 0
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, -1

a2aa:
lw $t4, -64($t3)			# t4 =  [l-1][c] 
blt $t4, 0, a2bb

addi $a1, $a1, -1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 0

a2bb:
lw $t4, -60($t3)			# t4 =  [l-1][c] 
blt $t4, 0, a2cc

addi $a1, $a1, -1
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, -1

a2cc:
j ENDV2ok	
#------------------------------------------------------
LINE15COLUNA15:
lw $t4, -4($t3)			# t4 =  [l][c-1] 
blt $t4, 0, z2aa

addi $a1, $a1, 0
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, 1

z2aa:			
lw $t4, -64($t3)		# t4 =  [l-1][c] 
blt $t4, 0, z2bb

addi $a1, $a1, -1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 0

z2bb:
lw $t4, -68($t3)		# t4 =  [l-1][c-1] 
blt $t4, 0, z2cc

addi $a1, $a1, -1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 1

z2cc:
j ENDV2ok
#------------------------------------------------------
LINE15COLUNAP:
lw $t4, -4($t3)			# t4 =  [l][c-1] 
blt $t4, 0, b2aa

addi $a1, $a1, 0
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, 1

b2aa:			
lw $t4, 4($t3)			# t4 =  [l][c+1] 
blt $t4, 0, b2bb

addi $a1, $a1, 0
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, -1

b2bb:
lw $t4, -64($t3)		# t4 =  [l-1][c] 
blt $t4, 0, b2ee

addi $a1, $a1, -1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 0

b2ee:
lw $t4, -68($t3)		# t4 =  [l-1][c-1] 
blt $t4, 0, b2cc

addi $a1, $a1, -1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, 1

b2cc:
lw $t4, -60($t3)		# t4 =  [l-1][c+1] 
blt $t4, 0, b2dd

addi $a1, $a1, -1
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, 1
addi $a2, $a2, -1

b2dd:
j ENDV2ok

#**********************************************************
LINE0:
beq $a2, $zero, LINE0COLUNA0
beq $a2, 60, LINE0COLUNA15	# 4* 15
j LINE0COLUNAP

#------------------------------------------------------
LINE0COLUNAP:
lw $t4, -4($t3)			# t4 =  [l][c-1] 
blt $t4, 0, x2aa

addi $a1, $a1, 0
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, 1

x2aa:
lw $t4, 64($t3)			# t4 =  [l+1][c] 
blt $t4, 0, x2bb

addi $a1, $a1, 1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 0

x2bb:
lw $t4, 60($t3)			# t4 =  [l+1][c-1] 
blt $t4, 0, x2cc

addi $a1, $a1, 1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 1

x2cc: 				
lw $t4, 68($t3)			# t4 =  [l+1][c+1] 
blt $t4, 0, x2dd

addi $a1, $a1, 1
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, -1

x2dd:
lw $t4, 4($t3)			# t4 =  [l+1][c+1] 
blt $t4, 0, x2ee

addi $a1, $a1, 0
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, -1

x2ee:
j ENDV2ok
#------------------------------------------------------
LINE0COLUNA15:
lw $t4, -4($t3)			# t4 =  [l][c-1] 
blt $t4, 0, c2aa

addi $a1, $a1, 0
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, 1

c2aa:
lw $t4, 64($t3)			# t4 =  [l+1][c] 
blt $t4, 0, c2bb

addi $a1, $a1, 1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 0

c2bb:
lw $t4, 60($t3)			# t4 =  [l+1][c-1] 
blt $t4, 0, c2cc

addi $a1, $a1, 1
addi $a2, $a2, -1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 1

c2cc:
j ENDV2ok
#------------------------------------------------------
LINE0COLUNA0:
lw $t4, 4($t3)			# t4 =  [l][c+1] 
blt $t4, 0, v2aa

addi $a1, $a1, 0
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, 0
addi $a2, $a2, -1

v2aa:
lw $t4, 64($t3)			# t4 =  [l+1][c] 
blt $t4, 0, v2bb

addi $a1, $a1, 1
addi $a2, $a2, 0
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, 0

v2bb:
lw $t4, 68($t3)			# t4 =  [l+1][c+1] 
blt $t4, 0, v2cc

addi $a1, $a1, 1
addi $a2, $a2, 1
jal revelaCasa
addi $a1, $a1, -1
addi $a2, $a2, -1

v2cc:
ENDV2ok:
#################################
fimJogo:
lw $t4, 0($sp)		
addi $sp,$sp, 4	
lw $t3, 0($sp)			
addi $sp,$sp, 4			
lw $t2, 0($sp)		
addi $sp,$sp, 4
lw $t1, 0($sp)		
addi $sp,$sp, 4
lw $t0, 0($sp)		
addi $sp,$sp, 4
lw $a1, 0($sp)		
addi $sp,$sp, 4
lw $a2, 0($sp)		
addi $sp,$sp, 4

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra

gameover:
li $v0, 4			# codigo 4 imprime string
la $a0, go			# argumento a0
syscall	
jal printaMatrizBitMap

li $v0, 10			# cÃ³digo para encerrar
syscall				# chamada do encerramento
#####################################################################################################

converteMatrizToBitMap:		# recebe  endereço $a0, retorna $v0 = linha, v1 = coluna
				# retorna a0 endereço bitmap
				
sub $a0, $a0, $s5		# endereço M - endereço base		
li $v0, 0			# linha
li $v1, 0			# coluna
				
linhaT:
ble $a0, 63, colunaT
addi $a0, $a0, -64
addi $v0, $v0, 1
j linhaT

colunaT:
ble $a0, 0, foraT
addi $a0, $a0, -4
addi $v1, $v1, 1
j colunaT

foraT:
mul $v0, $v0, 4096		# linha * (128) * 4 * 8
mul $v1, $v1, 32		# coluna * 8 * 4
add $a0, $v0, $v1
add $a0, $v0, $v1
add $a0, $a0, $s0
		
jr $ra
#####################################################################################################

printCasa:			# recebe endereço matriz em a0, BM em s0

addi $sp,$sp, -4
sw $ra, 0($sp)			

addi $sp,$sp, -4
sw $a2, 0($sp)		
addi $sp,$sp, -4
sw $a1, 0($sp)		
addi $sp,$sp, -4
sw $a0, 0($sp)			
addi $sp,$sp, -4
sw $t1, 0($sp)		
addi $sp,$sp, -4
sw $t2, 0($sp)		
addi $sp,$sp, -4
sw $t3, 0($sp)		
addi $sp,$sp, -4
sw $t4, 0($sp)		

lw $t2, 0($a0)			# t2 = valor = argumento

jal converteMatrizToBitMap	# retorna em a0 = endereço para o bitmap

beq $t2, 0, dddraw0
beq $t2, 1, dddraw1
beq $t2, 2, dddraw2
beq $t2, 3, dddraw3
beq $t2, 4, dddraw4
beq $t2, 5, dddraw5
beq $t2, 6, dddraw6
beq $t2, 7, dddraw7
beq $t2, 8, dddraw8
beq $t2, 9, dddraw9
beq $t2, -1, pilhaBM1		# caso for -1, n faz nada
				# se não, é bandeira

jal bandeira	
j pilhaBM1	
dddraw0:
jal drawBranco
j pilhaBM1
dddraw1:
jal draw1
j pilhaBM1
dddraw2:
jal draw2
j pilhaBM1
dddraw3:
jal draw3
j pilhaBM1
dddraw4:
jal draw4
j pilhaBM1
dddraw5:
jal draw5
j pilhaBM1
dddraw6:
jal draw6
j pilhaBM1
dddraw7:
jal draw7
j pilhaBM1
dddraw8:
jal draw8
j pilhaBM1
dddraw9:
jal mina

pilhaBM1:
lw $t4, 0($sp)		
addi $sp,$sp, 4	
lw $t3, 0($sp)			
addi $sp,$sp, 4			
lw $t2, 0($sp)		
addi $sp,$sp, 4
lw $t1, 0($sp)		
addi $sp,$sp, 4
lw $a0, 0($sp)			
addi $sp,$sp, 4			
lw $a1, 0($sp)		
addi $sp,$sp, 4
lw $a2, 0($sp)		
addi $sp,$sp, 4

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

printaMatrizBitMap:		# recebe endereço em s5, BM em s0

addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

move $t0, $s5			# t0 = endereço
li $t1, 0			# 0

loopBMBP:
lw $t2, 0($t0)			# a1 = valor = argumento
move $a0, $t0			# endereço matriz
blt $t2, -2, bandeiraErr
jal printCasa
backBMDP:
addi $t0, $t0, 4		# ++ endereço
addi $t1, $t1, 1		# ++ t1 = contador final
bne $t1, 256,loopBMBP			# 16*16*4

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra

bandeiraErr:
jal converteMatrizToBitMap
jal bandeiraErrada
j backBMDP
#####################################################################################################

calculaV2:			# a1 = linha, a2 = coluna
la $t0, matriz			# t0 = endereço base
move $t1, $a1
move $t2, $a2
mul $t1, $t1, 64		# t1 = linha*64
mul $t2, $t2, 4			# t2 = coluna*4
add $t3, $t0, $t1		# $t3 = base + linha*64
add $t3, $t3, $t2		# t3 = base + linha*64 + coluna*4

lw $t7, ($t3)			# carrega casa desejada
beq $t7, 9, fimV2		# é uma mina

move $t4, $t0
beq $t1, 0, linha0		# linha 0
beq $t1, 960, linha15		# linha 15*64
beq $t2, 0, coluna0		# coluna0
beq $t2, 60, coluna15		# coluna15*4

# se nao, linhaPcolunaP
lw $t4, 4($t3)			# t4 =  [l][c-1] 
bne $t4, 9, r2a
addi $t7, $t7, 1		# contador + 1
r2a:
lw $t4, -4($t3)		# t4 =  [l-1][c] 
bne $t4, 9, r2b
addi $t7, $t7, 1		# contador + 1
r2b:
lw $t4, -64($t3)		# t4 =  [l-1][c-1] 
bne $t4, 9, r2c
addi $t7, $t7, 1		# contador + 1
r2c:
lw $t4, 64($t3)		# t4 =  [l+1][c+1] 
bne $t4, 9, r2d
addi $t7, $t7, 1		# contador + 1
r2d:
lw $t4, 60($t3)		# t4 =  [l+1][c+1] 
bne $t4, 9, r2e
addi $t7, $t7, 1		# contador + 1
r2e:
lw $t4, -60($t3)		# t4 =  [l+1][c+1] 
bne $t4, 9, r2f
addi $t7, $t7, 1		# contador + 1
r2f:
lw $t4, 68($t3)		# t4 =  [l+1][c+1] 
bne $t4, 9, r2g
addi $t7, $t7, 1		# contador + 1
r2g:
lw $t4, -68($t3)		# t4 =  [l+1][c+1] 
bne $t4, 9, r2h
addi $t7, $t7, 1		# contador + 1
r2h:
j fimV2ok
#**********************************************************
coluna15:
# só sobrou LinhaPColuna15
lw $t4, -4($t3)			# t4 =  [l][c-1] 
bne $t4, 9, w2a
addi $t7, $t7, 1		# contador + 1
w2a:
lw $t4, -64($t3)		# t4 =  [l-1][c] 
bne $t4, 9, w2b
addi $t7, $t7, 1		# contador + 1
w2b:
lw $t4, -68($t3)		# t4 =  [l-1][c-1] 
bne $t4, 9, w2c
addi $t7, $t7, 1		# contador + 1
w2c:
lw $t4, 64($t3)		# t4 =  [l+1][c+1] 
bne $t4, 9, w2d
addi $t7, $t7, 1		# contador + 1
w2d:
lw $t4, 60($t3)		# t4 =  [l+1][c+1] 
bne $t4, 9, w2e
addi $t7, $t7, 1		# contador + 1
w2e:
j fimV2ok
#**********************************************************
coluna0:
# só sobrou caso LinhaPcoluna0
lw $t4, 4($t3)			# t4 =  [l][c+1] 
bne $t4, 9, q2a
addi $t7, $t7, 1		# contador + 1
q2a:
lw $t4, -64($t3)			# t4 =  [l-1][c] 
bne $t4, 9, q2b
addi $t7, $t7, 1		# contador + 1
q2b:
lw $t4, -60($t3)		# t4 =  [l-1][c+1] 
bne $t4, 9, q2c
addi $t7, $t7, 1		# contador + 1
q2c:
lw $t4, 64($t3)			# t4 =  [l+1][c] 
bne $t4, 9, q2d
addi $t7, $t7, 1		# contador + 1
q2d:
lw $t4, 68($t3)			# t4 =  [l+1][c] 
bne $t4, 9, q2e
addi $t7, $t7, 1		# contador + 1
q2e:
j fimV2ok
#**********************************************************
linha15:
beq $t2, $zero, linha15coluna0
beq $t2, 60, linha15coluna15	# 4* 15
j linha15colunaP

#------------------------------------------------------
linha15coluna0:
lw $t4, 4($t3)			# t4 =  [l][c+1] 
bne $t4, 9, a2a
addi $t7, $t7, 1		# contador + 1
a2a:
lw $t4, -64($t3)			# t4 =  [l-1][c] 
bne $t4, 9, a2b
addi $t7, $t7, 1		# contador + 1	
a2b:
lw $t4, -60($t3)			# t4 =  [l-1][c] 
bne $t4, 9, a2c
addi $t7, $t7, 1		# contador + 1
a2c:
j fimV2ok	
#------------------------------------------------------
linha15coluna15:
lw $t4, -4($t3)			# t4 =  [l][c-1] 
bne $t4, 9, z2a
addi $t7, $t7, 1		# contador + 1
z2a:			
lw $t4, -64($t3)		# t4 =  [l-1][c] 
bne $t4, 9, z2b
addi $t7, $t7, 1		# contador + 1
z2b:
lw $t4, -68($t3)		# t4 =  [l-1][c-1] 
bne $t4, 9, z2c
addi $t7, $t7, 1		# contador + 1
z2c:
j fimV2ok
#------------------------------------------------------
linha15colunaP:
lw $t4, -4($t3)			# t4 =  [l][c-1] 
bne $t4, 9, b2a
addi $t7, $t7, 1		# contador + 1
b2a:			
lw $t4, 4($t3)			# t4 =  [l][c+1] 
bne $t4, 9, b2b
addi $t7, $t7, 1		# contador + 1
b2b:
lw $t4, -64($t3)		# t4 =  [l-1][c] 
bne $t4, 9, b2e
addi $t7, $t7, 1		# contador + 1
b2e:
lw $t4, -68($t3)		# t4 =  [l-1][c-1] 
bne $t4, 9, b2c
addi $t7, $t7, 1		# contador + 1
b2c:
lw $t4, -60($t3)		# t4 =  [l-1][c+1] 
bne $t4, 9, b2d
addi $t7, $t7, 1		# contador + 1
b2d:
j fimV2ok

#**********************************************************
linha0:
beq $t2, $zero, linha0coluna0
beq $t2, 60, linha0coluna15	# 4* 15
j linha0colunaP

#------------------------------------------------------
linha0colunaP:
lw $t4, -4($t3)			# t4 =  [l][c-1] 
bne $t4, 9, x2a
addi $t7, $t7, 1		# contador + 1
x2a:
lw $t4, 64($t3)			# t4 =  [l+1][c] 
bne $t4, 9, x2b
addi $t7, $t7, 1		# contador + 1
x2b:
lw $t4, 60($t3)			# t4 =  [l+1][c-1] 
bne $t4, 9, x2c
addi $t7, $t7, 1
x2c: 				
lw $t4, 68($t3)			# t4 =  [l+1][c+1] 
bne $t4, 9, x2d
addi $t7, $t7, 1		# contador + 1
x2d:
lw $t4, 4($t3)			# t4 =  [l+1][c+1] 
bne $t4, 9, x2e
addi $t7, $t7, 1		# contador + 1
x2e:
j fimV2ok
#------------------------------------------------------
linha0coluna15:
lw $t4, -4($t3)			# t4 =  [l][c-1] 
bne $t4, 9, c2a
addi $t7, $t7, 1		# contador + 1
c2a:
lw $t4, 64($t3)			# t4 =  [l+1][c] 
bne $t4, 9, c2b
addi $t7, $t7, 1		# contador + 1
c2b:
lw $t4, 60($t3)			# t4 =  [l+1][c-1] 
bne $t4, 9, c2c
addi $t7, $t7, 1		# contador + 1
c2c:
j fimV2ok
#------------------------------------------------------
linha0coluna0:
lw $t4, 4($t3)			# t4 =  [l][c+1] 
bne $t4, 9, v2a
addi $t7, $t7, 1		# contador + 1
v2a:
lw $t4, 64($t3)			# t4 =  [l+1][c] 
bne $t4, 9, v2b
addi $t7, $t7, 1		# contador + 1
v2b:
lw $t4, 68($t3)			# t4 =  [l+1][c+1] 
bne $t4, 9, v2c
addi $t7, $t7, 1		# contador + 1
v2c:
j fimV2ok
#------------------------------------------------------
fimV2ok:
sw $t7, ($t3)			# carrega casa desejada
fimV2:
jr $ra
#####################################################################################################

loopCalculaV2:			
addi $sp,$sp, -4
sw $ra, 0($sp)		# push ra

li $a1, 0		# linha

loopCV2e:
li $a2, 0		# coluna = 0
loopCV2i:
jal calculaV2
addi $a2, $a2, 1	# ++ coluna
bne $a2, 16, loopCV2i	# coluna < 16
addi $a1, $a1, 1	# ++ linha
bne $a1, 16, loopCV2e	# linha < 16

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

printaMatriz:			# recebe endereço em a0
move $v1, $a0			# t0 = endereço
li $a1, 0			# 256
li $a2, 0			# 16
loopPM:
lw $a0, 0($v1)			# a0 = valor = argumento
li $v0, 1			# argumneto vo = 1 printa inteiro
syscall
addi $v1, $v1, 4		# ++ endereço
addi $a2, $a2, 1		# ++ t2 = contador linha
addi $a1, $a1, 1		# ++ t1 = contador final
beq $a2, 16, barranPM
voltaPM:
beq $a1, 256, PMsair 			# 16*16*4
j loopPM
PMsair:
jr $ra

barranPM:
la $a0, espaço123
li $v0, 4			# argumneto vo = 4 printa string
syscall
li $a2, 0
j voltaPM
#####################################################################################################

geraAleatorio:		# retorna v0 = numero entre 0 e 256*4

li $v0, 42			# cÃ³digo 42 gera nÃºmero aleatorio
li $a0, 0			# argumento a0
li $a1, 256		# argumento a1 = limite
syscall			# a0 = nÃºmero aleatÃ³rio
sll $a0, $a0, 2		# a0 * 4
move $v0, $a0

jr $ra
#####################################################################################################

criaMatriz:		# void, argumento a0 = numero de minas

move $a3, $a0		# t0 = numero de minas
li $a2, 9		# cÃ³digo 100 = mina = t7

addi $sp,$sp, -4
sw $ra, 0($sp)		# push ra

loopCM:
jal geraAleatorio		# retorna v0 
#move $v0, $0
lw $a1, matriz($v0)		# t1 = casa[aleatoria]
beq $a1, 9, loopCM		# t1 = 9  ==  colisao

sw $a2, matriz($v0)		# casa[aleatoria] = 100 = mina

addi $a3, $a3, -1		# --t0
beq $a3, $0, fimCM
j loopCM	


fimCM:
lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

drawPreto:			# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

move $a2, $0 			# t1 = preto

addi $a3, $0, 7
li $a1, 0			# preto
loopDP:
jal pintaLinhaCasa		# primeira linha em branco
addi $v0, $v0, 512
move $a0, $v0
addi $a3, $a3, -1
beq $a3, $0, foraDP
j loopDP
foraDP:
lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

drawBranco:			# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra


li $a1, 0xFFFFFFFF		# branco
addi $a3, $0, 7
loopDB:
jal pintaLinhaCasa		# primeira linha em branco
addi $v0, $v0, 512
move $a0, $v0
addi $a3, $a3, -1
beq $a3, $0, foraDB
j loopDB
foraDB:
lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra

#####################################################################################################

bandeiraErrada:			# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a1, 0xFFFFFFFF		# branco
li $a3, 0xff7142 		# cor
li $v1, 0xfd0000 		# vermelho

jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028		# (linha dois da grade 7x7) + 2
				# linha 1
sw $v1, 0($v0)			
addi $v0, $v0, 4					
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 2
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 3
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 5
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2
				# linha 6
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $v1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

bandeira:			# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a1, 0xFFFFFFFF		# branco
li $a3, 0xff7142 		# cor

jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028		# (linha dois da grade 7x7) + 2
				# linha 1
sw $a1, 0($v0)			
addi $v0, $v0, 4					
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 2
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 3
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 5
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2
				# linha 6
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $0, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

mina:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a1, 0xFFFFFFFF		# branco
li $a3, 0x63299c 		# cor

jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028		# (linha dois da grade 7x7) + 2
				# linha 1	
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 2
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 3
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, 484		# (linha dois da grade 7x7) + 2

				# linha 5
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a3, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4
sw $a1, 0($v0)			
addi $v0, $v0, 4

addi $v0, $v0, -32		# (linha dois da grade 7x7) + 2
				# linha 6
move $a0, $v0
jal pintaLinhaCasa		# primeira linha em branco

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

draw8:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a3, 0x616a6b 		# cor
li $a1, 0xFFFFFFFF		# branco

jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028 		# (linha dois da grade 7x7) + 2

addi $v1, $0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

addi $v0, $v0, -32
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		
addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		
addi $v0, $v0, 516
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
sw $a3, 8($v0)			# pinta
sw $a3, 16($v0)			# pinta
addi $v0, $v0, -8
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

addi $v0, $v0, 512
sw $a3, 16($v0)			# pinta
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

draw7:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a3, 0x2e4053 		# cor
li $a1, 0xFFFFFFFF		# t2 = branco

li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028 		# (linha dois da grade 7x7) + 2

addi $v1, $0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

addi $v0, $v0, -32
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		
addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		
addi $v0, $v0, 516
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
sw $a3, 8($v0)			# pinta
sw $a3, 16($v0)			# pinta
addi $v0, $v0, -8
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

draw6:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a3, 0xf72716		# cor
li $a1, 0xFFFFFFFF		# t2 = branco

li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028 		# (linha dois da grade 7x7) + 2

addi $v1, $0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

addi $v0, $v0, -32
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		
addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		
addi $v0, $v0, 516
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
sw $a3, 8($v0)			# pinta
addi $v0, $v0, -8
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

addi $v0, $v0, 512
move $a0, $v0
jal pintaLinhaCasa

addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

draw5:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a3, 0xd85c93		# cor
li $a1, 0xFFFFFFFF		# branco

jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028 		# (linha dois da grade 7x7) + 2

addi $v1, $0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

addi $v0, $v0, -32
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		
addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		
addi $v0, $v0, 516
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, -8
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

addi $v0, $v0, 512
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa

lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

draw4:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a3, 0x2b5dc7		# cor
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028 		# (linha dois da grade 7x7) + 2

addi $v1, $0, 4
loopD4:
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

addi $v0, $v0, 484
addi $v1, $v1, -1
beq $v1, $0, fimD4
j loopD4
fimD4:
addi $v0, $v0, -516
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco
addi $a0, $v0, 512
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco
lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

draw3:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a3, 0xf4d03f 		# cor
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028 		# (linha dois da grade 7x7) + 2

addi $v1, $0, 4
loopD3:
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

addi $v0, $v0, 484
addi $v1, $v1, -1
beq $v1, $0, fimD3
j loopD3
fimD3:
addi $v0, $v0, -516
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco
addi $a0, $v0, 512
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco
lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

draw2:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a3, 0x16a085		# cor
li $a1, 0xFFFFFFFF		# t2 = branco
jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028 		# (linha dois da grade 7x7) + 2

addi $v1, $0, 4
loopD2:
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

addi $v0, $v0, 484
addi $v1, $v1, -1
beq $v1, $0, fimD2
j loopD2
fimD2:
addi $v0, $v0, -516
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco
addi $a0, $v0, 512
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco
lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

draw1:				# recebe first pixel em a0
move $v0, $a0
addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

li $a3, 0x3498db 		# cor

li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco

addi $v0, $v0, 1028 		# (linha dois da grade 7x7) + 2

addi $v1, $0, 4
loopD1:
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a3, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4
sw $a1, 0($v0)			# pinta
addi $v0, $v0, 4

addi $v0, $v0, 484
addi $v1, $v1, -1
beq $v1, $0, fimD1
j loopD1
fimD1:
addi $v0, $v0, -516
move $a0, $v0
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco
addi $a0, $v0, 512
li $a1, 0xFFFFFFFF		# branco
jal pintaLinhaCasa		# primeira linha em branco
lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

pintaLinhaCasa:			# recebe first pixel em a0, e cor em a1
				# 8 x 8 pixels, no caso 7x7, excluindo a grade
				# posicao[m][n] =512*(n+1) + (m+1)*4	
addi $a0, $a0, 512		# PrÃ³xima linha	(primeira linha Ã© da grade)
	
addi $a2, $a0, 28		# a2 = Ãºltima posiÃ§Ã£o da casa
loopPLC:
addi $a0, $a0, 4
sw $a1, 0($a0)			# pinta branco
beq $a0, $a2, fimPLC
j loopPLC
fimPLC:
jr $ra
#####################################################################################################

desenhaGrade:			# recebe first pixel em a0
move $t0, $a0			# t0 = first pixel
and $t1, $zero, $zero		# t1 = 0


addi $sp,$sp, -4
sw $ra, 0($sp)			# push ra

loopGrade:
move $a0, $t0			# a0 = first Pixel of the line 
jal pintaLinha

addi $t2, $0, 7			# t2 = 7
llGrade:									
addi $t0, $t0, 512		# 128 * 4 = 512	PrÃ³xima linha
move $a0, $t0			# a0 = first Pixel of the line 
jal pintaColunaPorLinha

addi $t2, $t2, -1		# --t2
beq $t2, $0, foraGrade
j llGrade

foraGrade:
beq $t0, $s1, fimDG		# a0 == last Pixel of the screen
addi $t0, $t0, 512		# 128 * 4 = 512	PrÃ³xima linha
j loopGrade

fimDG:
lw $ra, 0($sp)			# ra = sp
addi $sp,$sp, 4			# restaura pilha
jr $ra
#####################################################################################################

pintaColunaPorLinha:		# recebe first pixel em a0
lw $a1, vermelho		# a1 = vermelho
addi $a2, $a0, 512		# a2 = Ãºltima posiÃ§Ã£o da linha

loopPCPL:
sw $a1, 0($a0)			# pinta vermelho
addi $a0, $a0, 32		# pula para prÃ³xima coluna
beq $a0, $a2, fimPCPL
j loopPCPL
fimPCPL:

jr $ra
#####################################################################################################

pintaLinha:			# recebe first pixel em a0
lw $a1, vermelho		# a1 = vermelho
addi $a2, $a0, 512		# a2 = Ãºltima posiÃ§Ã£o da linha
loopPL:
sw $a1, 0($a0)			# pinta vermelho
addi $a0, $a0, 4
beq $a0, $a2, fimPL
j loopPL
fimPL:
jr $ra
#####################################################################################################



