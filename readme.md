ForthEx est un projet d'exploration du langage Forth en commencant par la construction d'un petit ordinateur.

Caractéristiques
=================
 * MCU PIC24EP512GP202
 * sortie vidéo monochrome texte 25 lignes de 64 caractères
 * entrée par clavier PS/2
 * mémoire EEPROM SPI 128Ko pour rétention système
 * mémoire RAM SPI  128Ko pour fichier temporaire
 
 Le système Forth sera développé en assembleur et en Forth seulement.
 
Schématique
===========

![circuit principal](/Documentation/forthex_schematic.png)

![interface clavier](/Documentation/forthex_schematic_ps2.png)

[vidéo description matérielle](https://youtu.be/hgAJy2Itfcw)

2017-03-24
==========

À ce moment ci le projet est suffisamment avancé pour utiliser l'ordinateur. L'interpréteur et le compilateur sont complétés. Le support de base pour
utiliser la carte SD est complété ainsi que pour la RAM externe, l'EEPROM externe et la mémoire FLASH libre du PIC24EP512GP202. 

[1er vidéo de l'utilisation de l'ordinateur](https://youtu.be/jwFQXd6zAQ0)
