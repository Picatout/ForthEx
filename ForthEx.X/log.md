2017-04-06
----------
Travail dans serial.s
modificcation au projet ps_rs232 pour que la combinaison CTRL_x o� x est une 
lettre renvoie les m�me codes que l'�mumateur de terminal minicon en mode VT102.
modification � ACCEPT maintenant CTRL_X efface la ligne au lieu de CTRL_BACK

Ajout de CTRL_x pour r�entrer la ligne de commande pr�c�dente.

2017-04-05
----------
Modification au syst�me pour pouvoir utiliser le port s�riel comme console
REMOTE CONSOLE pour transf�rer la console au port RS-232
LOCAL CONSOLE pour transf�rer la console au clavier/�cran local.
Sur le PC on doit utiliser un �mulateur de terminal compatible VT100.

2017-04-04
----------
Modification � ACCEPT dans fichier core.s pour que CTRL-BACKSPACE efface la ligne au complet.
modification � KEYFLILTER dans fichier keyboard.s pour accepter VK_CTRL_BACK.

2017-04-03
----------
include la carte SD dans les p�riph�rique boot.
ajout des mots ?SDCOK, IMG>SDC et SDC>IMG, NSECTOR dans sdcard.s
modfications dans store.s

2017-04-02
----------
modification � SDCREAD et SDCWRITE

2017-04-01
----------
correction bogue dans routine scroll_down, fichier TVout.S

2017-03-28
----------
Documentation du projet:
  * installer sigil et lecture des tutoriels dans l'intention de cr�er un eBook
    pour le projet.
  * installer FBReader pour la lecture des eBooks.

2017-03-27
----------
ajout division:  UD/MOD  32u/16u -> Q:32u R: 16u
modifi� impression des nombres la conversion des nombres est maintenant bas�
sur la conversion des entiers doubles. Les entiers simples sont convertis en
entiers double avant d'�tre imprim�s. Les mots suivants ont �t� ajout�s:
COLFILL D. UD. D.R et UD.R

2017-03-26
----------
travail blog partie 2

2017-03-25
----------
renomm� QWARM QCOLD

2017-03-24
----------
Enchassement d'un vid�o dans le fichier readme.md

2017-03-23
-----------
d�buter la documentation du projet par la cr�ation d'une entr�e sur mon blog.


2017-03-22
-----------
mots de base pour carte SD compl�t�es
SDCINIT,SDREAD, SDWRITE,?SDC 

2017-03-21
----------
travail sur interface carte SD

2017-03-20
----------
travail interface carte SD 

2017-03-17
----------
travail sur CRC
ajout mot NOT qui inverse la valeur logique. i.e. 0 -> -1, n<>0 -> 0
� faire: continuer le d�veloppement support de base carte SD.

2017-03-16
----------
travail sur les fonctions de base du p�riph�rique CRC


2017-03-15
----------
ajout messages pour les r�initialisation caus� par CTRL-C, MATCH_EXCEPTION et 
STACK_ERROR.
ajout� outils de d�bogage mots: DEBUG,BREAK et RESUME, variables: RPBREAK ET DBGEN
Modification � QUIT pour extraire la boucle REPL

2017-03-14
----------
tests et nettoyage suite
corrig� longueur nom ?EMPTY
Modifi�  CREATE, >BODY 
remplac� RT_CREATE par FETCH_EXEC
ajout d'un red�marrage � chaud avec par CTRL-C.


2017-03-12
----------
Tests et nettoyage 
Suppression du mot  IP! et PACK$
corrig� 2!
corrig� LSHIFT et RSHIFT
Ajout constante MSB=0x8000,  MAX-INT=32767 et MIN-INT= -32768
Ajout CMOVE> et r��criture de CMOVE
 
2017-03-11
----------
Refais le travail de sauvegarde/r�cup�ration d'images RAM avec >BOOT et BOOT

