2017-06-13
----------
Compl�t� r�organisation de la console.

2017-06-12
----------
Travail sur console, modification sur le fonctionnement de KEY et EMIT pour
les rendre conforme au standard ANSI.

2017-06-11
----------
Travail sur la console. Modifications dans console.s,tvout.s et vt102.s
Renomm� GETCUR -> XY?

� faire: repenser le foncionment de la console. EMIT conforme au standard ANSI
sans d�pendance d'impl�mentation. Toutes les fonctions de contr�le doivent-�tre
ext�rios�es � EMIT.

2017-06-10
----------
Retravailler vt102.s
Vitesse de la console REMOTE am�lior�e et bogue semble r�gl�.
Travail dans blockEdit.s et vt102.s

2017-06-09
----------
Modification mat�riel circuit port rs-232.
Tentative de d�bogage port rs-232.

2017-06-08
----------
Travail sur console.
D�boger vt102.s, le test suivant plante continuellement. 
: test begin vt-key  vt-emit ; 
V�rification faite j'en suis venu � la conclusion que le probl�me est mat�riel.
Je dois modifier le circuit du port rs-232.

2017-06-07
-----------
Travail sur console, r�organisation.
� faire: bogue dans REMOTE CONSOLE, Plante sur lorsque saisie trop rapide.

2017-06-06
----------
Travail pour rendre BLKED fonctionnel sur les 2 consoles LOCAL et REMOTE.


2017-06-05
----------
Suppression de MAXCHAR dans blockEdit.s
Travail dans blockEdit.s
Ajout du mot PROMPT et modifications d'autres d�finitions.

Travail dans console.s, vt102.s et tvout.s


2017-06-04
----------
�limination des mots 'SOURCE et #SOURCE dans core.s
Transfert de certains mots de core.s vers d'autres fichiers.
Correction de la documentation de core.s
Correction bogue dans block.s
Correction bogue dans blockedit.s

2017-06-03
----------
Compl�t� boitier de l'ordinateur.
Ajout de ?PRTCHAR et ?QUOTED-CHAR dans strings.s
Modification de ?NUMBER dans strings.s
Modification de BLKFILTER dans block.s
Modification de LC-EMIT dans tvout.s
Modification de VT-EMIT dans vt102.s
Modification de INTERPRET dans interpret.s

2017-06-02
----------
Travail dans dynamem.s et block.s
Ajout du mot BUFFER: � dynamem.s
Ajout de ETYPE dans console.s

2017-06-01
----------
Renomm� dossier documentation en docs
r�organisation dossier html
Travail de documentation dans flash.s

2017-05-31
----------
Correcton bogue dans M+
Correction bogue dans FLASH>RAM
Correction bogue dans ?DO
Ajout des mots  F@ FC@L FC@H et IC@


2017-05-30
----------
Travail sur la documentation. Cr�ation du fichier presentation.html
R�vision du code dans flash.s

2017-05-29
----------
Travail sur docgen.c


2017-05-28
----------
Continuer travail sur BLKED
corrig� bogue dans ASSIGN

2017-05-27
----------
Corrig� mot LOAD dans block.s
Travail sur BLKED

2017-05-26
----------
Travail dans vt102.s et blockEdit.s

2017-05-24
----------
Modification dans tvout.s, ajout de LC-B/W.
Modification dans vt102.s, ajout de VT-B/W.
Modification dans console.s ajout de B/W et ajout de la fonction FN_B/W dans les
tables LCCONS et SERCONS.

Travail dans blockEdit.s

2017-05-23
----------
Travail sur BLKED

2017-05-22
----------
Modifi� le syst�me de coordonn�es de l'�cran local pour l'uniformiser avec VT102,
c'est � dire que la num�rotation des lignes colonnes commence � 1 au lieu de 0.
Le code qui �tait dans sound.s a �t� transf�r� dans hardware.s, il n'y avait qu'une seule d�finition.

Travail sur l'�diteur d'�cran, fichier blockEdit.s


2017-05-21
----------
Travail dans core.s
R�organisation du code.
Ajout du fichier interpret.s
Ajout du fichier eds.s

2017-05-20
----------
Travail dans tvout.s
Travaile dans strings.s
Travail dans block.s

