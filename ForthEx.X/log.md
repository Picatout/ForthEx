2017-06-13
----------
Complété réorganisation de la console.

2017-06-12
----------
Travail sur console, modification sur le fonctionnement de KEY et EMIT pour
les rendre conforme au standard ANSI.

2017-06-11
----------
Travail sur la console. Modifications dans console.s,tvout.s et vt102.s
Renommé GETCUR -> XY?

à faire: repenser le foncionment de la console. EMIT conforme au standard ANSI
sans dépendance d'implémentation. Toutes les fonctions de contrôle doivent-être
extériosées à EMIT.

2017-06-10
----------
Retravailler vt102.s
Vitesse de la console REMOTE améliorée et bogue semble réglé.
Travail dans blockEdit.s et vt102.s

2017-06-09
----------
Modification matériel circuit port rs-232.
Tentative de débogage port rs-232.

2017-06-08
----------
Travail sur console.
Déboger vt102.s, le test suivant plante continuellement. 
: test begin vt-key  vt-emit ; 
Vérification faite j'en suis venu à la conclusion que le problème est matériel.
Je dois modifier le circuit du port rs-232.

2017-06-07
-----------
Travail sur console, réorganisation.
à faire: bogue dans REMOTE CONSOLE, Plante sur lorsque saisie trop rapide.

2017-06-06
----------
Travail pour rendre BLKED fonctionnel sur les 2 consoles LOCAL et REMOTE.


2017-06-05
----------
Suppression de MAXCHAR dans blockEdit.s
Travail dans blockEdit.s
Ajout du mot PROMPT et modifications d'autres définitions.

Travail dans console.s, vt102.s et tvout.s


2017-06-04
----------
Élimination des mots 'SOURCE et #SOURCE dans core.s
Transfert de certains mots de core.s vers d'autres fichiers.
Correction de la documentation de core.s
Correction bogue dans block.s
Correction bogue dans blockedit.s

2017-06-03
----------
Complété boitier de l'ordinateur.
Ajout de ?PRTCHAR et ?QUOTED-CHAR dans strings.s
Modification de ?NUMBER dans strings.s
Modification de BLKFILTER dans block.s
Modification de LC-EMIT dans tvout.s
Modification de VT-EMIT dans vt102.s
Modification de INTERPRET dans interpret.s

2017-06-02
----------
Travail dans dynamem.s et block.s
Ajout du mot BUFFER: à dynamem.s
Ajout de ETYPE dans console.s

2017-06-01
----------
Renommé dossier documentation en docs
réorganisation dossier html
Travail de documentation dans flash.s

2017-05-31
----------
Correcton bogue dans M+
Correction bogue dans FLASH>RAM
Correction bogue dans ?DO
Ajout des mots  F@ FC@L FC@H et IC@


2017-05-30
----------
Travail sur la documentation. Création du fichier presentation.html
Révision du code dans flash.s

2017-05-29
----------
Travail sur docgen.c


2017-05-28
----------
Continuer travail sur BLKED
corrigé bogue dans ASSIGN

2017-05-27
----------
Corrigé mot LOAD dans block.s
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
Modifié le système de coordonnées de l'écran local pour l'uniformiser avec VT102,
c'est à dire que la numérotation des lignes colonnes commence à 1 au lieu de 0.
Le code qui était dans sound.s a été transféré dans hardware.s, il n'y avait qu'une seule définition.

Travail sur l'éditeur d'écran, fichier blockEdit.s


2017-05-21
----------
Travail dans core.s
Réorganisation du code.
Ajout du fichier interpret.s
Ajout du fichier eds.s

2017-05-20
----------
Travail dans tvout.s
Travaile dans strings.s
Travail dans block.s

Transfert des opérateurs booléen et des comparateur dans math.s

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
création de math.s et déplacement de mots de core.s vers math.s
création de tools.s et déplacement de mots de core.s vers tools.s

2017-05-17
----------
Documentation dans core.s
Documentation dans store.s

2017-05-16
----------
Réécriture du mot CFA>NFA
Documentation.

2017-05-15
----------

Travail sur docgen.c et commentaires dans core.s

2017-05-14
----------

Améliorer les commentaires dans les fichiers sources.

2017-05-13
----------

Améliorer les commentaires dans les fichiers sources.

2017-05-11
----------

Commencé l'écriture de l'outil docgen.c


2017-05-11
----------
Écriture de l'outil count.c  pour vérifier que dans tous les fichiers *.s 
le compte des mots du dictionnaire correspond bien la longueur de la chaîne.
Plusieurs erreurs ont été détectées et corrigées.

Renommé TVout.S et font.S en tvout.s et font.s

2017-05-10
----------
déboguer block.s
Correction bogue -TRAILING

2017-05-09
----------
Modifié BAUD dans serial.s, et ajouté des constantes pour les différentes vitesses
supporté. Le mot BAUD maintenant prend comme argument l'une de ces constantes.
La vitesse par défaut est passé à 115200 BAUD.

Travail dans vt102.s

2017-05-08
----------
Ajout de PARSE-NAME.
Fichier vt102.s  ajout de VT-PUTC et modification de VT-EMIT
Réécriture de ACCEPT dans core.s
ajouté CLS dans console.s et renommé CLS dans TVout.s -> VT-PAGE
renommé NEWLINE -> CR dans console.s et renommé CR -> LC-CR dans TVout.s

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
modification à DEFER,DEFER!,DEFER@,IS et ajouté ACTION-OF

