function AutoTravel_POI_Setup()
   ATStatus.poi_list = { };
   ATStatus.poi_sublist = { };
   ATStatus.poi_namelist = { };

   ATStatus.poi_zone_list = { };
   ATStatus.poi_zone_sublist = { };

   for index, point in AutoTravel_GetPoints() do
      if point.poi then
	 AutoTravel_POI_AddPOI(point.poi, point.zone);
      end
   end
end

function AutoTravel_POI_SplitPOIList(poi)
   local list = { };
   local start_search = 1;
   while true do
      local i = string.find(poi, ",", start_search, true);
      if not i then
	 break;
      end
      table.insert(list, string.sub(poi, start_search, i - 1));
      start_search = i + 1;
   end
   table.insert(list, string.sub(poi, start_search));
   return list;
end

function AutoTravel_POI_SplitPOISub(poi)
   local i = string.find(poi, "||", start_search, true);
   if not i then
      return nil;
   end
   return string.sub(poi, 1, i - 1), string.sub(poi, i + 2);
end

function AutoTravel_POI_AddPOI(poi, zone)
   local list = ATStatus.poi_list;
   local sublist = ATStatus.poi_sublist;
   AutoTravel_POI_AddPOI_Zone(poi, list, sublist);

   if not ATStatus.poi_zone_list[zone] then
      ATStatus.poi_zone_list[zone] = { };
   end
   list = ATStatus.poi_zone_list[zone];

   if not ATStatus.poi_zone_sublist[zone] then
      ATStatus.poi_zone_sublist[zone] = { };
   end
   sublist = ATStatus.poi_zone_sublist[zone];

   AutoTravel_POI_AddPOI_Zone(poi, list, sublist);
end

function AutoTravel_POI_AddPOI_Zone(poi, list, sublist)
   for index2, poi2 in AutoTravel_POI_SplitPOIList(poi) do
      
      local poi_lower = string.lower(poi2);
      ATStatus.poi_namelist[poi_lower] = poi2;

      if not list[poi_lower] then
	 list[poi_lower] = 1;
      else
	 list[poi_lower] = list[poi_lower] + 1;
      end
      local cat, name = AutoTravel_POI_SplitPOISub(poi2);
      if cat then

	 local cat_lower, name_lower = string.lower(cat), string.lower(name);
	 ATStatus.poi_namelist[cat_lower] = cat;
	 ATStatus.poi_namelist[name_lower] = name;

	 if not list[cat_lower] then
	    list[cat_lower] = 1;
	 else
	    list[cat_lower] = list[cat_lower] + 1;
	 end

	 if not sublist[cat_lower] then
	    sublist[cat_lower] = { };
	 end
	 if not sublist[cat_lower][name_lower] then
	    sublist[cat_lower][name_lower] = 1;
	 else
	    sublist[cat_lower][name_lower] = sublist[cat_lower][name_lower] + 1;
	 end
      end
   end
end

function AutoTravel_POI_RemovePOI(poi, zone)
   poi = string.lower(poi);

   local list = ATStatus.poi_list;
   local sublist = ATStatus.poi_sublist;
   AutoTravel_POI_RemovePOI_Zone(poi, list, sublist);

   list = ATStatus.poi_zone_list[zone];
   sublist = ATStatus.poi_zone_sublist[zone];
   if list and sublist then
      AutoTravel_POI_RemovePOI_Zone(poi, list, sublist);
   end
end

function AutoTravel_POI_RemovePOI_Zone(poi, list, sublist)
   for index2, poi2 in AutoTravel_POI_SplitPOIList(poi) do
      if list[poi2] then
	 if list[poi2] == 1 then
	    list[poi2] = nil;
	 else
	    list[poi2] = list[poi2] - 1;
	 end
      end
      local cat, name = AutoTravel_POI_SplitPOISub(poi2);
      if cat then
	 if list[cat] then
	    if list[cat] == 1 then
	       list[cat] = nil;
	    else
	       list[cat] = list[cat] - 1;
	    end
	 end
	 if sublist[cat] then
	    if sublist[cat][name] then
	       if sublist[cat][name] == 1 then
		  sublist[cat][name] = nil;
		  if AutoTravel_IsTableEmpty(sublist[cat]) then
		     sublist[cat] = nil;
		  end
	       else
		  sublist[cat][name] = sublist[cat][name] - 1;
	       end
	    end
	 end
      end
   end
end

function AutoTravel_POI_IsMatch(search, point)
   if AutoTravelSettings.partial_matching then
      return AutoTravel_POI_IsPartialMatch(search, point)
   end

   search = string.lower(search);

   local p = point.poi;
   p = string.lower(p);

   for index2, poi2 in AutoTravel_POI_SplitPOIList(p) do
      if search == poi2 then
	 return true;
      end
      local cat, name = AutoTravel_POI_SplitPOISub(poi2);
      if cat then
	 if search == cat then
	    return true;
	 end
	 if search == name then
	    return true;
	 end
      end
   end
   return false;
end

