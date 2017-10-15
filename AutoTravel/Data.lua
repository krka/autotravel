function AutoTravel_SetupData()
   if AutoTravelData == nil then
      AutoTravelData = { };
   end

   if AutoTravelData.version == nil then
      AutoTravelData.version = 2;
   end

   if AutoTravelData.settings == nil then
      AutoTravelData.settings = { };
   end

   if AutoTravelData.settings[Fetch_PlayerInfo] == nil then
      AutoTravelData.settings[Fetch_PlayerInfo] = { };
   end

   AutoTravelSettings = AutoTravelData.settings[Fetch_PlayerInfo];
   if AutoTravelSettings.autoroad == nil then
      AutoTravelSettings.autoroad = true;
   end

   if AutoTravelSettings.autoroad2 == nil then
      AutoTravelSettings.autoroad2 = false;
   end

   if AutoTravelSettings.hidden == nil then
      AutoTravelSettings.hidden = false;
   end

   if AutoTravelSettings.togglemap_onwalk == nil then
      AutoTravelSettings.togglemap_onwalk = true;
   end

   if AutoTravelSettings.replace_point == nil then
      AutoTravelSettings.replace_point = false;
   end

   if AutoTravelSettings.show_eta == nil then
      AutoTravelSettings.show_eta = false;
   end

   if AutoTravelSettings.hide2roads == nil then
      AutoTravelSettings.hide2roads = false
   end

   if AutoTravelSettings.hide_roads == nil then
      AutoTravelSettings.hide_roads = false
   end

   if AutoTravelSettings.hide_other_zones == nil then
      AutoTravelSettings.hide_other_zones = false
   end

   if AutoTravelSettings.fade_non_poi == nil then
      AutoTravelSettings.fade_non_poi = false
   end

   if AutoTravelSettings.player_visible == nil then
      AutoTravelSettings.player_visible = false
   end

   if AutoTravelSettings.mapalpha == nil then
      AutoTravelSettings.mapalpha = 1
   end

   if AutoTravelSettings.wheelzoom == nil then
      AutoTravelSettings.wheelzoom = false
   end

   if AutoTravelSettings.local_poi == nil then
      AutoTravelSettings.local_poi = false
   end

   if AutoTravelSettings.partial_matching == nil then
      AutoTravelSettings.partial_matching = false
   end

   if AutoTravelData.points == nil then
      AutoTravelData.points = { };
      AutoTravelData.next_point_id = 1;
   end

   if AutoTravelData.roads == nil then
      AutoTravelData.roads = { };
   end

   for index, data in AutoTravelData.points do
      if data.subzone == data.zone or data.subzone == nil then
	 data.subzone = "";
      end
   end

   ATStatus.zone_points = { };
   -- Temporary stuff -  add translations to MapLibrary
   -- To be removed in later versions when basically everyone
   -- has already converted
   if AutoTravelData.translation then
      for zone, trans in AutoTravelData.translation do
	 if not MapLibrary.ZoneIsCalibrated(zone) and trans.offset_x then
	    MapLibraryData.translation[zone] = trans;
	 end
      end
   end
  
   AutoTravel_AddPointsToZones();

   AutoTravel_POI_Setup();

   -- Faction stuff
   ATStatus.faction_id = { };
   for i = 1, GetNumFactions() do
      local name = GetFactionInfo(i);
      ATStatus.faction_id[name] = i;
   end
end

-- O(n), don't use it too much. n = number of points in world
function AutoTravel_NearestPoint(posx, posy)
   local best_index = nil;
   local best_distance = nil;
   for index, point in AutoTravelData.points do
      local d = MapLibrary.YardDistance(posx, posy, point.x, point.y);
      if not best_index or d < best_distance then
	 best_index, best_distance = index, d;
      end
   end
   return best_index, best_distance;
end

function AutoTravel_NearestRoad(posx, posy)
   local best_point1 = nil;
   local best_point2 = nil;
   local best_distance2 = nil;

   for point1_index, point1 in AutoTravel_GetPoints() do
      for point2_index, tmp in AutoTravel_GetRoads(point1_index) do
	 -- no use in checking each road twice
	 if point1_index < point2_index then
	    local point2 = AutoTravel_GetPoint(point2_index);
	    if point2 then
	       local v1x, v1y = point1.x - point2.x, point1.y - point2.y;
	       local len = math.sqrt(v1x * v1x + v1y * v1y);
	       if len > 0 then
		  v1x = v1x / len;
		  v1y = v1y / len;
	       end

	       local v2x, v2y = posx - point2.x, posy - point2.y;
	    
	       local dot = v1x * v2x + v1y * v2y;

	       if dot >= 0 and dot <= len then
		  local point3x, point3y = point2.x + dot * v1x, point2.y + dot * v1y;

		  local distance = MapLibrary.YardDistance(point3x, point3y, posx, posy);
		  if best_point1 == nil or distance < best_distance2 then
		     best_point1, best_point2, best_distance2 = point1_index, point2_index, distance;
		  end
	       end
	    end
	 end
      end
   end
   return best_point1, best_point2, best_distance2;