Transfert des op�rateurs bool�en et des comparateur dans math.s

2017-05-19
----------
Travail dans strings.s
Travail dans sdcard.s
Travail dans console.s
Travail dans vt102.s
Travail dans block.s

2017-05-18
----------
Documentation dans keyboard.s
Documentation dans dynamem.s
Documentation dans serial.s
Documentation dans hardware.s
Documentation dans flash.s
Documentation dans sound.s
Ajouts de mots dans strings.s
cr�ation de math.s et d�placement de mots de core.s vers math.s
cr�ation de tools.s et d�placement de mots de core.s vers tools.s

2017-05-17
----------
Documentation dans core.s
Documentation dans store.s

2017-05-16
----------
R��criture du mot CFA>NFA
Documentation.

2017-05-15
----------

Travail sur docgen.c et commentaires dans core.s

2017-05-14
----------

Am�liorer les commentaires dans les fichiers sources.

2017-05-13
----------

Am�liorer les commentaires dans les fichiers sources.

2017-05-11
----------

Commenc� l'�criture de l'outil docgen.c


2017-05-11
----------
�criture de l'outil count.c  pour v�rifier que dans tous les fichiers *.s 
le compte des mots du dictionnaire correspond bien la longueur de la cha�ne.
Plusieurs erreurs ont �t� d�tect�es et corrig�es.

Renomm� TVout.S et font.S en tvout.s et font.s

2017-05-10
----------
d�boguer block.s
Correction bogue -TRAILING

2017-05-09
----------
Modifi� BAUD dans serial.s, et ajout� des constantes pour les diff�rentes vitesses
support�. Le mot BAUD maintenant prend comme argument l'une de ces constantes.
La vitesse par d�faut est pass� � 115200 BAUD.

Travail dans vt102.s

2017-05-08
----------
Ajout de PARSE-NAME.
Fichier vt102.s  ajout de VT-PUTC et modification de VT-EMIT
R��criture de ACCEPT dans core.s
ajout� CLS dans console.s et renomm� CLS dans TVout.s -> VT-PAGE
renomm� NEWLINE -> CR dans console.s et renomm� CR -> LC-CR dans TVout.s

2017-05-07
----------
Travail sur block.s

2017-05-06
----------
Travail sur block.s

A faire: revoir PARSE, PARSE-NAME,INTERPET,EVALUATE,QUIT

2017-05-05
----------
Travail sur blocks.s
Modifications dans store.s et sdcard.s

2017-05-04
----------
modification � DEFER,DEFER!,DEFER@,IS et ajout� ACTION-OF

2017-05-03
----------
Travail dans block.s

2017-05-02
----------
Travail sur serial.s, abandon de la file en transmission.
R��criture de __T2Interrupt dans TVout.s

D�bogage POSTPONE

Travail sur vt102.s

2017-05-01
----------
R��criture de WITHIN dans core.s  et renomm� MSEC en MS et r��criture du code
pour �tre conforme au standard ANSI.
R��criture de USEC
R��criture de ?COMPILE, maintenant affiche le mot qui a produit l'exception.
R�paration bogue dans LEAVE
Continuer le travail dans vt102.s


2017-04-30
----------
Modifiez encore le g�n�rateur vid�o pour v�rifier s'il est n�cessaire d'inclure
un seuil de noir comme indiqu� dans la sp�cification NTSC. Si �a peut fonctionner
sans seuil de noir je pourrai lib�r� la broche 12 du MCU.
CONCLUSION: Sans fonctionne tr�s bien sans seuil de noir.

Correction bogue dans serial.s (non r�solu � ce moment).
Travail dans vt102.s

2017-04-29
----------
Travail sur __T2Interrupt pour am�liorer la synchronisation vid�o.
Travaril sur vt102.s

2017-04-28
----------
Continuation du travail commenc� hier sur console.

2017-04-27
----------
Refaire le syst�me console en le basant sur des tables de vecteurs pour chaque
terminal. les tables contiennent le CFA de chaque fonction.
ref: http://lars.nocrew.org/dpans/dpans10.htm#10.6.1


2017-04-26
----------
Les mots d�finis dans le dictionnaire avec l'attibru F_HIDDEN ont �t� red�finis
avec la macro HEADLESS, ce qui a permis de sauver de l'espace et d'�purer le dictionnaire.
R0,S0 et DP0 sont pass�s de variables syst�me � constantes.

