-- EVENT_INVENTORY_SINGLE_SLOT_UPDATE sends us (number eventCode, Bag bagId, number slotId, boolean isNewItem, ItemUISoundCategory itemSoundCategory, number inventoryUpdateReason, number stackCountChange)
local function onSingleSlotUpdate(eventCode, bagId, slotId, isNewItem, ItemUISoundCategory, inventoryUpdateReason, stackCountChange)
  local result = nil
  if bagId == BAG_BACKPACK then -- run comparison logic
    -- Queueu Armor Upgrades
    FIT_AltGearManager.utils.QueueArmorUpgrades(BAG_BACKPACK, slotId)
    -- Queueu Armor Upgrades
    FIT_AltGearManager.utils.QueueWeaponUpgrades(BAG_BACKPACK, slotId)
    -- Queueu Jewelery Upgrades
    FIT_AltGearManager.utils.QueueJewelryUpgrades(BAG_BACKPACK, slotId)

    -- d(slotId.." "..GetItemLink(bagId, slotId).." (onSingleSlotUpdate)")
  elseif bagId == BAG_WORN then
    -- Don't do anything if the player manually adjusted their inventory. Initiating a move event from here can cause infinate loops.

    -- Only Parse their BAG_WORN if they are above CP160, if all items are above CP160 then unregister
    if FIT_AltGearManager.vars.CP >= 160 and FIT_AltGearManager.utils.CP160ParseInventory() == false then
        -- d("Unregister")
        SLASH_COMMANDS["/fit"] = nil
        EVENT_MANAGER:UnregisterForEvent(FIT_AltGearManager.namespaceId .. "_ATTRIBUTES", EVENT_ATTRIBUTE_UPGRADE_UPDATED)
        EVENT_MANAGER:UnregisterForEvent(FIT_AltGearManager.namespaceId .. "_LEVELUP", EVENT_LEVEL_UPDATE)
        EVENT_MANAGER:UnregisterForEvent(FIT_AltGearManager.namespaceId .. "_COMBAT_EVENT", EVENT_PLAYER_COMBAT_STATE)
        EVENT_MANAGER:UnregisterForEvent(FIT_AltGearManager.namespaceId .. "_LOOT", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
    end

    -- d(slotId.." "..GetItemLink(bagId, slotId).." (onSingleSlotUpdate BAG_WORN)")

  end

  if result then FIT_AltGearManager.utils.TransferQueue() end

end -- End onSingleSlotUpdate

local function handleLevelUp(eventCode)
  FIT_AltGearManager.vars.Level = GetUnitLevel("player")
  FIT_AltGearManager.vars.CP = GetUnitEffectiveChampionPoints("player")
  FIT_AltGearManager.utils.ParseInventory()
end -- End handleLevelUp

local function handleAttributes(eventCode)
  FIT_AltGearManager.utils.UpdateAttributes()
end -- End handleAttributes

local function handleCombat(eventCode, inCombat)
  if inCombat == true then
    FIT_AltGearManager.vars.inCombat = true
  else
    FIT_AltGearManager.vars.inCombat = false
  end
end -- End handleCombat

local function initialize(eventCode, name)
  if name ~= FIT_AltGearManager.namespaceId then return end
  -- Stop checking for addons once we're loaded
  EVENT_MANAGER:UnregisterForEvent(FIT_AltGearManager.namespaceId, EVENT_ADD_ON_LOADED )

  -- Init Vars
  FIT_AltGearManager.vars.Level = GetUnitLevel("player")
  FIT_AltGearManager.vars.CP = GetUnitEffectiveChampionPoints("player")

  -- Only Enable if the character is lower than 50 or they are lower than CP160
  if FIT_AltGearManager.vars.Level < 50 or FIT_AltGearManager.vars.CP <= 160 or FIT_AltGearManager.utils.CP160ParseInventory() then
    FIT_AltGearManager.utils.UpdateAttributes()
    -- Documentation at https://wiki.esoui.com/Events
    EVENT_MANAGER:RegisterForEvent(FIT_AltGearManager.namespaceId .. "_ATTRIBUTES", EVENT_ATTRIBUTE_UPGRADE_UPDATED, handleAttributes)
    EVENT_MANAGER:RegisterForEvent(FIT_AltGearManager.namespaceId .. "_LEVELUP", EVENT_LEVEL_UPDATE, handleLevelUp)
    EVENT_MANAGER:RegisterForEvent(FIT_AltGearManager.namespaceId .. "_COMBAT_EVENT", EVENT_PLAYER_COMBAT_STATE, handleCombat)
    EVENT_MANAGER:RegisterForEvent(FIT_AltGearManager.namespaceId .. "_LOOT", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, onSingleSlotUpdate)
    SLASH_COMMANDS["/fit"] = FIT_AltGearManager.utils.ParseInventory

  end

end -- End initialize

EVENT_MANAGER:RegisterForEvent(FIT_AltGearManager.namespaceId, EVENT_ADD_ON_LOADED, initialize )






-- Search on ESOUI Source Code GetCurrentQuickslot()
-- local slotActions = ZO_InventorySlotActions:New()
-- slotActions:SetInventorySlot(slotId)

-- ApplySimpleQuickslotAction(slotActions, ACTION_TYPE_ITEM, actionId) --itemid?
-- https://wiki.esoui.com/Globals#ActionBarSlotType
-- https://github.com/esoui/esoui/blob/master/esoui/ingame/inventory/inventoryslot.lua
-- local function ApplySimpleQuickslotAction(slotActions, actionType, actionId)
--     if QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then
--         local currentSlot = FindActionSlotMatchingSimpleAction(actionType, actionId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
--         if currentSlot then
--             AddQuickslotRemoveAction(slotActions, currentSlot)
--         else
--             local validSlot = GetFirstFreeValidSlotForSimpleAction(actionType, actionId, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
--             if validSlot then
--                 AddQuickslotAddAction(function()
--                     SelectSlotSimpleAction(actionType, actionId, validSlot, HOTBAR_CATEGORY_QUICKSLOT_WHEEL)
--                 end, slotActions)
--             end
--         end
--     end
-- end
