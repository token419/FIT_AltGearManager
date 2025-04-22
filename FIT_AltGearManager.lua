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
FIT_AltGearManager.utils = {} -- Container for functions

local function handleCombatQueue(eventCode, inCombat)
  if inCombat == false then
    EVENT_MANAGER:UnregisterForEvent(FIT_AltGearManager.namespaceId .. "_COMBAT_QUEUE", EVENT_PLAYER_COMBAT_STATE)
    FIT_AltGearManager.utils.TransferQueue()
  end
end

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
          d("Transfer Failed")
        end
      else
        RequestMoveItem(BAG_BACKPACK, v.slotId, destBag, BAG_WORN, k, 1)
        FIT_AltGearManager.Queue[k] = nil
        SHARED_INVENTORY.refresh:RefreshSingle("inventory", BAG_BACKPACK, v.slotId, true, ITEM_SOUND_CATEGORY_DEFAULT, INVENTORY_UPDATE_REASON_DEFAULT)
        SHARED_INVENTORY.refresh:RefreshSingle("inventory", BAG_WORN, k, true, ITEM_SOUND_CATEGORY_DEFAULT, INVENTORY_UPDATE_REASON_DEFAULT)
      end
      if success == true then
        -- d("Equipped: "..v.itemLink)
      end
    end
  end

end

function FIT_AltGearManager.utils.QueueWeaponUpgrades(BAG, slotId)
  local result = false
  local ItemRequiredLevel = GetItemRequiredLevel(BAG, slotId)
  local ItemRequiredCP = GetItemRequiredChampionPoints(BAG, slotId)
  local ItemEquipmentFilterType = GetItemEquipmentFilterType(BAG, slotId)
  local itemLink = GetItemLink(BAG, slotId)
  local WeaponPower = GetItemLinkWeaponPower(itemLink)
  local ArmorRating = GetItemLinkArmorRating(itemLink, false)
  local slots = {}
  slots[4] = true
  slots[5] = true
  slots[20] = true
  slots[21] = true

  if ItemRequiredLevel <= FIT_AltGearManager.vars.Level and ItemRequiredCP >= FIT_AltGearManager.vars.CP then
    for k , _ in pairs(slots) do
      if ItemEquipmentFilterType ~= EQUIPMENT_FILTER_TYPE_SHIELD and ItemEquipmentFilterType == GetItemEquipmentFilterType(BAG_WORN, k) and WeaponPower > GetItemLinkWeaponPower(GetItemLink(BAG_WORN, k)) then
        result = true
        if FIT_AltGearManager.Queue[k] then
          if ItemRequiredLevel > GetItemRequiredLevel(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId) then
            FIT_AltGearManager.Queue[k].slotId = slotId
            FIT_AltGearManager.Queue[k].itemLink = itemLink
            FIT_AltGearManager.Queue[k].WeaponPower = WeaponPower
          end
        else
          FIT_AltGearManager.Queue[k] = {}
          FIT_AltGearManager.Queue[k].slotId = slotId
          FIT_AltGearManager.Queue[k].itemLink = itemLink
          FIT_AltGearManager.Queue[k].WeaponPower = WeaponPower
        end
      elseif ItemEquipmentFilterType == EQUIPMENT_FILTER_TYPE_SHIELD and ItemEquipmentFilterType == GetItemEquipmentFilterType(BAG_WORN, k) and ArmorRating > GetItemLinkArmorRating(GetItemLink(BAG_WORN, k), false)  then -- Handle Shields
        result = true
        if FIT_AltGearManager.Queue[k] then
          if ItemRequiredLevel > GetItemRequiredLevel(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId) then
            FIT_AltGearManager.Queue[k].slotId = slotId
            FIT_AltGearManager.Queue[k].itemLink = itemLink
            FIT_AltGearManager.Queue[k].ArmorRating = ArmorRating
          end
        else
          FIT_AltGearManager.Queue[k] = {}
          FIT_AltGearManager.Queue[k].slotId = slotId
          FIT_AltGearManager.Queue[k].itemLink = itemLink
          FIT_AltGearManager.Queue[k].ArmorRating = ArmorRating
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

end

-- /script d(FIT_AltGearManager.utils.QueueArmorUpgrades(BAG_BACKPACK, 16))
function FIT_AltGearManager.utils.QueueArmorUpgrades(BAG, slotId)
  local result = false
  local ItemRequiredLevel = GetItemRequiredLevel(BAG, slotId)
  local ItemRequiredCP = GetItemRequiredChampionPoints(BAG, slotId)
  local ItemEquipmentFilterType = GetItemEquipmentFilterType(BAG, slotId)
  local ItemEquipType = GetItemEquipType(BAG, slotId)
  local itemLink = GetItemLink(BAG, slotId)
  local ArmorRating = GetItemLinkArmorRating(itemLink, false)
  local slots = {}
  slots[0] = EQUIP_TYPE_HEAD
  slots[2] = EQUIP_TYPE_CHEST
  slots[3] = EQUIP_TYPE_SHOULDERS
  slots[6] = EQUIP_TYPE_WAIST
  slots[8] = EQUIP_TYPE_LEGS
  slots[9] = EQUIP_TYPE_FEET
  slots[16] = EQUIP_TYPE_HAND

  if ItemRequiredLevel <= FIT_AltGearManager.vars.Level and ItemRequiredCP >= FIT_AltGearManager.vars.CP then
    for k , v in pairs(slots) do
      if ItemEquipmentFilterType == GetItemEquipmentFilterType(BAG_WORN, k) and ArmorRating > GetItemLinkArmorRating(GetItemLink(BAG_WORN, k), false) and ItemEquipType == v then
        result = true
        if FIT_AltGearManager.Queue[k] then
          if ItemRequiredLevel > GetItemRequiredLevel(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId) then
            FIT_AltGearManager.Queue[k].slotId = slotId
            FIT_AltGearManager.Queue[k].itemLink = itemLink
          end
        else
          FIT_AltGearManager.Queue[k] = {}
          FIT_AltGearManager.Queue[k].slotId = slotId
          FIT_AltGearManager.Queue[k].itemLink = itemLink
        end
      end
    end
  end

  if result then FIT_AltGearManager.utils.TransferQueue() end

  return result