� faire: Repenser le syst�me console pour que le fonctionnement soit identique
         en REMOTE CONSOLE qu'en LOCAL CONSOLE. Modifier le vocabulaire pour
         qu'il soit conforme � DPANS-94: http://lars.nocrew.org/dpans/dpans10.htm#10.6.1
         Il faudrait vectoris� les mots KEY,KEY?,EKEY,EKEY? ainsi que EMIT
         laisser tomber le mot ?KEY qui provient de EFORTH. Modifier le mot LOCAL
         pour qu'il empile la table SCREEN et modifier le mot REMOTE pour qu'il 
         empile la table SERIAL. Fusionner les tables SCREEN et KEYBOARD et renommer
         LCONSOLE. 

2017-04-25
----------
Travail sur block.s

�puration r�organisation:
    modification � RAM>EE  
    modification � IMG! et IMG@  qui maintenant ne s'applique qu'� la m�moire flash
    du MCU. Supression de la variable BOOTDEV.
    IMG! renomm� IMGSAVE
    IMG@ renomm� IMGLOAD
    d�placement du code pour IMGSAVE et IMGSTORE dans flash.s
    mot OK n'est plus dans le dictionnaire est maintenant HEADLESS.

2017-04-23/24
----------
Modification au g�n�rateur vid�o pour ajouter un seuil noir en utilisant OC4.

Cr�ation et travail sur block.s
Retir� eefs.s du projet.


2017-04-22
----------
�puration: suppression de FREE dans hardware.s
           suppression de FREEHEAD, USEDHEAD, LNKSWAP, BSORT, SORTLIST, BMERGE,
                          HDEFRAG dans dynamem.s

Renomm� BLKFREE -> FREE dans dynamem.s
Ajout de ?>LIST dans dynamem.s

2017-04-21
----------
Travail sur dynamem.s
Test dynamem.s

2017-04-20
----------
Travail dans dynamem.s

2017-04-19
----------
Travail dans dynamem.s

Ajout RDROP
Modification � UD.

� faire: d�boguer dynamem.s et simplifier mots.
         Compl�ter LISTSORT et HDEFRAG

2017-04-18
----------
Travail dans dynamem.s


2017-04-17
----------
Travail dans dynamem.s


2017-04-16
----------
Cr�ation et travail dans eefs.s et strings.s

2017-04-15
----------
Travail sur ed.s
Ajout mot MARKER dans fichier core.s
Cr�ation du fichier dynamem.s pour d�veloppement ult�rieur.

2017-04-14
----------
Travail sur ed.s
Cr�ation du fichier fat8.s, plus tard j'aurai besoin d'un syst�me de fichier
pour l'EEPROM 25LC1024 pour conserver les fichiers cr��s dans l'�diteur.

2017-04-13
----------
Correction bogue dans firmware ps2_rs232
Travail sur ed.s

2017-04-12
----------

Correction bogue dans SCRCHAR
Cr�ation fichiers ed.s et vt102.s


2017-04-11
----------
D�boguage: autochargement ne fonctionnais plus.
    La valeur d'initialisation de bootdev_init �tait incorrecte.
    ERASEROWS avait un bogue r�gressif suite au modifications d'hier.

� faire: Cet ordinateur a besoin d'un �diteur de texte et d'un moyen de
         sauvegarder et charger des fichiers texte pour r��dition ou ex�cution.

2017-04-10
----------
retravaill� acc�s p�riph�riques en cr�ant des descripteurs de p�riphiriques
Ajout TBL@ et TBL! dans fichier core.s
Travail dans store.s
Renomm�:  BOOT -> IMG@ et >BOOT -> IMG!

2017-04-08
----------
Corriger bogue dans TONE
Modification � _WARM dans hardware.s

2017-04-07
----------
Mise � jour sch�matique
Modification � BOOT, protection contre les images pass�es date. Lorsque le syst�me
est mis � jour les images sauvegard�es avant cette mise � jour sont invalides.

2017-04-06
----------
Travail dans serial.s
Modificcation au projet ps_rs232 pour que la combinaison CTRL_x o� x est une 
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