2017-03-10
----------
Suppression du mot @EXECUTE
�liminer _flash_buffer  cette espace RAM EDS fait maintenant partie du heap.
Cr�ation d'une section .vars_init pour l'initialisation des variables syst�me et
modfication de VARS_INIT 
R��crire BOOT et >BOOT pour vectoriser l'op�ration en fonction du p�riph�rique
utilis�.

2017-03-09
----------
Suite du travail sur flash.s
L'ordinateur Forthex est rendu � un stade d'autonomie qui permet de continuer
� d�velopper le syst�me sans avoir recours � un PC. En effet gr�ce aux mots
IMG>FLASH et FLASH>IMG il est possible de sauvegarder le travail fait sur l'ordinateur
Forthex dans la m�moire flash du MCU et de la r�cup�rer au d�marrage. Mais il y
a encore des am�liorations � apporter � ce syt�me. Entre autre la possibilit� de
choisir le p�riph�rique chargement entre la FLASH du MCU, l'EEPROM externe ou
encore la carte SD. D'ailleurs le support la carte SD est � faire. Pour le moment
j'ai configur� un auto-chargement d'image au d�marrage � partir de la m�moire
FLASH. 

2017-03-08
-----------

Renomm�  mots T -> TRUE  et F -> FALSE 
ajout�  mot UNUSED 
Modification des mots >BOOT et BOOT pour utiliser le flash drive au lieu de
l'EEPROM externe. Ce qui signifie que le syst�me boot � partir de la m�moire
flash du MCU au lieu de la m�moire EEPROM externe.
Ajout� mots UDREL ?FLIMITS FERASE >FLASH  CALL


2017-03-07
----------
suppression de <BUILDS et XJUMP  mots compilant cr�er avec CREATE ET DOES>
ajout :NONAME


2017-03-05
----------
Ajout de :NONAME

2017-03-04
----------
Ajout de DEFER DEFER! DEFER@  IS  ?WORD

2017-03-03
----------
Suppression du mot [COMPILE]
Ajout de ?DO  C"
modification � CREATE VARIABLE CONSTANT :

� faire: revoir le syst�me <BUILDS  DOES>  pas correct.

2017-03-02
----------
R�par� SOUND_INIT et TONE
ajout� mots DABS, FM/MOD SM/REM, ?NEGATE
compl�t� tous les mots du core selon ref: [dspan-20xx]http://lars.nocrew.org/forth2012/core.html
except� ENVIRONMENT?

