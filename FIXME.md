# Mode rapide

- [x] Le drag and drop dans le mode facile n'est pas très UI friendly, ça manque de dynamisme. Tout est figé jusqu'à ce qu'on relâche. Il faudrait que ce soit dynamique même quand on a pas relaché, mais qu'on se déplace avec notre souris.
- [x] Quand un utilisateur a fini une poule, la page des groupes ne fonctionne pas bien :
  - [x] Il faut actualiser le classement choisi dans la group-card
  - [x] Il faut que l'utilisateur voit en un seul coup d'oeil qui il a qualifié, qui il a disqualifier
- [ ] Le flow du jeu ne me va pas, on peut choisir les meilleurs troisièmes alors même que le classement des poules n'est pas fini. ça n'a pas de sens. On devrait pouvoir choisir les meilleurs troisièmes une fois toutes les poules faites non ?
- [?] l'arbre du tournoi est tronqué dans mon navigateur, je suis obligé de scroller horizontalement pour voir la partie droite de l'arbre, il faut changer ça.
- [?] Quand l'arbre est à la verticale, les deux parties du tableau parte des 8 ème, sauf qu'il y a la finale entre les deux ce qui donne ce rendu très bizarre : 8-> 4-> 2-> finale-> 8 -> 4 -> 2

## Fonctionnalité clé

- [ ] Si l'utilisateur clique sur les détails d'un match avant de faire son choix : on affiche la feuille de match de chaque rencontre : On utilise l'image d'une pelouse et on y place les 22 joueurs + les coachs + les remplacants. Pour l'instant on va utiliser une silouhette tout en noir et pour le nom on va utiliser firstname lastname. Le but est de coder la feature, le style, puis ensuite on ajoutera les vraies données. 