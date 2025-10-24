# Defeat_the_Demonlord
***The following repository contains the source code for the game Defeat the Demonlord (placeholdername), a game that is the endproduct for from the course TDDD23 Game Design.***

## Current Bugs:
* Healthbar doesn't act like it should. (Works for now...)

## Issues (not really bugs, more structural issues):
* Changing `healthbar` color is not memory-efficient at all since it dublicates per character.
* Enemies can probably occupy the same space
* Sprites should flip when moving/attacking to the left.
* AI-controlled ranged units should move to a beneficial range to avoid range-penalty.
* Characters can level up when replaying a level.

## Annoying features:
* You have to click on a unit to deselect them intead of just not clicking on anything else. Same with target.
* Character located below another character should appear on top of the other character. (change node order)

## Todo:
* Implement turns -- Julia
* Cooldowns -- Julia
* Class advantage -- Julia
* <del>Being able to start and win/lose a level (win/loss condition)</del> -- Mirijam
* Xp system -- Mirijam
* <del>Level select</del> -- Mirijam
* <del>Save files</del> -- Mirijam
* Character talent (Knight: pass turn -> guard for allies (become attack_target), Mage: Apply burn (damage over time)) -- Julia
* <del>Counter attack -- Julia</del>
* Art (Demon Lord, slime, goblin, skeleton) -- Both
* Music -- Mirijam

## Hand-in:
* Playthrough - Julia
* Trailer/preview - Mirijam

* Code-explaination.
