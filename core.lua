local addonName, acs = ...
AchievementChatSettingsDBPC = AchievementChatSettingsDBPC or {}

acs._handler = CreateFrame("Frame")
local handler = acs._handler
handler.OnEvent = function(self,event,...)
   return acs[event] and acs[event](acs,event,...)
end
handler:SetScript("OnEvent", handler.OnEvent)
handler:RegisterEvent("ADDON_LOADED")
handler:RegisterEvent("PLAYER_ENTERING_WORLD")
acs._userSave = {}

local chatTypeAchievment = {
   type = "ACHIEVEMENT",
   checked = function () return IsListeningForMessageType("ACHIEVEMENT") end,
   func = function(self, checked) ToggleChatMessageGroup(checked, "ACHIEVEMENT") end,
   disabled = false,
}
local chatTypeGuildAchievement = {
   type = "GUILD_ACHIEVEMENT",
   checked = function () return IsListeningForMessageType("GUILD_ACHIEVEMENT") end,
   func = function(self, checked) ToggleChatMessageGroup(checked, "GUILD_ACHIEVEMENT") end,
   disabled = false,
}

function acs:ADDON_LOADED(event,...)
   local addon = ...
   if addon == addonName then
      if self._PEW then
         self:RestoreSettings()
      end
      self._loaded = true
   end
end

function acs:PLAYER_ENTERING_WORLD(event,...)
   local isLogin, isReload = ...
   if self._loaded then
      self:RestoreSettings()
   end
   self._PEW = true
end

function acs.ChangeChatColor(chatType, r,g,b)
   if acs._userSave[chatType] then
      ChatTypeInfo[chatType].r = r
      ChatTypeInfo[chatType].g = g
      ChatTypeInfo[chatType].b = b
      AchievementChatSettingsDBPC["color"] = AchievementChatSettingsDBPC["color"] or {}
      AchievementChatSettingsDBPC["color"][chatType] = {r=r, g=g, b=b}
   end
end

function acs.ToggleChatMessageGroup(checked, chatType)
   if acs._userSave[chatType] then
      local id = FCF_GetCurrentChatFrameID()
      AchievementChatSettingsDBPC["status"] = AchievementChatSettingsDBPC["status"] or {}
      AchievementChatSettingsDBPC["status"][id] = AchievementChatSettingsDBPC["status"][id] or {}
      AchievementChatSettingsDBPC["status"][id][chatType] = checked
   end
end

function acs:Hook()
   if not acs._hookinstalled then
      hooksecurefunc("ChangeChatColor",acs.ChangeChatColor)
      hooksecurefunc("ToggleChatMessageGroup",acs.ToggleChatMessageGroup)
      acs._hookinstalled = true
   end
end

function acs:FindConfig(chatType)
   for k,config in pairs(CHAT_CONFIG_OTHER_SYSTEM) do
      if config.type == chatType then
         return k
      end
   end
   return
end

local function WrapToggleChatMessageGroup(id,chatType,status)
   local env = {FCF_GetCurrentChatFrame = function()
      return _G["ChatFrame"..id]
   end}
   setmetatable(env, {__index = _G})
   local func = setfenv(ToggleChatMessageGroup, env)
   func(status,chatType)
   setfenv(ToggleChatMessageGroup, _G)
end

function acs:RestoreSettings()
   if not ChatTypeInfo["ACHIEVEMENT"] then
      ChatTypeInfo["ACHIEVEMENT"] = { sticky = 0, flashTab = false, flashTabOnGeneral = false }
      acs._userSave["ACHIEVEMENT"] = true
   end
   if not ChatTypeGroup["ACHIEVEMENT"] then
      ChatTypeGroup["ACHIEVEMENT"] = {
        "CHAT_MSG_ACHIEVEMENT"
      }
   end
   if not ChatTypeInfo["GUILD_ACHIEVEMENT"] then
      ChatTypeInfo["GUILD_ACHIEVEMENT"] = { sticky = 0, flashTab = true, flashTabOnGeneral = false }
      acs._userSave["GUILD_ACHIEVEMENT"] = true
   end
   if not ChatTypeGroup["GUILD_ACHIEVEMENT"] then
      ChatTypeGroup["GUILD_ACHIEVEMENT"] = {
         "CHAT_MSG_GUILD_ACHIEVEMENT"
      }
   end
   if not self:FindConfig("ACHIEVEMENT") then
      tinsert(CHAT_CONFIG_OTHER_SYSTEM,chatTypeAchievment)
   end
   if not self:FindConfig("GUILD_ACHIEVEMENT") then
      tinsert(CHAT_CONFIG_OTHER_SYSTEM,chatTypeGuildAchievement)
   end
   ChatConfig_CreateCheckboxes(ChatConfigOtherSettingsSystem, CHAT_CONFIG_OTHER_SYSTEM, "ChatConfigCheckBoxWithSwatchTemplate", OTHER)

   if AchievementChatSettingsDBPC["color"] then
      if AchievementChatSettingsDBPC["color"]["ACHIEVEMENT"] then
         local color = AchievementChatSettingsDBPC["color"]["ACHIEVEMENT"]
         ChangeChatColor("ACHIEVEMENT",color.r, color.g, color.b)
      end
      if AchievementChatSettingsDBPC["color"]["GUILD_ACHIEVEMENT"] then
         local color = AchievementChatSettingsDBPC["color"]["GUILD_ACHIEVEMENT"]
         ChangeChatColor("GUILD_ACHIEVEMENT",color.r, color.g, color.b)
      end
   end

   if AchievementChatSettingsDBPC["status"] then
      for id,info in pairs(AchievementChatSettingsDBPC["status"]) do
         for chatType,status in pairs(info) do
            WrapToggleChatMessageGroup(id,chatType,status)
         end
      end
   end

   self._handler:UnregisterEvent("PLAYER_ENTERING_WORLD")
   self:Hook()
end