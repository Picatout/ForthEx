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

