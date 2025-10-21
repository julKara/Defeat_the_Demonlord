# Defeat_the_Demonlord
*The following repository contains the source code for the game Defeat the Demonlord (placeholdername), a game that is the endproduct for from the course TDDD23 Game Design.*

**Current Bugs**:
* Healthbar doesn't act like it should. (Works for now...)

**Issues (not really bugs, more structural issues):**
* `TileMap`: Currently, the movement-range is drawn upon the `TileMap` instead of the `TileMapLayer`. This makes the range invisible behind the `Background` or "too visible" in the sense that the red blocks are not supposed to be visible in-game.
* Changing `healthbar` color is not memory-efficient at all since it dublicates per character.

**Annoying features**
* You have to click on a unit to deselect them intead of just not clicking on anything else.

**Todo:**
* Implement turns -- Julia
* Cooldowns -- Julia
* Class advantage -- Julia
* Being able to start and win/lose a level (win/loss condition) -- Mirijam
* Xp system -- Mirijam
* Level select -- Mirijam
* Save files -- Mirijam
* Character talent (Knight: pass turn -> guard for allies (become attack_target), Mage: Apply burn (damage over time)) -- Julia
* Counter attack -- Julia
* Art (Demon Lord, slime, goblin, skeleton) -- Both
* Music -- Mirijam
