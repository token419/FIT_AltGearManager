FIT_AltGearManager = {}
FIT_AltGearManager.namespaceId = "FIT_AltGearManager"
FIT_AltGearManager.version = "1"
FIT_AltGearManager.author = "@token419"
FIT_AltGearManager.Bags = {}
FIT_AltGearManager.Bags[BAG_BACKPACK] = SHARED_INVENTORY:GetOrCreateBagCache(BAG_BACKPACK)
FIT_AltGearManager.Bags[BAG_WORN] = SHARED_INVENTORY:GetOrCreateBagCache(BAG_WORN)
FIT_AltGearManager.Queue = {}
FIT_AltGearManager.vars = {}
FIT_AltGearManager.vars.Level = 0
FIT_AltGearManager.vars.CP = 0
FIT_AltGearManager.vars.inCombat = false
FIT_AltGearManager.vars.Health = GetAttributeSpentPoints(ATTRIBUTE_HEALTH)
FIT_AltGearManager.vars.Magicka = GetAttributeSpentPoints(ATTRIBUTE_MAGICKA)
FIT_AltGearManager.vars.Stamina = GetAttributeSpentPoints(ATTRIBUTE_STAMINA)
FIT_AltGearManager.vars.Main1Type = EQUIPMENT_FILTER_TYPE_NONE
FIT_AltGearManager.vars.Main2Type = EQUIPMENT_FILTER_TYPE_NONE
FIT_AltGearManager.vars.Back1Type = EQUIPMENT_FILTER_TYPE_NONE
FIT_AltGearManager.vars.Back2Type = EQUIPMENT_FILTER_TYPE_NONE
FIT_AltGearManager.vars.PrimaryStat = ATTRIBUTE_NONE
FIT_AltGearManager.vars.PrimaryArmorEnchant = 0
FIT_AltGearManager.vars.PrimaryJewelryTrait = 0
FIT_AltGearManager.utils = {} -- Container for functions

local function handleCombatQueue(eventCode, inCombat)
  if inCombat == false then
    EVENT_MANAGER:UnregisterForEvent(FIT_AltGearManager.namespaceId .. "_COMBAT_QUEUE", EVENT_PLAYER_COMBAT_STATE)
    FIT_AltGearManager.utils.TransferQueue()
  end
end -- End handleCombatQueue

function FIT_AltGearManager.utils.TransferQueue()
  local success = false

  if FIT_AltGearManager.vars.inCombat == true then
    EVENT_MANAGER:RegisterForEvent(FIT_AltGearManager.namespaceId .. "_COMBAT_QUEUE", EVENT_PLAYER_COMBAT_STATE, handleCombatQueue)
    return false
  end

  for k, v in pairs(FIT_AltGearManager.Queue) do
    if v.slotId ~= nil then
      if IsProtectedFunction("RequestMoveItem") then
        local result = CallSecureProtected("RequestMoveItem", BAG_BACKPACK, v.slotId, BAG_WORN, k, 1)
        FIT_AltGearManager.Queue[k] = nil
        if result == true then
          success = true
          SHARED_INVENTORY.refresh:RefreshSingle("inventory", BAG_BACKPACK, v.slotId, true, ITEM_SOUND_CATEGORY_DEFAULT, INVENTORY_UPDATE_REASON_DEFAULT)
          SHARED_INVENTORY.refresh:RefreshSingle("inventory", BAG_WORN, k, true, ITEM_SOUND_CATEGORY_DEFAULT, INVENTORY_UPDATE_REASON_DEFAULT)
        else
          -- d("Transfer Failed")
        end
      else
        RequestMoveItem(BAG_BACKPACK, v.slotId, destBag, BAG_WORN, k, 1)
        FIT_AltGearManager.Queue[k] = nil
        SHARED_INVENTORY.refresh:RefreshSingle("inventory", BAG_BACKPACK, v.slotId, true, ITEM_SOUND_CATEGORY_DEFAULT, INVENTORY_UPDATE_REASON_DEFAULT)
        SHARED_INVENTORY.refresh:RefreshSingle("inventory", BAG_WORN, k, true, ITEM_SOUND_CATEGORY_DEFAULT, INVENTORY_UPDATE_REASON_DEFAULT)
      end
      if success == true then
        -- d(v.slotId.." Equipped: "..v.itemLink)
        -- d("Equipped: "..v.itemLink)
      end
    end -- End if statement
  end -- End For loop

