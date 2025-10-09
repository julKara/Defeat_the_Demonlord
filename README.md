# Defeat_the_Demonlord
***The following repository contains the source code for the game Defeat the Demonlord (placeholdername), a game that is the endproduct for from the course TDDD23 Game Design.***

**Current Bugs**:
* Movement: When pressing quickly will already having inputted an movement action lets the unit move to unreachable tiles. It also lets them move unnaturally, espeshially around edges.

**Issues (not really bugs, more strucrual issues):**
* `TileMap`: Currently, the movement-range is drawn upon the `TileMap` instead of the `TileMapLayer`. This makes the range invisible behind the `Background` or "too visible" in the sense that the red blocks are not supposed to be visible in-game. 