2017-05-03
----------
Travail dans block.s

2017-05-02
----------
Travail sur serial.s, abandon de la file en transmission.
Réécriture de __T2Interrupt dans TVout.s

Débogage POSTPONE

Travail sur vt102.s

2017-05-01
----------
Réécriture de WITHIN dans core.s  et renommé MSEC en MS et réécriture du code
pour être conforme au standard ANSI.
Réécriture de USEC
Réécriture de ?COMPILE, maintenant affiche le mot qui a produit l'exception.
Réparation bogue dans LEAVE
Continuer le travail dans vt102.s


2017-04-30
----------
Modifiez encore le générateur vidéo pour vérifier s'il est nécessaire d'inclure
un seuil de noir comme indiqué dans la spécification NTSC. Si ça peut fonctionner
sans seuil de noir je pourrai libéré la broche 12 du MCU.
CONCLUSION: Sans fonctionne très bien sans seuil de noir.

Correction bogue dans serial.s (non résolu à ce moment).
Travail dans vt102.s

2017-04-29
----------
Travail sur __T2Interrupt pour améliorer la synchronisation vidéo.
Travaril sur vt102.s

2017-04-28
----------
Continuation du travail commencé hier sur console.

2017-04-27
----------
Refaire le système console en le basant sur des tables de vecteurs pour chaque
terminal. les tables contiennent le CFA de chaque fonction.
ref: http://lars.nocrew.org/dpans/dpans10.htm#10.6.1


2017-04-26
----------
Les mots définis dans le dictionnaire avec l'attibru F_HIDDEN ont été redéfinis
avec la macro HEADLESS, ce qui a permis de sauver de l'espace et d'épurer le dictionnaire.
R0,S0 et DP0 sont passés de variables système à constantes.

À faire: Repenser le système console pour que le fonctionnement soit identique
         en REMOTE CONSOLE qu'en LOCAL CONSOLE. Modifier le vocabulaire pour
         qu'il soit conforme à DPANS-94: http://lars.nocrew.org/dpans/dpans10.htm#10.6.1
         Il faudrait vectorisé les mots KEY,KEY?,EKEY,EKEY? ainsi que EMIT
         laisser tomber le mot ?KEY qui provient de EFORTH. Modifier le mot LOCAL
         pour qu'il empile la table SCREEN et modifier le mot REMOTE pour qu'il 
         empile la table SERIAL. Fusionner les tables SCREEN et KEYBOARD et renommer
         LCONSOLE. 

2017-04-25
----------
Travail sur block.s

Épuration réorganisation:
    modification à RAM>EE  
    modification à IMG! et IMG@  qui maintenant ne s'applique qu'à la mémoire flash
    du MCU. Supression de la variable BOOTDEV.
    IMG! renommé IMGSAVE
    IMG@ renommé IMGLOAD
    déplacement du code pour IMGSAVE et IMGSTORE dans flash.s
    mot OK n'est plus dans le dictionnaire est maintenant HEADLESS.

2017-04-23/24
----------
Modification au générateur vidéo pour ajouter un seuil noir en utilisant OC4.

Création et travail sur block.s
Retiré eefs.s du projet.


2017-04-22
----------
Épuration: suppression de FREE dans hardware.s
           suppression de FREEHEAD, USEDHEAD, LNKSWAP, BSORT, SORTLIST, BMERGE,
                          HDEFRAG dans dynamem.s

Renommé BLKFREE -> FREE dans dynamem.s
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
Modification à UD.

à faire: déboguer dynamem.s et simplifier mots.
         Compléter LISTSORT et HDEFRAG

2017-04-18
----------
Travail dans dynamem.s


2017-04-17
----------
Travail dans dynamem.s


2017-04-16
----------
Création et travail dans eefs.s et strings.s

2017-04-15
----------
Travail sur ed.s
Ajout mot MARKER dans fichier core.s
Création du fichier dynamem.s pour développement ultérieur.

2017-04-14
----------
Travail sur ed.s
Création du fichier fat8.s, plus tard j'aurai besoin d'un système de fichier
pour l'EEPROM 25LC1024 pour conserver les fichiers créés dans l'éditeur.

2017-04-13
----------
Correction bogue dans firmware ps2_rs232
Travail sur ed.s

2017-04-12
----------

Correction bogue dans SCRCHAR
Création fichiers ed.s et vt102.s


2017-04-11
----------
Déboguage: autochargement ne fonctionnais plus.
    La valeur d'initialisation de bootdev_init était incorrecte.
    ERASEROWS avait un bogue régressif suite au modifications d'hier.

À faire: Cet ordinateur a besoin d'un éditeur de texte et d'un moyen de
         sauvegarder et charger des fichiers texte pour réédition ou exécution.

2017-04-10
----------
retravaillé accès périphériques en créant des descripteurs de périphiriques
Ajout TBL@ et TBL! dans fichier core.s
Travail dans store.s
Renommé:  BOOT -> IMG@ et >BOOT -> IMG!

2017-04-08
----------
Corriger bogue dans TONE
Modification à _WARM dans hardware.s

2017-04-07
----------
Mise à jour schématique
Modification à BOOT, protection contre les images passées date. Lorsque le système
est mis à jour les images sauvegardées avant cette mise à jour sont invalides.

2017-04-06
----------
Travail dans serial.s
Modificcation au projet ps_rs232 pour que la combinaison CTRL_x où x est une 
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