end -- End handleCombatQueue

function FIT_AltGearManager.utils.QueueWeaponUpgrades(SourceBag, slotId)
  local result = false
  local ItemRequiredLevel = GetItemRequiredLevel(SourceBag, slotId)
  local ItemRequiredCP = GetItemRequiredChampionPoints(SourceBag, slotId)
  local ItemEquipmentFilterType = GetItemEquipmentFilterType(SourceBag, slotId)
  local ItemFilterTypeInfo, CompanionItemFilterTypeInfo = GetItemFilterTypeInfo(SourceBag, slotId)
  local ItemDisplayQuality = GetItemDisplayQuality(SourceBag, slotId)
  local ComputedLevel = ItemRequiredLevel + ItemDisplayQuality
  local ItemType, SpecializedItemType = GetItemType(SourceBag, slotId)
  local itemLink = GetItemLink(SourceBag, slotId)
  local slots = {}
  slots[4] = true
  slots[5] = true
  slots[20] = true
  slots[21] = true

  if CompanionItemFilterTypeInfo == ITEMFILTERTYPE_COMPANION then
    -- Do Nothing for Companion Items
    -- d("Companion Item: "..itemLink)
  elseif ItemRequiredLevel > FIT_AltGearManager.vars.Level and ItemRequiredCP > FIT_AltGearManager.vars.CP then
    -- Do Nothing for Items we cannot use yet
    -- d("Not High Enough: "..itemLink)
  elseif ItemFilterTypeInfo == ITEMFILTERTYPE_WEAPONS then
    for k, _ in pairs(slots) do
      local shouldQueue = false
      local currentItemRequiredLevel = GetItemRequiredLevel(BAG_WORN, k)
      local currentItemDisplayQuality = GetItemDisplayQuality(BAG_WORN, k)
      local currentComputedLevel = currentItemRequiredLevel + currentItemDisplayQuality

      if ItemEquipmentFilterType == GetItemEquipmentFilterType(BAG_WORN, k) and ItemEquipType == v and ComputedLevel > currentComputedLevel then
        shouldQueue = true
      end

      if shouldQueue == true then
        result = true
        if FIT_AltGearManager.Queue[k] then
          if ComputedLevel > (GetItemRequiredLevel(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId) + GetItemDisplayQuality(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId))  then
            FIT_AltGearManager.Queue[k].slotId = slotId
            FIT_AltGearManager.Queue[k].ComputedLevel = ComputedLevel
            FIT_AltGearManager.Queue[k].itemLink = itemLink
          end
        else
          FIT_AltGearManager.Queue[k] = {}
          FIT_AltGearManager.Queue[k].slotId = slotId
          FIT_AltGearManager.Queue[k].ComputedLevel = ComputedLevel
          FIT_AltGearManager.Queue[k].itemLink = itemLink
        end
      end

    end
  end

  if result then
    if FIT_AltGearManager.Queue[4] and FIT_AltGearManager.Queue[5] then -- Make sure we're not trying to put both fingers into the same ring
      if FIT_AltGearManager.Queue[4].slotId == FIT_AltGearManager.Queue[5].slotId then
        FIT_AltGearManager.Queue[5] = nil
      end
    end
    FIT_AltGearManager.utils.TransferQueue()
  end

  return result

end -- End FIT_AltGearManager.utils.QueueWeaponUpgrades

