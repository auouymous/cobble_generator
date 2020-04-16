Minetest Cobble Generator Mod
==========

![screenshot](/screenshot.png?raw=true "")

Automated cobble generators can be a source of client and server lag when combined with mods that require large quantities of cobble.
A simple one has flowing lava that turns to stone, a node detector activates a node breaker which sends a single item to a chest or pipeworks tube.
Glitches can result in the node breaker jamming, which requires more complicated control such as a luacontroller.
And some mods might randomly produce other blocks besides just stone, needing a sorter to extract the cobble.

This mod provides 6 nodes that produce 1, 2, 4, 8, 16, or 32 cobblestone every 3 seconds.
When its single stack inventory fills, it automatically tries to eject the entire stack to the node above or below.
Automatic ejection supports Node-IO, Pipeworks or any node with a "main" inventory.
It stops producing cobble if it is unable to eject enough of its inventory.
Manually taking from the inventory, using an external machine to take from any side or punching the cobble generator will restart it.
A mesecon signal can be used to stop cobble production, and removing the signal will restart it.

Breaking the node will drop any cobble it was storing.

The recipe for a mk1 generator varies if pipeworks node breaker or mesecons node detector are installed.

| steel ingot  | steel pick *or* node breaker   | steel_ingot |
| water bucket | stone                          | lava bucket |
| steel ingot  | steel block *or* node detector | steel ingot |

Two of any same tier generator can be crafted together to upgrade to the next higher tier.
And any generator can be downgraded to the tier below it.



Links
==========

[Download](https://github.com/auouymous/cobble_generator/archive/master.zip)
