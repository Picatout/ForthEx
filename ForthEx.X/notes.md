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

