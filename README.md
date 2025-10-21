# Defeat_the_Demonlord
***The following repository contains the source code for the game Defeat the Demonlord (placeholdername), a game that is the endproduct for from the course TDDD23 Game Design.***

**Current Bugs**:
* Healthbar doesn't act like it should. (Works for now...)

**Issues (not really bugs, more structural issues):**
* Dephending on the postioning of the orginal `Sprite`, it will not apear in the middle of a tile. This is a needed art-fix.
* All animations are not uniform in size -> need to fix so all are centered
* Changing `healthbar` color is not memory-efficient at all since it dublicates per character.

**Annoying features**
* You have to click on a unit to deselect them intead of just not clicking on anything else.

**Todo:**
* Implement turns -- Julia
* Cooldowns -- Julia
* Class advantage -- Julia
* <del>Being able to start and win/lose a level (win/loss condition)</del> -- Mirijam
* Xp system -- Mirijam
* <del>Level select</del> -- Mirijam
* Save files -- Mirijam
* Character talent (Knight: pass turn -> guard for allies (become attack_target), Mage: Apply burn (damage over time)) -- Julia
* Counter attack -- Julia
* Art (Demon Lord, slime, goblin, skeleton) -- Both
* Music -- Mirijam
