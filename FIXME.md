### Petites corrections

- [ ] Revoir le texte et les phrases qui n'ont pas de sens (landing page notamment)
- [x] Pages mentions légales, confidentialité 
- [x] Meilleure accessibilité vers les détails d'une équipe.
- [ ] Flow pour le mode complete ne fonctionne pas (prediction-form doit être inclus comme une modale qui s'afficherait automatiquement, on pourrait la fermer pour observer l'arbre, et la faire réapparaitre quand on veut ?)
- [x] Page modifiée quand on a enfin prédit le gagnant de la coupe du monde, avec un podium, confettis (statistiques pour le mode complete)
- [ ] Pour les matchs de poules, pareil que pour l'arbre -> mettre prediction form dans une modale, c'est bizarre de faire quitter la page ou alors la faire apparaitre en dessous ? parce qu'une modale sur téléphone c'est étrange également ?
- [x] La div player-info n'est pas satisfaisante dans la page teams (irrégulière selon la longueur du nom du joueur.)

### Gros chantiers

- [ ] Couvrir l'intégralité du projet avec des tests (agent claude).
- [ ] Documentation complète du code (agent).
- [ ] Renommage des pays avec les clés de traduction en bdd plutôt que les noms en français pour être supportés dans toutes les langues ? Voir si cette solution fonctionne
- [ ] Refacto du css, découpages en de nombreux fichiers pour favoriser la lisibilité
- [ ] CDN pour les images ? trouver une solution gratuite plutôt que local
- [x] Déploiement avec Render (gratuit) + UptimeRobot