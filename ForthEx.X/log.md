2017-04-06
----------
Travail dans serial.s
modificcation au projet ps_rs232 pour que la combinaison CTRL_x où x est une 
lettre renvoie les même codes que l'émumateur de terminal minicon en mode VT102.
modification à ACCEPT maintenant CTRL_X efface la ligne au lieu de CTRL_BACK

Ajout de CTRL_x pour réentrer la ligne de commande précédente.

2017-04-05
----------
Modification au système pour pouvoir utiliser le port sériel comme console
REMOTE CONSOLE pour transférer la console au port RS-232
LOCAL CONSOLE pour transférer la console au clavier/écran local.
Sur le PC on doit utiliser un émulateur de terminal compatible VT100.

2017-04-04
----------
Modification à ACCEPT dans fichier core.s pour que CTRL-BACKSPACE efface la ligne au complet.
modification à KEYFLILTER dans fichier keyboard.s pour accepter VK_CTRL_BACK.

2017-04-03
----------
include la carte SD dans les périphérique boot.
ajout des mots ?SDCOK, IMG>SDC et SDC>IMG, NSECTOR dans sdcard.s
modfications dans store.s

2017-04-02
----------
modification à SDCREAD et SDCWRITE

2017-04-01
----------
correction bogue dans routine scroll_down, fichier TVout.S

2017-03-28
----------
Documentation du projet:
  * installer sigil et lecture des tutoriels dans l'intention de créer un eBook
    pour le projet.
  * installer FBReader pour la lecture des eBooks.

2017-03-27
----------
ajout division:  UD/MOD  32u/16u -> Q:32u R: 16u
modifié impression des nombres la conversion des nombres est maintenant basé
sur la conversion des entiers doubles. Les entiers simples sont convertis en
entiers double avant d'être imprimés. Les mots suivants ont été ajoutés:
COLFILL D. UD. D.R et UD.R

2017-03-26
----------
travail blog partie 2

2017-03-25
----------
renommé QWARM QCOLD

2017-03-24
----------
Enchassement d'un vidéo dans le fichier readme.md

2017-03-23
-----------
débuter la documentation du projet par la création d'une entrée sur mon blog.


2017-03-22
-----------
mots de base pour carte SD complétées
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
à faire: continuer le développement support de base carte SD.

2017-03-16
----------
travail sur les fonctions de base du périphérique CRC


2017-03-15
----------
ajout messages pour les réinitialisation causé par CTRL-C, MATCH_EXCEPTION et 
STACK_ERROR.
ajouté outils de débogage mots: DEBUG,BREAK et RESUME, variables: RPBREAK ET DBGEN
Modification à QUIT pour extraire la boucle REPL

2017-03-14
----------
tests et nettoyage suite
corrigé longueur nom ?EMPTY
Modifié  CREATE, >BODY 
remplacé RT_CREATE par FETCH_EXEC
ajout d'un redémarrage à chaud avec par CTRL-C.


2017-03-12
----------
Tests et nettoyage 
Suppression du mot  IP! et PACK$
corrigé 2!
corrigé LSHIFT et RSHIFT
Ajout constante MSB=0x8000,  MAX-INT=32767 et MIN-INT= -32768
Ajout CMOVE> et réécriture de CMOVE
 
2017-03-11
----------
Refais le travail de sauvegarde/récupération d'images RAM avec >BOOT et BOOT

2017-03-10
----------
Suppression du mot @EXECUTE
Éliminer _flash_buffer  cette espace RAM EDS fait maintenant partie du heap.
Création d'une section .vars_init pour l'initialisation des variables système et
modfication de VARS_INIT 
Réécrire BOOT et >BOOT pour vectoriser l'opération en fonction du périphérique
utilisé.

2017-03-09
----------
Suite du travail sur flash.s
L'ordinateur Forthex est rendu à un stade d'autonomie qui permet de continuer
à développer le système sans avoir recours à un PC. En effet grâce aux mots
IMG>FLASH et FLASH>IMG il est possible de sauvegarder le travail fait sur l'ordinateur
Forthex dans la mémoire flash du MCU et de la récupérer au démarrage. Mais il y
a encore des améliorations à apporter à ce sytème. Entre autre la possibilité de
choisir le périphérique chargement entre la FLASH du MCU, l'EEPROM externe ou
encore la carte SD. D'ailleurs le support la carte SD est à faire. Pour le moment
j'ai configuré un auto-chargement d'image au démarrage à partir de la mémoire
FLASH. 

2017-03-08
-----------

Renommé  mots T -> TRUE  et F -> FALSE 
ajouté  mot UNUSED 
Modification des mots >BOOT et BOOT pour utiliser le flash drive au lieu de
l'EEPROM externe. Ce qui signifie que le système boot à partir de la mémoire
flash du MCU au lieu de la mémoire EEPROM externe.
Ajouté mots UDREL ?FLIMITS FERASE >FLASH  CALL


2017-03-07
----------
suppression de <BUILDS et XJUMP  mots compilant créer avec CREATE ET DOES>
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
modification à CREATE VARIABLE CONSTANT :

à faire: revoir le système <BUILDS  DOES>  pas correct.