ajout � core extension:
 .(  0<> 2>R  2R> 2R@


2017-03-01
----------
Ajout des mots CHARS, CHAR+ et CHAR  [CHAR] [']
Modification du mot WORDS: affiche le nombre de mots trouv�s dans le dictionnaire
EXIT est maintenant visible.
>> � faire:
     corrig� TONE
     ajouter FM/MOD SM/REM
     relire 6.1.1900 concernant MOVE, CMOVE et CMOVE>

2017-02-28
----------
travail dans store.s

Ajout du mot >BUFFER et modifi�  mot PGSAVE pour utiliser >BUFFER
au lieu du code utilisant CMOVE. Contournement du bogue que je n'arrivais
pas � r�soudre.

Interpr�teur et compilateur compl�t� permettant de d'ajouter des mots � partir
de l'ordinateur forthex lui-m�me. L'image RAM est sauvegard�e dans l'EEPROM
en utilisant le mot >BOOT et restaur�e au d�marrage avec le mot BOOT.

Ajout du mot FORGET

2017-02-27
----------
Poursuite du d�bogage de PGSAVE. Toujours pas de solution en vue.
EEWRITE ne fonctionne pas apr�s le CMOVE. Par contre si j'ajoute
DUP,DOT, ou simplement DOTS apr�s CMOVE, EEWRITE fonctionne.
Si j'enl�ve la copie de la RAM vers le tampon EEWRITE fonctionne.
J'ai beau examin� le code de CMOVE je ne vois pas ce qui induit 
le probl�me. A la sortie de CMOVE S: est dans le bon �tat!

2017-02-26
----------
D�bogage interface SPI RAM externe et EEPROM
D�blogage de PGSAVE, bug �trange... non r�solu

ajout mot FORGET


2017-02-25
----------
Continuation du travail sur >BOOT et BOOT
Ajout UMAX UMIN
modifi� wait_wip0

2017-02-24
----------
Continuation du travail sur la sauvegarde/restauration image BOOT 
Modification de EERASE


2017-02-23
----------
modification des mots ELOAD,ESTORE
ajout des mots BOOT, CLEAR, ?IMG, IMG>
ajout mots BUFADDR, BUFFER!, BUFFERC!, BUFFER@, BUFFERC@

2017-02-22
----------
Supprimer CFILL et r�parer FILL
Variable dp0 remplac�e par constante dp0 cette valeur ne varie pas.
ajout des mots E@,CE@,ERASE,USAVE,ULOAD
d�but� travail sur DSAVE DLOAD

2017-02-21
----------
D�placer la m�moire vi�do � la fin de la m�moire RAM.
Rendre le dictionnaire insensible � la casse en convertissants tous les noms en majuscules.
Suppression du mot code INFLOOP, peut-�tre cr�er dans l'interpr�teur.
Compl�ter d�finition de POSTPONE.
Changer le nom des runtime de s" et ."
cacher certains runtime

2017-02-20
----------
Retravailler mot ?NUMBER pour qu'il soit conforme � la EBNF suivante
ENTIER ::- SIMPLE | DOUBLE
SIMPLE ::- [PREFIXE][SIGNE]{DIGIT}+
DOUBLE ::- [PREFIXE][SIGNE]{DIGIT+['.'|',']}+
PREFIXE ::- '$'|'#'|'%'
SIGNE ::- '-'
DIGIT ::- '0'|'1'...base-1
'-' ::- nombre n�gatif
'$' ::- base hexad�cimale
'#' ::- base d�cimale
'%' ::- base binaire

2017-02-19
-----------
ajout mot M*
retravaill� ?NUMBER pour inclure modificateur de base et entr�e nombre double pr�cision
ajout mot ?DOUBLE
nettoyage mots redondants.


2017-02-18
-----------
modification au compilateur suppression de NEWEST
�crire et tester DOES> <BUILDS XJUMP (DOES>)


2017-02-16
-----------
continuation du travail sur LEAVE
LEAVE compl�t� et test�.
CONSTANT, VARIABLE compl�t� et test�
modification � ABORT pour annuler les effet d'une compilation en cours
ajout du mot EMPTY qui v�rifie si le dictionnaire utilisateur est vide.

2017-02-15
-----------
test� IF ELSE THEN
test� BEGIN UNTIL
test� BEGIN WHILE REPEAT
�crire et test� CASE OF ENDOF ENDCASE
d�bute travail sur LEAVE

2017-02-03
----------
Abadon du mod�le eForth trop ancien au profit de CamelForth
r�f�rence: [Camel forth pour msp430](http://www.camelforth.com/download.php?view.25)

2017-01-23
----------
Cr�ation de la branche eForth avec l'intention de recommencher le travail en m'inspirant du document
[eForth guide](http://www.exemark.com/FORTH/eForthOverviewv5.pdf)

premier objectif
----------------
Revisiter la couche d'abstraction mat�rielle et cr�er une interface coh�rente pour celle-ci. eForth
devra communiquer avec les fonctions BIOS � travers cette interface. 

![diagramme du syst�me](/Documentation/diagramme-syst�me.png)

2017-01-24
----------
R�organisation majeure du projet. Red�finitions de macros li� � la cr�ation des mots forth. Pour faciliter
la cr�ation des liens entre les mots du dictionnaire tous les fichiers doivent-�tre assembl�s en m�me temps.
J'ai donc cr�er un fichier **forthex.s** qui inclus les autres fichiers. Les autres fichiers sont retir�s du
**makefile** pour �viter un assemblage s�par�.