-- This function was written by Itchyban. Thanks!
function AutoTravel_POI_IsPartialMatch(search, point)
   search = string.lower(search);

   local search_len = string.len(search);

   local p = point.poi;
   p = string.lower(p);

   for index2, poi2 in AutoTravel_POI_SplitPOIList(p) do
      if search == string.sub(poi2, 1, search_len) then
	 return true;
      end
      local cat, name = AutoTravel_POI_SplitPOISub(poi2);
      if cat then
	 if search == string.sub(cat, 1, search_len) then
	    return true;
	 end
	 if search == string.sub(name, 1, search_len) then
	    return true;
	 end
      end
   end
   return false;
end

function AutoTravel_Show_POI_Menu()
   DropDownList1:Hide();

   local x, y = GetCursorPosition(); 
   if x > UIParent:GetWidth() - 200 then
      x = UIParent:GetWidth() - 200;
   end
   if y < 300 then
      y = 300;
   end
   AutoTravel_POI_Menu_OnLoad();
   ToggleDropDownMenu(1, nil, AutoTravel_POI_Menu, "UIParent", x, y);
end

function AutoTravel_POI_Menu_OnLoad()
   if AutoTravelSettings.local_poi then
      UIDropDownMenu_Initialize(AutoTravel_POI_Menu, AutoTravel_POI_Menu_Initialize_local, "MENU");
   else
      UIDropDownMenu_Initialize(AutoTravel_POI_Menu, AutoTravel_POI_Menu_Initialize_global, "MENU");
   end
end

function AutoTravel_POI_Menu_Initialize_global(level)
   return AutoTravel_POI_Menu_Initialize_shared(level, false);
end

function AutoTravel_POI_Menu_Initialize_local(level)
   return AutoTravel_POI_Menu_Initialize_shared(level, true);
end

function AutoTravel_POI_Menu_Initialize_shared(level, loc)
   if not level then
      return;
   end

   local c = 0;

   local poi_list = ATStatus.poi_list;
   local poi_sublist = ATStatus.poi_sublist;

   if loc then
      local zonemap = MapLibrary.GetCurrentZoneMap();
      if not zonemap then
	 return;
      end
      poi_list = ATStatus.poi_zone_list[zonemap];
      poi_sublist = ATStatus.poi_zone_sublist[zonemap];
   end

   if level > 1 and type(UIDROPDOWNMENU_MENU_VALUE) == "string" then
      local info = {};
      info.text = AUTOTRAVEL_POINTS_OF_INTEREST;
      info.notClickable = 1;
      info.isTitle = 1;
      UIDropDownMenu_AddButton(info, level); c = c + 1;
      
      if not poi_list then
	 return;
      end

      local category = UIDROPDOWNMENU_MENU_VALUE;
      
      local pois = { };
      local poicount = { };
      for poi, count in poi_sublist[category] do
	 poicount[poi] = count;
	 pois[poi] = 1;
      end
      
      -- this is to get it sorted.
      local pois2 = { };
      for poi, tmp in pois do
	 table.insert(pois2, poi);
      end
      table.sort(pois2);
      
      for index, poi in pois2 do
	 local info = {};
	 info.text = ATStatus.poi_namelist[poi] .. GREEN_FONT_COLOR_CODE .. " [" .. poicount[poi] .. "]" .. FONT_COLOR_CODE_CLOSE;
	 info.value = category .. "||" .. poi;
	 info.func = AutoTravel_MainFrame_Poi_OnClick;
	 if c <= 32 then
	    UIDropDownMenu_AddButton(info, level); c = c + 1;
	 end
      end
   else
      local info = {};
      info.text = AUTOTRAVEL_POINTS_OF_INTEREST;
      info.notClickable = 1;
      info.isTitle = 1;
      UIDropDownMenu_AddButton(info, level);
	 
      if not poi_list then
	 return;
      end

      local pois = { };
      local poicount = { };

      for poi, count in poi_list do
	 poicount[poi] = count;
	 local cat, name = AutoTravel_POI_SplitPOISub(poi);
	 if cat then
	    pois[cat] = 2;
	 elseif not pois[poi] then
	    pois[poi] = 1;
	 end
      end
      
      -- this is to get it sorted.
      local pois2 = { };
      for poi, tmp in pois do
	 table.insert(pois2, poi);
      end
      table.sort(pois2);
      
      for index, poi in pois2 do
	 local info = {};
	 info.value = poi;
	 info.text = ATStatus.poi_namelist[poi] .. GREEN_FONT_COLOR_CODE ..
	    " [" .. poicount[poi] .. "]" .. FONT_COLOR_CODE_CLOSE;

	 if pois[poi] == 2 then
	    info.hasArrow = 1;
	 end
	 info.func = AutoTravel_MainFrame_Poi_OnClick;
	 if c <= 32 then
	    UIDropDownMenu_AddButton(info, level); c = c + 1;
	 end
      end
   end
end

function AutoTravel_MainFrame_Poi_OnClick()
   CloseDropDownMenus(1);
   AutoTravel_CalculatePath(nil, nil, nil, this.value);
end

function AutoTravel_POI_SetPoi(point, poi)
   if point.poi then
      AutoTravel_POI_RemovePOI(point.poi, point.zone);
   end
   
   if poi == "" then
      poi = nil;
   end

   point.poi = poi;

   if point.poi then
      AutoTravel_POI_AddPOI(point.poi, point.zone);
   end
end