2017-03-02
----------
Réparé SOUND_INIT et TONE
ajouté mots DABS, FM/MOD SM/REM, ?NEGATE
complété tous les mots du core selon ref: [dspan-20xx]http://lars.nocrew.org/forth2012/core.html
excepté ENVIRONMENT?

ajout à core extension:
 .(  0<> 2>R  2R> 2R@


2017-03-01
----------
Ajout des mots CHARS, CHAR+ et CHAR  [CHAR] [']
Modification du mot WORDS: affiche le nombre de mots trouvés dans le dictionnaire
EXIT est maintenant visible.
>> à faire:
     corrigé TONE
     ajouter FM/MOD SM/REM
     relire 6.1.1900 concernant MOVE, CMOVE et CMOVE>

2017-02-28
----------
travail dans store.s

Ajout du mot >BUFFER et modifié  mot PGSAVE pour utiliser >BUFFER
au lieu du code utilisant CMOVE. Contournement du bogue que je n'arrivais
pas à résoudre.

Interpréteur et compilateur complété permettant de d'ajouter des mots à partir
de l'ordinateur forthex lui-même. L'image RAM est sauvegardée dans l'EEPROM
en utilisant le mot >BOOT et restaurée au démarrage avec le mot BOOT.

Ajout du mot FORGET

2017-02-27
----------
Poursuite du débogage de PGSAVE. Toujours pas de solution en vue.
EEWRITE ne fonctionne pas après le CMOVE. Par contre si j'ajoute
DUP,DOT, ou simplement DOTS après CMOVE, EEWRITE fonctionne.
Si j'enlève la copie de la RAM vers le tampon EEWRITE fonctionne.
J'ai beau examiné le code de CMOVE je ne vois pas ce qui induit 
le problème. A la sortie de CMOVE S: est dans le bon état!

2017-02-26
----------
Débogage interface SPI RAM externe et EEPROM
Déblogage de PGSAVE, bug étrange... non résolu

ajout mot FORGET


2017-02-25
----------
Continuation du travail sur >BOOT et BOOT
Ajout UMAX UMIN
modifié wait_wip0

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
Supprimer CFILL et réparer FILL
Variable dp0 remplacée par constante dp0 cette valeur ne varie pas.
ajout des mots E@,CE@,ERASE,USAVE,ULOAD
débuté travail sur DSAVE DLOAD

2017-02-21
----------
Déplacer la mémoire viédo à la fin de la mémoire RAM.
Rendre le dictionnaire insensible à la casse en convertissants tous les noms en majuscules.
Suppression du mot code INFLOOP, peut-être créer dans l'interpréteur.
Compléter définition de POSTPONE.
Changer le nom des runtime de s" et ."
cacher certains runtime

2017-02-20
----------
Retravailler mot ?NUMBER pour qu'il soit conforme à la EBNF suivante
ENTIER ::- SIMPLE | DOUBLE
SIMPLE ::- [PREFIXE][SIGNE]{DIGIT}+
DOUBLE ::- [PREFIXE][SIGNE]{DIGIT+['.'|',']}+
PREFIXE ::- '$'|'#'|'%'
SIGNE ::- '-'
DIGIT ::- '0'|'1'...base-1
'-' ::- nombre négatif
'$' ::- base hexadécimale
'#' ::- base décimale
'%' ::- base binaire

2017-02-19
-----------
ajout mot M*
retravaillé ?NUMBER pour inclure modificateur de base et entrée nombre double précision
ajout mot ?DOUBLE
nettoyage mots redondants.


2017-02-18
-----------
modification au compilateur suppression de NEWEST
écrire et tester DOES> <BUILDS XJUMP (DOES>)


2017-02-16
-----------
continuation du travail sur LEAVE
LEAVE complété et testé.
CONSTANT, VARIABLE complété et testé
modification à ABORT pour annuler les effet d'une compilation en cours
ajout du mot EMPTY qui vérifie si le dictionnaire utilisateur est vide.

2017-02-15
-----------
testé IF ELSE THEN
testé BEGIN UNTIL
testé BEGIN WHILE REPEAT
écrire et testé CASE OF ENDOF ENDCASE
débute travail sur LEAVE

2017-02-03
----------
Abadon du modèle eForth trop ancien au profit de CamelForth
référence: [Camel forth pour msp430](http://www.camelforth.com/download.php?view.25)

2017-01-23
----------
Création de la branche eForth avec l'intention de recommencher le travail en m'inspirant du document
[eForth guide](http://www.exemark.com/FORTH/eForthOverviewv5.pdf)

premier objectif
----------------
Revisiter la couche d'abstraction matérielle et créer une interface cohérente pour celle-ci. eForth
devra communiquer avec les fonctions BIOS à travers cette interface. 

![diagramme du système](/Documentation/diagramme-système.png)

2017-01-24
----------
Réorganisation majeure du projet. Redéfinitions de macros lié à la création des mots forth. Pour faciliter
la création des liens entre les mots du dictionnaire tous les fichiers doivent-être assemblés en même temps.
J'ai donc créer un fichier **forthex.s** qui inclus les autres fichiers. Les autres fichiers sont retirés du
**makefile** pour éviter un assemblage séparé.

