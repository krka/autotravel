function AutoTravel_SetupMainFrame()
   AutoTravel_DestinationText:SetTextColor(0.7, 0.9, 1.0);
   AutoTravel_DestinationText:SetText(AUTOTRAVEL_DESTINATION);

   AutoTravel_DistanceText:SetTextColor(0.7, 0.9, 1.0);
   AutoTravel_DistanceText:SetText(AUTOTRAVEL_DISTANCE);

   AutoTravel_TimeText:SetTextColor(0.7, 0.9, 1.0);
   AutoTravel_TimeText:SetText(AUTOTRAVEL_ETA);

   AutoTravel_UpdateUI();
end

function AutoTravel_UpdateUI()
   if ATStatus.path and AutoTravel_MainFrame:IsVisible() then
      local count = table.getn(ATStatus.path);
      local end_point = ATStatus.path[count];
      local end_point_coords = AutoTravel_GetPoint(end_point.point);

      local subzone = end_point_coords.zone;
      if end_point_coords.subzone and end_point_coords.subzone ~= "" then
	 subzone = end_point_coords.subzone;
      end

      AutoTravel_DestinationValue:SetText(subzone);

      if not ATStatus.paused then
	 
	 local distance = AutoTravel_GetDistance();
	 
	 AutoTravel_DistanceValue:SetText(format("%.1f %s", distance, AUTOTRAVEL_YARDS));
	 if ATStatus.speed == 0 then
	    AutoTravel_TimeValue:SetText("???");
	 else
	    local seconds = floor(distance / ATStatus.speed);
	    local minutes = floor(seconds / 60);
	    seconds = seconds - 60 * minutes;

	    AutoTravel_TimeValue:SetText(format("%2d:%02d", minutes, seconds));
	 end
      else
	 AutoTravel_DistanceValue:SetText(AUTOTRAVEL_PAUSED);
	 AutoTravel_TimeValue:SetText("");
      end
   else
      AutoTravel_DistanceValue:SetText("");
      AutoTravel_DestinationValue:SetText("");
      AutoTravel_TimeValue:SetText("");
   end

   if AutoTravelSettings.show_eta then
      AutoTravel_MainFrame:SetWidth(240);
      AutoTravel_TimeText:Show();
      AutoTravel_TimeValue:Show();
      
      AutoTravel_DistanceText:SetPoint("TOPRIGHT",
				       "AutoTravel_MainFrame",
				       "TOPRIGHT",
					  -46, -6);
      AutoTravel_DistanceValue:SetPoint("BOTTOMRIGHT",
				       "AutoTravel_MainFrame",
				       "BOTTOMRIGHT",
					  -46, 6);
   else
      AutoTravel_MainFrame:SetWidth(200);
      AutoTravel_TimeText:Hide();
      AutoTravel_TimeValue:Hide();

      AutoTravel_DistanceText:SetPoint("TOPRIGHT",
				       "AutoTravel_MainFrame",
				       "TOPRIGHT",
					  -6, -6);
      AutoTravel_DistanceValue:SetPoint("BOTTOMRIGHT",
				       "AutoTravel_MainFrame",
				       "BOTTOMRIGHT",
					  -6, 6);
   end
end


function AutoTravel_MainFrame_OnClick(arg1)
   DropDownList1:Hide();
   if arg1 == "RightButton" then
      local x, y = GetCursorPosition(); 
      if x > UIParent:GetWidth() - 200 then
	 x = UIParent:GetWidth() - 200;
      end
      if y < 300 then
	 y = 300;
      end
      ToggleDropDownMenu(1, nil, AutoTravel_MainFrame_Menu, "UIParent", x, y);
   end
end

function AutoTravel_MainFrame_Menu_OnLoad()
   UIDropDownMenu_Initialize(AutoTravel_MainFrame_Menu, AutoTravel_MainFrame_Menu_Initialize, "MENU");
end

local AutoTravel_LocalPOI;

