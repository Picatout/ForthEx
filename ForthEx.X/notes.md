2017-02-24
==========
Continuation du travail sur la sauvegarde/restauration image BOOT 
Modification de EERASE


2017-02-23
==========
modification des mots ELOAD,ESTORE
ajout des mots BOOT, CLEAR, ?IMG, IMG>
ajout mots BUFADDR, BUFFER!, BUFFERC!, BUFFER@, BUFFERC@

2017-02-22
==========
Supprimer CFILL et réparer FILL
Variable dp0 remplacée par constante dp0 cette valeur ne varie pas.
ajout des mots E@,CE@,ERASE,USAVE,ULOAD
débuté travail sur DSAVE DLOAD

2017-02-21
==========
Déplacer la mémoire viédo à la fin de la mémoire RAM.
Rendre le dictionnaire insensible à la casse en convertissants tous les noms en majuscules.
Suppression du mot code INFLOOP, peut-être créer dans l'interpréteur.
Compléter définition de POSTPONE.
Changer le nom des runtime de s" et ."
cacher certains runtime

2017-02-20
==========
Retravailler mot ?NUMBER pour qu'il soit conforme à la EBNF suivante
ENTIER ::= SIMPLE | DOUBLE
SIMPLE ::= [PREFIXE][SIGNE]{DIGIT}+
DOUBLE ::= [PREFIXE][SIGNE]{DIGIT+['.'|',']}+
PREFIXE ::= '$'|'#'|'%'
SIGNE ::= '-'
DIGIT ::= '0'|'1'...base-1
'-' ::= nombre négatif
'$' ::= base hexadécimale
'#' ::= base décimale
'%' ::= base binaire

2017-02-19
===========
ajout mot M*
retravaillé ?NUMBER pour inclure modificateur de base et entrée nombre double précision
ajout mot ?DOUBLE
nettoyage mots redondants.


2017-02-18
===========
modification au compilateur suppression de NEWEST
écrire et tester DOES> <BUILDS XJUMP (DOES>)


2017-02-16
===========
continuation du travail sur LEAVE
LEAVE complété et testé.
CONSTANT, VARIABLE complété et testé
modification à ABORT pour annuler les effet d'une compilation en cours
ajout du mot EMPTY qui vérifie si le dictionnaire utilisateur est vide.

2017-02-15
===========
testé IF ELSE THEN
testé BEGIN UNTIL
testé BEGIN WHILE REPEAT
écrire et testé CASE OF ENDOF ENDCASE
débute travail sur LEAVE

2017-02-03
==========
Abadon du modèle eForth trop ancien au profit de CamelForth
référence: [Camel forth pour msp430](http://www.camelforth.com/download.php?view.25)

2017-01-23
==========
Création de la branche eForth avec l'intention de recommencher le travail en m'inspirant du document
[eForth guide](http://www.exemark.com/FORTH/eForthOverviewv5.pdf)

premier objectif
----------------
Revisiter la couche d'abstraction matérielle et créer une interface cohérente pour celle-ci. eForth
devra communiquer avec les fonctions BIOS à travers cette interface. 

![diagramme du système](/Documentation/diagramme-système.png)

2017-01-24
==========
Réorganisation majeure du projet. Redéfinitions de macros lié à la création des mots forth. Pour faciliter
la création des liens entre les mots du dictionnaire tous les fichiers doivent-être assemblés en même temps.
J'ai donc créer un fichier **forthex.s** qui inclus les autres fichiers. Les autres fichiers sont retirés du
**makefile** pour éviter un assemblage séparé.