-- /script d(FIT_AltGearManager.utils.QueueArmorUpgrades(BAG_BACKPACK, 16))
function FIT_AltGearManager.utils.QueueArmorUpgrades(SourceBag, slotId)
  local result = false
  local ItemRequiredLevel = GetItemRequiredLevel(SourceBag, slotId)
  local ItemRequiredCP = GetItemRequiredChampionPoints(SourceBag, slotId)
  local ItemEquipmentFilterType = GetItemEquipmentFilterType(SourceBag, slotId)
  local ItemEquipType = GetItemEquipType(SourceBag, slotId)
  local ItemFilterTypeInfo, CompanionItemFilterTypeInfo = GetItemFilterTypeInfo(SourceBag, slotId)
  local ItemDisplayQuality = GetItemDisplayQuality(SourceBag, slotId)
  local ComputedLevel = ItemRequiredLevel + ItemDisplayQuality
  local ItemType, SpecializedItemType = GetItemType(SourceBag, slotId)
  local itemLink = GetItemLink(SourceBag, slotId)
  local ArmorRating = GetItemLinkArmorRating(itemLink, false)
  local slots = {}
  slots[0] = EQUIP_TYPE_HEAD
  slots[2] = EQUIP_TYPE_CHEST
  slots[3] = EQUIP_TYPE_SHOULDERS
  slots[6] = EQUIP_TYPE_WAIST
  slots[8] = EQUIP_TYPE_LEGS
  slots[9] = EQUIP_TYPE_FEET
  slots[16] = EQUIP_TYPE_HAND

  if CompanionItemFilterTypeInfo == ITEMFILTERTYPE_COMPANION then
    -- Do Nothing for Companion Items
    -- d("Companion Item: "..itemLink)
  elseif ItemRequiredLevel > FIT_AltGearManager.vars.Level and ItemRequiredCP > FIT_AltGearManager.vars.CP then
    -- Do Nothing for Items we cannot use yet
    -- d("Not High Enough: "..itemLink)
  elseif ItemFilterTypeInfo == ITEMFILTERTYPE_ARMOR then
    for k , v in pairs(slots) do
      local shouldQueue = false
      local currentItemRequiredLevel = GetItemRequiredLevel(BAG_WORN, k)
      local currentItemDisplayQuality = GetItemDisplayQuality(BAG_WORN, k)
      local currentComputedLevel = currentItemRequiredLevel + currentItemDisplayQuality

      -- Get Enchantments, Sometimes GetItemLinkDefaultEnchantId does not return a value, so we do a secondary call to GetItemLinkAppliedEnchantId and overwrite if that happens
      local CurrentItemEnchant = GetItemLinkDefaultEnchantId(GetItemLink(BAG_WORN, k))
      if CurrentItemEnchant == 0 then
        CurrentItemEnchant = GetItemLinkAppliedEnchantId(GetItemLink(BAG_WORN, k))
      end

      -- Get Enchantments, Sometimes GetItemLinkDefaultEnchantId does not return a value, so we do a secondary call to GetItemLinkAppliedEnchantId and overwrite if that happens
      local ItemEnchant = GetItemLinkDefaultEnchantId(itemLink)
      if ItemEnchant == 0 then
        ItemEnchant = GetItemLinkAppliedEnchantId(itemLink)
      end

      -- If the item matches the slot.... well then...
      if ItemEquipmentFilterType == GetItemEquipmentFilterType(BAG_WORN, k) and ItemEquipType == v then
        if ComputedLevel > currentComputedLevel then
          shouldQueue = true
        elseif ComputedLevel == currentComputedLevel then

          if CurrentItemEnchant ~= FIT_AltGearManager.vars.PrimaryArmorEnchant and ItemEnchant == FIT_AltGearManager.vars.PrimaryArmorEnchant then
            -- d("Upgraded Becasue Enchant was better "..itemLink)
            shouldQueue = true
          else
            -- d("Skipped Same ComputedLevel item "..itemLink)
          end

        end
      end

      if shouldQueue == true then
        result = true
        if FIT_AltGearManager.Queue[k] then
          if ComputedLevel > (GetItemRequiredLevel(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId) + GetItemDisplayQuality(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId)) then
            FIT_AltGearManager.Queue[k].slotId = slotId
            FIT_AltGearManager.Queue[k].ComputedLevel = ComputedLevel
            FIT_AltGearManager.Queue[k].itemLink = itemLink
          end
        else
          FIT_AltGearManager.Queue[k] = {}
          FIT_AltGearManager.Queue[k].slotId = slotId
          FIT_AltGearManager.Queue[k].ComputedLevel = ComputedLevel
          FIT_AltGearManager.Queue[k].itemLink = itemLink
        end
      end

    end -- End for loop
  end -- End if statement

  if result == true then
    FIT_AltGearManager.utils.TransferQueue()
  end

  return result

end -- End FIT_AltGearManager.utils.QueueArmorUpgrades