function AutoTravel_MainFrame_Menu_Initialize(level)
   if level == 2 then
      if UIDROPDOWNMENU_MENU_VALUE == 1 then
	 -- Zones
	 local info = {};
	 info.text = AUTOTRAVEL_ZONES;
	 info.notClickable = 1;
	 info.isTitle = 1;
	 UIDropDownMenu_AddButton(info, 2);

	 local curzone = MapLibrary.GetCurrentZoneMap();
	 if not curzone then
	    return;
	 end
	 
	 local cur_continent = MapLibrary.mappedzone[curzone].continent;

	 local zones = { };
	 for zone, id in MapLibrary.mappedzone do
	    if id.zone ~= 0 and id.continent == cur_continent and ATStatus.zone_points[zone] then
	       
	       if not AutoTravel_IsTableEmpty(ATStatus.zone_points[zone]) then
	       end
	       zones[zone] = 1;
	    end
	 end

	 -- this is to get it sorted.
	 local zones2 = { };
	 for zone in zones do
	    table.insert(zones2, zone);
	 end
	 table.sort(zones2);

	 for index, zone in zones2 do
	    local info = {};
	    info.text = zone;
	    info.value = {"zone", zone};
	    info.hasArrow = 1;
	    info.func = AutoTravel_MainFrame_Zone_Menu_OnClick;
	    UIDropDownMenu_AddButton(info, 2);
	 end
      elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
	 -- POI
	 AutoTravel_LocalPOI = false;
	 AutoTravel_POI_Menu_Initialize_global(2);
      elseif UIDROPDOWNMENU_MENU_VALUE == 12 then
	 AutoTravel_LocalPOI = true;
	 AutoTravel_POI_Menu_Initialize_local(2);
      elseif UIDROPDOWNMENU_MENU_VALUE == 3 then
	 -- Map settings
	 local info = {};
	 info.text = AUTOTRAVEL_MAPSETTINGS;
	 info.notClickable = 1;
	 info.isTitle = 1;
	 UIDropDownMenu_AddButton(info, level);

	 local info = {};
	 info.text = AUTOTRAVEL_TOGGLEMAP_ONWALK;
	 if AutoTravelSettings.togglemap_onwalk then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleMapOnWalk;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_HIDE_ROADS;
	 if AutoTravelSettings.hide_roads then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleHideRoads;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_HIDE_TWO_ROADS;
	 if AutoTravelSettings.hide2roads then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleHide2Roads;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_HIDE_OTHER_ZONES;
	 if AutoTravelSettings.hide_other_zones then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleHideOtherZones;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_FADE_NON_POI;
	 if AutoTravelSettings.fade_non_poi then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleFadeNonPoi;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_WHEEL_ZOOM;
	 if AutoTravelSettings.wheelzoom then
	    info.checked = 1;
	 end
	 info.func = function() AutoTravelSettings.wheelzoom = not AutoTravelSettings.wheelzoom; end;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);
	 
      elseif UIDROPDOWNMENU_MENU_VALUE == 4 then
	 -- Pathing settings
	 local info = {};
	 info.text = AUTOTRAVEL_PATHING_SETTINGS;
	 info.notClickable = 1;
	 info.isTitle = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_SHOW_ETA;
	 if AutoTravelSettings.show_eta then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleShowEta;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_REPLACE_POINT;
	 if AutoTravelSettings.replace_point then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleReplacePoint;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_AUTOROAD;
	 if AutoTravelSettings.autoroad then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleAutoRoad;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_AUTOROAD2;
	 if AutoTravelSettings.autoroad2 then
	    info.checked = 1;
	 end
	 info.func = AutoTravel_ToggleAutoRoad2;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);

	 info = {};
	 info.text = AUTOTRAVEL_LOCAL_POI;
	 if AutoTravelSettings.local_poi then
	    info.checked = 1;
	 end
	 info.func = function() AutoTravelSettings.local_poi = not AutoTravelSettings.local_poi; end;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);
	 
	 info = {};
	 info.text = AUTOTRAVEL_PARTIAL_MATCHING;
	 if AutoTravelSettings .partial_matching then
	    info.checked = 1;
	 end
	 info.func = function() AutoTravelSettings.partial_matching = not AutoTravelSettings.partial_matching; end;
	 info.keepShownOnClick = 1;
	 UIDropDownMenu_AddButton(info, level);
	 
      end
      return;
   elseif level == 3 then
      if type(UIDROPDOWNMENU_MENU_VALUE) == "string" then
	 AutoTravel_POI_Menu_Initialize_shared(3, AutoTravel_LocalPOI);
      elseif UIDROPDOWNMENU_MENU_VALUE[1] == "zone" then
	 -- Subzones
	 local info = {};
	 info.text = AUTOTRAVEL_SUBZONES;
	 info.notClickable = 1;
	 info.isTitle = 1;
	 UIDropDownMenu_AddButton(info, 3);
	 
	 local zone = UIDROPDOWNMENU_MENU_VALUE[2];
	 local subzones = { };
	 for index in ATStatus.zone_points[zone] do
	    local point = AutoTravel_GetPoint(index);
	    local subzone = point.subzone;
	    if subzone == "" then
	       subzone = zone;
	    end
	    if point.zone == zone then
	       subzones[subzone] = 1;
	    end
	 end
	 
	 -- this is to get it sorted.
	 local subzones2 = { };
	 for subzone in subzones do
	    table.insert(subzones2, subzone);
	 end
	 table.sort(subzones2);
	 
	 for index, subzone in subzones2 do
	    local info = {};
	    info.text = subzone;
	    info.value = {zone, subzone};
	    info.func = AutoTravel_MainFrame_Subzone_OnClick;
	    UIDropDownMenu_AddButton(info, 3);
	 end
      end
      return;
   end
   
   local info = {};
   info.text = AUTOTRAVEL_TRAVEL_OPTIONS;
   info.notClickable = 1;
   info.isTitle = 1;
   UIDropDownMenu_AddButton(info);
  
   if not Fetch_PlayerInfo then
      return;
   end

   if ATStatus.path then
      info = {};
      info.text = AUTOTRAVEL_STOP;
      info.func = AutoTravel_Stop;
      info.checked = nil;
      info.keepShownOnClick = nil;
      UIDropDownMenu_AddButton(info);

      if ATStatus.paused then
	 info = {};
	 info.text = BINDING_NAME_AUTOTRAVEL_RESUME;
	 info.func = AutoTravel_Resume;
	 info.checked = nil;
	 info.keepShownOnClick = nil;
	 UIDropDownMenu_AddButton(info);
      else
	 info = {};
	 info.text = BINDING_NAME_AUTOTRAVEL_PAUSE;
	 info.func = AutoTravel_Pause;
	 info.checked = nil;
	 info.keepShownOnClick = nil;
	 UIDropDownMenu_AddButton(info);
      end
   end

   info = {};
   info.text = BINDING_NAME_AUTOTRAVEL_ADD_POINT;
   info.func = AutoTravel_AddCurrentPoint;
   UIDropDownMenu_AddButton(info);

   info = {};
   info.text = AUTOTRAVEL_GO_TO_ZONE;
   info.value = 1;
   info.hasArrow = 1;
   UIDropDownMenu_AddButton(info);

   info = {};
   info.text = AUTOTRAVEL_GO_TO_POI;
   info.value = 2;
   info.hasArrow = 1;
   UIDropDownMenu_AddButton(info);

   info = {};
   info.text = AUTOTRAVEL_GO_TO_LOCAL_POI;
   info.value = 12;
   info.hasArrow = 1;
   UIDropDownMenu_AddButton(info);

   info = {};
   info.text = AUTOTRAVEL_SETTINGS;
   info.notClickable = 1;
   info.isTitle = 1;
   UIDropDownMenu_AddButton(info);
  
   info = { };
   info.text = AUTOTRAVEL_SHOW_MAIN;
   info.keepShownOnClick = 1;
   if not AutoTravelSettings.hidden then
      info.checked = 1;
   end
   info.func = AutoTravel_ToggleVisible;
   UIDropDownMenu_AddButton(info);
  
   info = { };
   info.text = AUTOTRAVEL_SHOW_MAP;
   info.keepShownOnClick = 1;
   if AutoTravel_MapFrame:IsVisible() then
      info.checked = 1;
   end
   info.func = AutoTravel_ToggleMapVisible;
   UIDropDownMenu_AddButton(info);

   info = {};
   info.text = AUTOTRAVEL_MAPSETTINGS;
   info.hasArrow = 1;
   info.value = 3;
   UIDropDownMenu_AddButton(info);

   info = {};
   info.text = AUTOTRAVEL_PATHING_SETTINGS;
   info.hasArrow = 1;
   info.value = 4;
   UIDropDownMenu_AddButton(info);
end

function AutoTravel_MainFrame_Zone_Menu_OnClick()
   AutoTravel_CalculatePath(nil, this.value[2]);
   CloseDropDownMenus(1);
end

function AutoTravel_MainFrame_Subzone_OnClick()
   AutoTravel_CalculatePath(nil, this.value[1], this.value[2]);
   CloseDropDownMenus(1);
end

 -- Is there a better way to do this?
function AutoTravel_IsTableEmpty(t)
   for tmp in t do
      return false;
   end
   return true;
end
