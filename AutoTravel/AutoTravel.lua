function AutoTravel_Msg(s)
   if(DEFAULT_CHAT_FRAME) then
      DEFAULT_CHAT_FRAME:AddMessage("AutoTravel: " .. s);
   end
end

function AutoTravel_OnLoad()
   -- Setting up important variables
   ATStatus = { };
   ATStatus.speed = 0;

   ATStatus.num_points = 1000;
   ATStatus.num_lines = 1000;

   ATStatus.max_update_time = 1 / 5;

   SLASH_AUTOTRAVEL1 = "/at";
   SlashCmdList["AUTOTRAVEL"] = AutoTravel_SlashCommand;
   
   AutoTravel_Updater:RegisterEvent("VARIABLES_LOADED");
   AutoTravel_Updater:RegisterEvent("PLAYER_ENTERING_WORLD");
   AutoTravel_Updater:RegisterEvent("ZONE_CHANGED");
   AutoTravel_Updater:RegisterEvent("ZONE_CHANGED_INDOORS");
   AutoTravel_Updater:RegisterEvent("ZONE_CHANGED_NEW_AREA");

   StaticPopupDialogs["AUTOTRAVEL_POI"] = {
      text = AUTOTRAVEL_POINT_OF_INTEREST .. ":",
      button1 = TEXT(ACCEPT),
      button2 = TEXT(CANCEL),
      hasEditBox = 1,
      maxLetters = 63,
      whileDead = 1,
      OnAccept = AutoTravel_Point_POI_Editbox_OnAccept;
      timeout = 0,
      EditBoxOnEnterPressed = AutoTravel_Point_POI_Editbox_OnAccept;
      OnCancel = AutoTravel_Point_POI_Editbox_OnCancel;
   };

   ATStatus.party_str = { };
   for i = 1, 4 do
      ATStatus.party_str[i] = "AutoTravel_MapFrameContentParty" .. i;
   end
   
   AutoTravel_MapFrame_ZoomOffsetX = 0;
   AutoTravel_MapFrame_ZoomOffsetY = 0;
   AutoTravel_MapFrame_Zoom = 1;

   ATStatus.last_update = GetTime();
end

function AutoTravel_Init()
   AutoTravel_SetupData();

   if AutoTravelSettings.hidden then
      AutoTravel_Hide();
   end

   AutoTravel_SetupMainFrame();
   AutoTravel_MapFrame_Setup();

   AutoTravel_MainFrame_Menu_OnLoad();
   AutoTravel_POI_Menu_OnLoad();
   AutoTravel_Point_Menu_OnLoad();

   AutoTravelAPI.TriggerEvent("OnInitialized");

   AutoTravelCamera_Init();
   AutoTravel_Ready = 1;
end

function AutoTravel_OnEvent(arg1)
   if arg1 == "VARIABLES_LOADED" then
      Fetch_PlayerInfo = UnitName("player").." of "..GetCVar("realmName");
      AutoTravel_Init();
      AutoTravel_Updater:Show();
      return;
   end

   if not MapLibrary.Ready then
      return;
   end

   local zone = MapLibrary.GetCurrentZoneMap();
   if not zone then
      return;
   end

   AutoTravel_GetMapData(zone);
   AutoTravel_MapFrame_Dirty = 1;

   if zone ~= AutoTravel_MapFrame_Zone then
      AutoTravel_SetMapZone(zone);
   end
end

