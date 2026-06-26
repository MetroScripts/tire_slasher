# Tire Slasher

Script FiveM permettant de creuver les pneus des véhicules avec un couteau.

## Fonctionnalités
- Interaction `ox_target` optimisée.
- Animation réaliste avec équipement de l'arme.
- Nécessite un `weapon_knife` ou `weapon_switchblade` dans l'inventaire.
- Dégonflage visuel (pneu à plat, non explosé).
- Bloque l'interaction si le pneu est déjà crevé.

## Installation
1. Glissez le dossier `tire_slasher` dans vos ressources.
2. Assurez-vous d'avoir `ox_lib` et `ox_target` installés.
3. Ajoutez `ensure tire_slasher` dans votre `server.cfg`.
4. Ajoutez la ligne suivante dans votre `server.cfg` pour la gestion des armes :


setr inventory:ignoreweapons [
 "WEAPON_SWITCHBLADE",
 "WEAPON_KNIFE"
]

---
Créé par MetroScripts*
