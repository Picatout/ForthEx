\ jeu serpent
\ constantes
128 constant max-len \ longueur maximale du serpent
\ directions deplacement
0 constant east
1 constant south
2 constant west
3 constant north
62 constant play-width \ largeur surface jeu
22 constant play-height \ hauteur surface jeu
2 constant x-offset \ pour affichage
2 constant y-offset \ pour affichage
75 constant speed \ controle vitesse serpent
143 constant ar_left \ fleche a gauche
144 constant ar_right \ fleche a droite

\ variables
variable score \ pointage
variable head \ direction serpent
variable snake-len \ longueur serpent
variable food \ localisation pastille nourriture
variable tail \ localisation queue serpent

\ vector permet de creer des variables tableau 1D
: vector create cells allot does> swap cells + ;
\ variables tableaux
4 vector c-head \ contient les caracteres de tete serpent
max-len vector snake \ le corps du serpent

\ initialisation c-head
'<' east c-head ! \ tete direction est
'W' south c-head ! \ tete direction sud
'>' west c-head ! \ tete direction ouest
'V' north c-head ! \ tete direction nord


\ fonctions graphiques
\ conversion entier non signe vers couple {x,y}
: ucoord>xy ( u -- x y )
   256 /mod ;

\ conversion couple {x,y} vers ucoord
: xy>ucoord ( x y -- u )
   256 * + ;

\ dessine un pixel  c caractere {x,y} coord.
: draw-pixel ( c x y -- )
   y-offset + swap x-offset + swap at-xy emit ;

\ dessine une pastille u=ucoord
: draw-ring ( u -- )
   true b/w
   'O' swap ucoord>xy draw-pixel false b/w ;

\ dessine les bandes de l'arene
: draw-walls ( -- )
   cls 1 whiteln 24 whiteln
   24 2 do 1 i at-xy space 64 i at-xy space loop false b/w ;

\ dessine le serpent
: draw-snake ( -- )
   head @ c-head @ 0 snake @ ucoord>xy draw-pixel
   snake-len @ 1 do i snake @ draw-ring loop ;

\ affiche le status
: status ( -- )
   true b/w 1 1 at-xy ." SCORE:" score @ .
   16 1 at-xy ." LENGTH:" snake-len @ . false b/w ;

\ Lors de la creation d'une patille il faut valider
\ qu'elle ne superpose pas au serpent.
: valid-food? ( u -- f )
   true swap snake-len @ 0 do
       i snake @ over = if swap drop false swap leave then
       loop drop ;

\ creation d'une pastille de nourriture
: new-food ( -- )
   0 begin drop rand abs play-width mod \ x
       rand abs play-height mod \ y
       xy>ucoord dup valid-food? until food ! ;

\ verifie si le serpent se mord.
: snake-bite? ( -- f )
   false 0 snake @  snake-len @ 1 do
       i snake @ over = if swap drop true swap leave then
       loop drop ;

\ retourne un flag pour chaque coordonnee
\ vrai si le long d'un mur.
: borders? ( u1 -- fy fx )
   ucoord>xy dup 0= swap play-height 1- = or
   swap dup 0= swap play-width 1- = or ;

\ ajuste SCORE
: score+ ( -- )
   1 food @ borders?
   if swap 2* swap then
   if 2* then
   score +! -1 food ! ;

\ rallonge le serpent
: snake+ ( -- )
   snake-len dup >r @ dup 1+ r> ! tail @  swap snake ! ;

\ dessine pastille nourriture
: draw-food  food @ draw-ring ;

\ deplace le serpent
: move-snake ( -- )
   0 snake @ dup ucoord>xy
   head @ case
       east of swap 1+ swap endof
       south of 1+ endof
       west of swap 1- 255 and swap endof
       north of 1- endof
       endcase xy>ucoord
   0 snake !
   snake-len @ 1 do i snake dup >r @ swap r> !
   loop dup tail !
   bl swap ucoord>xy draw-pixel draw-snake ;

\ verification collision avec mur
: wall-bang? ( -- f )
   0 snake @ ucoord>xy  play-height 1- u>
   swap  play-width 1- u> or ;

\ verification collision
: collision? ( -- f )
   snake-bite? wall-bang? or ;

 \ initialisation du serpent
: snake-init ( -- )
   east head ! -1 food !
   play-width 2/ play-height 2/ snake-len @ 0 do
   2dup xy>ucoord i snake ! swap 1- swap loop 2drop ;

\ lecture clavier touche 'q' quitte le jeu.
: game-exit? ( -- f )
   ekey? if ekey case
   ar_left of head @ 1- 3 and head ! false endof
   ar_right of head @ 1+ 3 and head ! false endof
   'q' of true endof
   'Q' of true endof
   >r false r>
   endcase else false then ;

\ pastille mangee?
: eaten? ( -- f )
   0 snake @ food @ = ;

\ boucle du jeu
: game-loop ( -- )
  begin
  speed ms
  status food @ -1 = if new-food then draw-food
  game-exit? ?dup 0= if
  move-snake eaten? if score+  snake+ false else
  collision? then then until ;

\ initialisation du jeu
: game-init ( -- )
   srand 4 snake-len ! 0 score !
   snake-init draw-walls ;

\ partie terminee
: game-over? ( -- f )
   1 24 at-xy ." game over <Q> leave" key 'q' = ;

\ lance le jeux.
: snake-run ( -- )
   begin game-init game-loop game-over?  until cls ;