function AutoTravel_SlashCommand(msg)
   if (msg) then
      local command = string.lower(msg);
      if command == "stop" then
	 AutoTravel_Stop();
      elseif command == "pause" then
	 AutoTravel_Pause();
      elseif command == "resume" then
	 AutoTravel_Resume();
      elseif command == "add" then
	 AutoTravel_AddCurrentPoint();
      elseif command == "toggle hidden" then
	 AutoTravel_ToggleVisible();
      elseif command == "hide" then
	 AutoTravel_Hide();
      elseif command == "show" then
	 AutoTravel_Show();
      elseif string.find(command, "mapalpha %d+") then
	 local alpha;
	 for w in string.gfind(command, "%d+") do
	    alpha = tonumber(w) / 100;
	 end
	 if alpha >= 0 and alpha <= 1 then
	    AutoTravelSettings.mapalpha = alpha;
	    AutoTravel_UpdateAlpha();
	 end
      elseif command == "reset" then
	 AutoTravel_MapFrame:SetWidth(512);
	 AutoTravel_MapFrame:ClearAllPoints();
	 AutoTravel_MapFrame:SetPoint("TOP", "UIParent", "TOP", 0, -104);

	 AutoTravel_MainFrame:ClearAllPoints();
	 AutoTravel_MainFrame:SetPoint("TOP", "UIParent", "TOP", 0, -25);

	 AutoTravel_MapFrame_Dirty = 1;

      elseif string.find(command, "go .+") then
	 local target = string.sub(command, 4);
	 if not AutoTravel_CalculatePath(nil, nil, nil, target) then
	    -- Try as a subzone if not a poi
	    if not AutoTravel_CalculatePath(nil, nil, target, nil) then
	       -- Try as a zone if not a subzone
	       AutoTravel_CalculatePath(nil, target, nil, nil);
	    end
	 end
      end
   end
end

function AutoTravel_ToggleAutoRoad()
   if AutoTravelSettings.autoroad then
      AutoTravelSettings.autoroad = false;
   else
      AutoTravelSettings.autoroad = true;
   end
end

function AutoTravel_ToggleAutoRoad2()
   if AutoTravelSettings.autoroad2 then
      AutoTravelSettings.autoroad2 = false;
   else
      AutoTravelSettings.autoroad2 = true;
   end
end

function AutoTravel_ToggleMapOnWalk()
   if AutoTravelSettings.togglemap_onwalk then
      AutoTravelSettings.togglemap_onwalk = false;
   else
      AutoTravelSettings.togglemap_onwalk = true;
   end
end

function AutoTravel_ToggleReplacePoint()
   if AutoTravelSettings.replace_point then
      AutoTravelSettings.replace_point = false;
   else
      AutoTravelSettings.replace_point = true;
   end
end

function AutoTravel_ToggleShowEta()
   if AutoTravelSettings.show_eta then
      AutoTravelSettings.show_eta = false;
   else
      AutoTravelSettings.show_eta = true;
   end
   AutoTravel_UpdateUI();
end

function AutoTravel_ToggleHideRoads()
   if AutoTravelSettings.hide_roads then
      AutoTravelSettings.hide_roads = false;
   else
      AutoTravelSettings.hide_roads = true;
   end
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_ToggleHide2Roads()
   if AutoTravelSettings.hide2roads then
      AutoTravelSettings.hide2roads = false;
   else
      AutoTravelSettings.hide2roads = true;
   end
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_ToggleHideOtherZones()
   if AutoTravelSettings.hide_other_zones then
      AutoTravelSettings.hide_other_zones = false;
   else
      AutoTravelSettings.hide_other_zones = true;
   end
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_ToggleFadeNonPoi()
   if AutoTravelSettings.fade_non_poi then
      AutoTravelSettings.fade_non_poi = false;
   else
      AutoTravelSettings.fade_non_poi = true;
   end
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_ToggleVisible()
   if AutoTravelSettings.hidden then
      AutoTravel_Show();
   else
      AutoTravel_Hide();
   end
end

function AutoTravel_Show()
   AutoTravelSettings.hidden = false;
   AutoTravel_MainFrame:Show();
end

function AutoTravel_Hide()
   AutoTravelSettings.hidden = true;
   AutoTravel_MainFrame:Hide();
end

function AutoTravel_AddCurrentPoint()
   if MapLibrary.Ready then
      local zone = MapLibrary.GetMapZoneName();
      
      local posx, posy = MapLibrary.GetWorldPosition("player");
      if posx then
	 AutoTravel_AddPoint(posx, posy);
      elseif MapLibrary.ZoneIsCalibrated(zone) == false then
	 AutoTravel_Msg(AUTOTRAVEL_NOT_CALIBRATED);
      end
   end
end

function AutoTravel_Update(elapsed)
   if GetTime() - ATStatus.last_update > ATStatus.max_update_time then
      ATStatus.last_update = GetTime();
   else
      return;
   end

   -- Walk if wanted
   if ATStatus.path and not ATStatus.paused then
      AutoTravel_FollowPath();
   end

   AutoTravelAPI.FlushTriggerQueue();
end