function FIT_AltGearManager.utils.QueueJewelryUpgrades(SourceBag, slotId)
  local result = false
  local ItemRequiredLevel = GetItemRequiredLevel(SourceBag, slotId)
  local ItemRequiredCP = GetItemRequiredChampionPoints(SourceBag, slotId)
  local ItemEquipmentFilterType = GetItemEquipmentFilterType(SourceBag, slotId)
  local ItemFilterTypeInfo, CompanionItemFilterTypeInfo = GetItemFilterTypeInfo(SourceBag, slotId)
  local ItemDisplayQuality = GetItemDisplayQuality(SourceBag, slotId)
  local ComputedLevel = ItemRequiredLevel + ItemDisplayQuality
  local ItemType, SpecializedItemType = GetItemType(SourceBag, slotId)
  local itemLink = GetItemLink(SourceBag, slotId)
  local itemTrait = GetItemTrait(SourceBag, slotId)
  local slots = {}
  slots[1] = EQUIPMENT_FILTER_TYPE_NECK
  slots[11] = EQUIPMENT_FILTER_TYPE_RING
  slots[12] = EQUIPMENT_FILTER_TYPE_RING

  if CompanionItemFilterTypeInfo == ITEMFILTERTYPE_COMPANION then
    -- Do Nothing for Companion Items
    -- d("Companion Item: "..itemLink)
  elseif ItemRequiredLevel > FIT_AltGearManager.vars.Level and ItemRequiredCP > FIT_AltGearManager.vars.CP then
    -- Do Nothing for Items we cannot use yet
    -- d("Not High Enough: "..itemLink)
  elseif ItemFilterTypeInfo == ITEMFILTERTYPE_JEWELRY then
    for k , v in pairs(slots) do
      local shouldQueue = false
      local currentTrait = GetItemTrait(BAG_WORN, k)
      local currentItemRequiredLevel = GetItemRequiredLevel(BAG_WORN, k)
      local currentItemDisplayQuality = GetItemDisplayQuality(BAG_WORN, k)
      local currentComputedLevel = currentItemRequiredLevel + currentItemDisplayQuality

      if ItemEquipmentFilterType == v and ComputedLevel > currentComputedLevel then
        if itemTrait == currentTrait then
          shouldQueue = true
        end
      end

      if shouldQueue == true then
        result = true
        if FIT_AltGearManager.Queue[k] then
          if ComputedLevel > (GetItemRequiredLevel(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId) + GetItemDisplayQuality(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId))  then
            FIT_AltGearManager.Queue[k].slotId = slotId
            FIT_AltGearManager.Queue[k].ComputedLevel = ComputedLevel
            FIT_AltGearManager.Queue[k].itemLink = itemLink
          end
        else
          FIT_AltGearManager.Queue[k] = {}
          FIT_AltGearManager.Queue[k].slotId = slotId
          FIT_AltGearManager.Queue[k].ComputedLevel = ComputedLevel
          FIT_AltGearManager.Queue[k].itemLink = itemLink
        end
      end

    end
  end

  if result == true then
    if FIT_AltGearManager.Queue[11] and FIT_AltGearManager.Queue[12] then -- Make sure we're not trying to put both fingers into the same ring
      if FIT_AltGearManager.Queue[11].slotId == FIT_AltGearManager.Queue[12].slotId then
        FIT_AltGearManager.Queue[12] = nil
      end
    end
    FIT_AltGearManager.utils.TransferQueue()
  end

  return result

end -- End FIT_AltGearManager.utils.QueueJewelryUpgrades

function FIT_AltGearManager.utils.ParseInventory()
  local result = nil
  for k = 0, GetBagSize(BAG_BACKPACK) - 1 do
    -- Queue Armor Upgrades
    if FIT_AltGearManager.utils.QueueArmorUpgrades(BAG_BACKPACK, k) then result = true end
    -- Queue Armor Upgrades
    if FIT_AltGearManager.utils.QueueWeaponUpgrades(BAG_BACKPACK, k) then result = true end
    -- Queue Jewelery Upgrades
    if FIT_AltGearManager.utils.QueueJewelryUpgrades(BAG_BACKPACK, k) then result = true end
	end

  if result then FIT_AltGearManager.utils.TransferQueue() end

end -- End FIT_AltGearManager.utils.ParseInventory