end

function FIT_AltGearManager.utils.QueueJewelryUpgrades(BAG, slotId)
  local result = false
  local trait = ITEM_TRAIT_TYPE_NONE
  local ItemRequiredLevel = GetItemRequiredLevel(BAG, slotId)
  local ItemRequiredCP = GetItemRequiredChampionPoints(BAG, slotId)
  local ItemEquipmentFilterType = GetItemEquipmentFilterType(BAG, slotId)
  local itemLink = GetItemLink(BAG, slotId)
  local itemTrait = GetItemTrait(BAG, slotId)
  local slots = {}
  slots[1] = EQUIPMENT_FILTER_TYPE_NECK
  slots[11] = EQUIPMENT_FILTER_TYPE_RING
  slots[12] = EQUIPMENT_FILTER_TYPE_RING

  -- Translate Primary Stat into Jewlery Trait
  if FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_STAMINA then
    trait = ITEM_TRAIT_TYPE_JEWELRY_ROBUST
  elseif FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_MAGICKA then
    trait = ITEM_TRAIT_TYPE_JEWELRY_ARCANE
  elseif FIT_AltGearManager.vars.PrimaryStat == ATTRIBUTE_HEALTH then
    trait = ITEM_TRAIT_TYPE_JEWELRY_HEALTHY
  end

  if ItemRequiredLevel <= FIT_AltGearManager.vars.Level and ItemRequiredCP >= FIT_AltGearManager.vars.CP then
    for k , v in pairs(slots) do
      local currentTrait = GetItemTrait(BAG_WORN, k)
      local currentItemRequiredLevel = GetItemRequiredLevel(BAG_WORN, k)
      if ItemEquipmentFilterType == v and ItemRequiredLevel >= currentItemRequiredLevel then
        if itemTrait == trait and currentTrait ~= trait then
          result = true
          if FIT_AltGearManager.Queue[k] then
            if ItemRequiredLevel > GetItemRequiredLevel(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId) then
              FIT_AltGearManager.Queue[k].slotId = slotId
              FIT_AltGearManager.Queue[k].itemLink = itemLink
            end
          else
            FIT_AltGearManager.Queue[k] = {}
            FIT_AltGearManager.Queue[k].slotId = slotId
            FIT_AltGearManager.Queue[k].itemLink = itemLink
          end
        elseif currentTrait == ITEM_TRAIT_TYPE_NONE then -- Handle if nothing equipped/no trait information
          result = true
          if FIT_AltGearManager.Queue[k] then
            if ItemRequiredLevel > GetItemRequiredLevel(BAG_BACKPACK, FIT_AltGearManager.Queue[k].slotId) then
              FIT_AltGearManager.Queue[k].slotId = slotId
              FIT_AltGearManager.Queue[k].itemLink = itemLink
            end
          else
            FIT_AltGearManager.Queue[k] = {}
            FIT_AltGearManager.Queue[k].slotId = slotId
            FIT_AltGearManager.Queue[k].itemLink = itemLink
          end
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

end

function FIT_AltGearManager.utils.ParseInventory()
  local result = nil
  for slotId=0, GetBagSize(BAG_BACKPACK)-1 do
    -- Queueu Armor Upgrades
    if FIT_AltGearManager.utils.QueueArmorUpgrades(BAG_BACKPACK, slotId) then result = true end
    -- Queueu Armor Upgrades
    if FIT_AltGearManager.utils.QueueWeaponUpgrades(BAG_BACKPACK, slotId) then result = true end
    -- Queueu Jewelery Upgrades
    if FIT_AltGearManager.utils.QueueJewelryUpgrades(BAG_BACKPACK, slotId) then result = true end
	end

  if result then FIT_AltGearManager.utils.TransferQueue() end

end

function FIT_AltGearManager.utils.UpdateAttributes()
  local function calculatePrimaryStat()
    local PrimaryStat = ATTRIBUTE_NONE
    if FIT_AltGearManager.vars.Stamina > PrimaryStat then
      PrimaryStat = ATTRIBUTE_STAMINA
    end
    if FIT_AltGearManager.vars.Magicka > PrimaryStat then
      PrimaryStat = ATTRIBUTE_MAGICKA
    end
    if FIT_AltGearManager.vars.Health > PrimaryStat then
      PrimaryStat = ATTRIBUTE_HEALTH
    end

    return PrimaryStat

  end

  FIT_AltGearManager.vars.Stamina = GetAttributeSpentPoints(ATTRIBUTE_STAMINA)
  FIT_AltGearManager.vars.Magicka = GetAttributeSpentPoints(ATTRIBUTE_MAGICKA)
  FIT_AltGearManager.vars.Health = GetAttributeSpentPoints(ATTRIBUTE_HEALTH)
  FIT_AltGearManager.vars.PrimaryStat = calculatePrimaryStat()

end