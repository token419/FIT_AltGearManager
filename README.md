# FIT Alt Gear Manager for Elder Scrolls Online

**WARNING**: This addon will auto bind items to you when it equips them, if you care about that, this may not be for you.

This addon helps manage gear for alts or new characters whose gear is under CP160 still. The addon itself won't actually do anything when it starts up if:

1. The character is above CP160
2. All worn items are CP160

The focus is to stop worrying about gear so you can just play the game. There is no setup, simply equip your preferred armor, weapons, and jewelry and the addon will auto monitor and upgrade them for you. When all of your gear equipped is CP160 the addon will automatically unregister itself.

The addon will register 1 command if active: `/fit`. This command will scan your backpack and auto equip any items considered upgrades. This can be handy when loading for the first time on a character that may have potential upgrades in their inventory.
- Note: This command, along with all logic in the addon, will not register if the character's currently equipped inventory is all above CP160.

**Weapon handling** is currently done by categories, if weapon specific passives are not purchased. The cateogires are:
- Destruction Staff (Fire, Lightening, Ice) **Note:** Purchasing the passive `Tri Focus` will override this, retaining your equiped specific weapon type.
- 2 Handed (Axe, Sword, Mace) **Note:** Purchasing the passive `Heavy Weapons` will override this, retaining your equiped specific weapon type.
- 1 Handed (Axe, Sword, Mace, Dagger, Shield) **Note:** Purchasing the passive `Twin Blade and Blunt` will override this, retaining your equiped specific weapon type.

if the weapon is of the same category it will upgrade that category, not the individual weapon type unless the corresponding passive for that weapon type is purchased.
- i.e. if a 1h sword is currently equipped, and a dagger dropped and is considered better, the dagger will be used, unless `Twin Blade and Blunt` is purchased, in which case, the sword would still be used until a better sword drops.

The weapon logic itself checks:

1. Verifies the item is not a companion item.
2. Checks the level requirements to make sure the item is usable by the character.
3. Checks the Level of the item, and the Quality, and if it resulting item is considered better, will equip it. (This is a literal check of adding the Level + Quality and comparing the 2, this allows us to compare items of different levels and qualities which may have identical stats)

**Armor handling** will make an additioal check to see if the new item is considered the same quality as our new one, has a more desireable enchant than our currently equipped one, and if so, will upgrade. We derrive desired enchant based on your attribute allocation. The follow attributes line up to the following enchants:
- More points into Stamina will prioritize Stamina enchantments.
- More points into Magicka will prioritize Magicka enchantments.
- More points into Health will prioritize Health enchantments.

The armor logic itself checks:
1. Verifies the item is not a companion item.
2. Checks the level requirements to make sure the item is usable by the character.
3. Checks the Level of the item, and the Quality, and if it resulting item is considered better, will equip it. (This is a literal check of adding the Level + Quality and comparing the 2, this allows us to compare items of different levels and qualities which may have identical stats)
4. Checks the item enchantment IF the item is of the same level and quality, if the enchantment is of the same type that your attributes are spent in, it will select that enchantment.
- i.e. If you have all of your points allocated into Stamina and you get a new chest that has a stamina enchant, and your old one had anything execpt a stamina enchant, it will select the new one with stamina.

**Jewelery handling** will check the currently equipped jewelry trait only upgrade new items that have the same trait and are of a higher considered quality.

The jewelery logic itself checks:
1. Verifies the item is not a companion item
2. Checks the level requirements to make sure the item is usable by the character.
3. Checks the Level of the item, and the Quality, and if it resulting item is better, will equip it. (This is a literal check of adding the Level + Quality and comparing the 2, this allows us to compare items of different levels and qualities which may have identical stats)