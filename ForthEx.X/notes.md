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
Supprimer CFILL et r�parer FILL
Variable dp0 remplac�e par constante dp0 cette valeur ne varie pas.
ajout des mots E@,CE@,ERASE,USAVE,ULOAD
d�but� travail sur DSAVE DLOAD

2017-02-21
==========
D�placer la m�moire vi�do � la fin de la m�moire RAM.
Rendre le dictionnaire insensible � la casse en convertissants tous les noms en majuscules.
Suppression du mot code INFLOOP, peut-�tre cr�er dans l'interpr�teur.
Compl�ter d�finition de POSTPONE.
Changer le nom des runtime de s" et ."
cacher certains runtime

2017-02-20
==========
Retravailler mot ?NUMBER pour qu'il soit conforme � la EBNF suivante
ENTIER ::= SIMPLE | DOUBLE
SIMPLE ::= [PREFIXE][SIGNE]{DIGIT}+
DOUBLE ::= [PREFIXE][SIGNE]{DIGIT+['.'|',']}+
PREFIXE ::= '$'|'#'|'%'
SIGNE ::= '-'
DIGIT ::= '0'|'1'...base-1
'-' ::= nombre n�gatif
'$' ::= base hexad�cimale
'#' ::= base d�cimale
'%' ::= base binaire

2017-02-19
===========
ajout mot M*
retravaill� ?NUMBER pour inclure modificateur de base et entr�e nombre double pr�cision
ajout mot ?DOUBLE
nettoyage mots redondants.


2017-02-18
===========
modification au compilateur suppression de NEWEST
�crire et tester DOES> <BUILDS XJUMP (DOES>)


2017-02-16
===========
continuation du travail sur LEAVE
LEAVE compl�t� et test�.
CONSTANT, VARIABLE compl�t� et test�
modification � ABORT pour annuler les effet d'une compilation en cours
ajout du mot EMPTY qui v�rifie si le dictionnaire utilisateur est vide.

2017-02-15
===========
test� IF ELSE THEN
test� BEGIN UNTIL
test� BEGIN WHILE REPEAT
�crire et test� CASE OF ENDOF ENDCASE
d�bute travail sur LEAVE

2017-02-03
==========
Abadon du mod�le eForth trop ancien au profit de CamelForth
r�f�rence: [Camel forth pour msp430](http://www.camelforth.com/download.php?view.25)

2017-01-23
==========
Cr�ation de la branche eForth avec l'intention de recommencher le travail en m'inspirant du document
[eForth guide](http://www.exemark.com/FORTH/eForthOverviewv5.pdf)

premier objectif
----------------
Revisiter la couche d'abstraction mat�rielle et cr�er une interface coh�rente pour celle-ci. eForth
devra communiquer avec les fonctions BIOS � travers cette interface. 

![diagramme du syst�me](/Documentation/diagramme-syst�me.png)

2017-01-24
==========
R�organisation majeure du projet. Red�finitions de macros li� � la cr�ation des mots forth. Pour faciliter
la cr�ation des liens entre les mots du dictionnaire tous les fichiers doivent-�tre assembl�s en m�me temps.
J'ai donc cr�er un fichier **forthex.s** qui inclus les autres fichiers. Les autres fichiers sont retir�s du
**makefile** pour �viter un assemblage s�par�.