end

function AutoTravel_AddPoint(posx, posy, zone, subzone)
   if not zone then
      zone = MapLibrary.GetCurrentZoneMap();
      if not zone then
	 return;
      end
   end

   if not subzone then
      subzone = GetSubZoneText();
   end

   if subzone == zone then
      subzone = "";
   elseif subzone == "" then
      subzone = GetRealZoneText();
   end

   local index, d = AutoTravel_NearestPoint(posx, posy);
   if index and d < 0.1 then
      -- Move nearest point
      if AutoTravelSettings.replace_point then
	 AutoTravelData.points[index].x = posx;
	 AutoTravelData.points[index].y = posy;
	 AutoTravelData.points[index].zone = zone;
	 AutoTravelData.points[index].subzone = subzone;
	 AutoTravel_MapFrame_Dirty = 1;
      end
      ATStatus.previously_added = index;
      return index;
   else
      -- Make new point
      local index2 = AutoTravelData.next_point_id;
      AutoTravelData.next_point_id = index2 + 1;

      AutoTravelData.points[index2] = { };
      AutoTravelData.points[index2].x = posx;
      AutoTravelData.points[index2].y = posy;
      AutoTravelData.points[index2].zone = zone;
      AutoTravelData.points[index2].subzone = subzone;
      
      AutoTravelData.roads[index2] = { };

      AutoTravel_ConnectionAdd(index2, index2);

      local b = true;
      if AutoTravelSettings.autoroad2 and
	 ATStatus.previously_added and
	 AutoTravel_GetPoint(ATStatus.previously_added) then
	 local p = AutoTravel_GetPoint(ATStatus.previously_added);
	 local distance = MapLibrary.YardDistance(p.x, p.y, posx, posy);
	 if distance< 100 then
	    b = false;
	    AutoTravel_AddRoad(index2, ATStatus.previously_added);
	 end
      end
      if b and index and AutoTravelSettings.autoroad then
	 local p = AutoTravel_GetPoint(index);
	 local distance = MapLibrary.YardDistance(p.x, p.y, posx, posy);
	 if distance < 100 then
	    AutoTravel_AddRoad(index, index2);
	 end
      end

      AutoTravel_AddPointToZones(index2);
      ATStatus.previously_added = index2;
      AutoTravel_MapFrame_Dirty = 1;
      return index2;
   end
end

function AutoTravel_RemovePoint(p)
   local point_coords = AutoTravel_GetPoint(p);
   AutoTravel_POI_SetPoi(point_coords, nil);

   -- Remove neighbouring roads
   for p2, tmp in AutoTravelData.roads do
      AutoTravel_RemoveRoad(p, p2, true);
   end

   ATStatus.connected_valid = nil;
   ATStatus.connected_sets[p] = nil;

   AutoTravelData.roads[p] = nil;
   AutoTravelData.points[p] = nil;

   AutoTravel_RemovePointFromZones(p);

   if ATStatus.path then

      local count = table.getn(ATStatus.path);
      local end_point = ATStatus.path[count].point;
      if end_point == p then
	 AutoTravel_Stop();
      elseif not ATStatus.paused then
	 for index, p2 in ATStatus.path do
	    if p2.point == p then
	       AutoTravel_CalculatePath(end_point);
	       break;
	    end
	 end
      end
   end
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_GetPoint(p)
   return AutoTravelData.points[p];
end

function AutoTravel_GetPoints()
   return AutoTravelData.points;
end

function AutoTravel_IsRoad(p1, p2)
   return AutoTravelData.roads[p1][p2];
end

function AutoTravel_GetRoads(p)
   return AutoTravelData.roads[p];
end

function AutoTravel_AddRoad(p1, p2)
   AutoTravelData.roads[p1][p2] = true;
   AutoTravelData.roads[p2][p1] = true;

   AutoTravel_ConnectionAdd(p1, p2);
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_RemoveRoad(p1, p2, skipcheck)
   AutoTravelData.roads[p1][p2] = nil;
   AutoTravelData.roads[p2][p1] = nil;

   ATStatus.connected_valid = nil;

   if ATStatus.path and not skipcheck then
      local count = table.getn(ATStatus.path);
      local end_point = ATStatus.path[count].point;
      local start_point = ATStatus.path[1].point;
      if not AutoTravel_IsConnected(start_point, end_point) then
	 AutoTravel_Stop();
      end
   end
   AutoTravel_MapFrame_Dirty = 1;
end