-- Returns True if the character has non CP160 items still
function FIT_AltGearManager.utils.CP160ParseInventory()
  local slots = {}
  slots[0] = true -- Head
  slots[1] = true -- Neck
  slots[2] = true -- Chest
  slots[3] = true -- Shoulders
  slots[4] = true -- MainWeapon1
  -- slots[5] = true -- MainWeapon2
  slots[6] = true -- Waist
  slots[8] = true -- Legs
  slots[9] = true -- Feet
  slots[11] = true -- Ring1
  slots[12] = true -- Ring2
  slots[16] = true -- Hands
  slots[20] = true -- BackWeapon1
  -- slots[21] = true -- BackWeapon2

  for k , v in pairs(slots) do
    if GetItemRequiredChampionPoints(BAG_WORN, k) ~= 160 then
      return true
    end
	end
  -- Check if Duel Wielding on Main weapon bar
  local main1 = GetItemEquipmentFilterType(BAG_WORN, 4)
  if main1 == EQUIPMENT_FILTER_TYPE_ONE_HANDED or main1 == EQUIPMENT_FILTER_TYPE_SHIELD then
    if GetItemRequiredChampionPoints(BAG_WORN, 5) ~= 160 then
      return true
    end
  end
  -- Check if Duel Wielding on Back weapon bar
  local back1 = GetItemEquipmentFilterType(BAG_WORN, 20)
  if back1 == EQUIPMENT_FILTER_TYPE_ONE_HANDED or back1 == EQUIPMENT_FILTER_TYPE_SHIELD then
    if GetItemRequiredChampionPoints(BAG_WORN, 21) ~= 160 then
      return true
    end
  end

  return false

end -- End FIT_AltGearManager.utils.CP160ParseInventory

function FIT_AltGearManager.utils.UpdateAttributes()
  local function calculatePrimaryStat()
    local PrimaryStat = ATTRIBUTE_NONE
    if FIT_AltGearManager.vars.Stamina > FIT_AltGearManager.vars.Magicka and FIT_AltGearManager.vars.Stamina > FIT_AltGearManager.vars.Health then
      PrimaryStat = ATTRIBUTE_STAMINA
    elseif FIT_AltGearManager.vars.Magicka > FIT_AltGearManager.vars.Stamina and FIT_AltGearManager.vars.Magicka > FIT_AltGearManager.vars.Health then
      PrimaryStat = ATTRIBUTE_MAGICKA
    elseif FIT_AltGearManager.vars.Health > FIT_AltGearManager.vars.Stamina and FIT_AltGearManager.vars.Health > FIT_AltGearManager.vars.Magicka then
      PrimaryStat = ATTRIBUTE_HEALTH
    end

    return PrimaryStat

  end -- End calculatePrimaryStat

  local function calculatePrimaryJewelryTrait()
    local PrimaryJewelryTrait = ITEM_TRAIT_TYPE_NONE
    if FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_STAMINA then
      PrimaryJewelryTrait = ITEM_TRAIT_TYPE_JEWELRY_ROBUST
    elseif FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_MAGICKA then
      PrimaryJewelryTrait = ITEM_TRAIT_TYPE_JEWELRY_ARCANE
    elseif FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_HEALTH then
      PrimaryJewelryTrait = ITEM_TRAIT_TYPE_JEWELRY_HEALTHY
    end

    return PrimaryJewelryTrait

  end -- End calculatePrimaryJewelryTrait

  local function calculatePrimaryArmorEnchant()
    local PrimaryArmorEnchant = 0
    if FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_STAMINA then
      PrimaryArmorEnchant = 25
    elseif FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_MAGICKA then
      PrimaryArmorEnchant = 19
    elseif FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_HEALTH then
      PrimaryArmorEnchant = 17
    end

    return PrimaryArmorEnchant

  end -- End calculatePrimaryArmorEnchant

  FIT_AltGearManager.vars.Stamina = GetAttributeSpentPoints(ATTRIBUTE_STAMINA)
  FIT_AltGearManager.vars.Magicka = GetAttributeSpentPoints(ATTRIBUTE_MAGICKA)
  FIT_AltGearManager.vars.Health = GetAttributeSpentPoints(ATTRIBUTE_HEALTH)
  FIT_AltGearManager.vars.PrimaryStat = calculatePrimaryStat()
  FIT_AltGearManager.vars.PrimaryArmorEnchant = calculatePrimaryArmorEnchant()
  FIT_AltGearManager.vars.PrimaryJewelryTrait = calculatePrimaryJewelryTrait()

end -- End FIT_AltGearManager.utils.UpdateAttributes