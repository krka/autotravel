function AutoTravel_GetDistance()
   if not ATStatus.posx then
      return 0;
   end
   if ATStatus.path and not ATStatus.paused then
      local count = table.getn(ATStatus.path);
      local end_point = ATStatus.path[count];

      local total_distance = end_point.distance;

      local distance = total_distance - ATStatus.path[1].distance;
      -- Actually, I need to check if need to walk to road first... but this is a good approximation anyway.
      local point = AutoTravel_GetPoint(ATStatus.path[1].point);
      local dx, dy = ATStatus.posx - point.x, ATStatus.posy - point.y;
      distance = distance + MapLibrary.YardDistance(ATStatus.posx, ATStatus.posy, point.x, point.y);
	 
      if GetLocale() == "deDE" then
	 -- Germans apparently want distance in meters.
	 distance = distance * 0.9144;
      end

      return distance;
   end
   return nil;
end

function AutoTravel_GetETA()
   if not ATStatus.path or ATStatus.paused or ATStatus.speed == 0 then
      return nil;
   end
   return AutoTravel_GetDistance() / ATStatus.speed;
end

function AutoTravel_PointOnRoad(px, py, point1_index, point2_index)

   local point1 = AutoTravel_GetPoint(point1_index);
   local point2 = AutoTravel_GetPoint(point2_index);

   if not point1 or not point2 then
      return nil;
   end

   local v1x, v1y = point1.x - point2.x, point1.y - point2.y;
   local len = math.sqrt(v1x * v1x + v1y * v1y);
   v1x = v1x / len;
   v1y = v1y / len;
	    
   local v2x, v2y = px - point2.x, py - point2.y;
	    
   local dot = v1x * v2x + v1y * v2y;

   if dot >= 0 and dot <= len then
      return point2.x + dot * v1x, point2.y + dot * v1y;
   end

   return nil;
end

function AutoTravel_Pause_Resume()
   if ATStatus.path then
      if ATStatus.paused then
	 AutoTravel_Resume();
      else
	 AutoTravel_Pause();
      end
   end
end

function AutoTravel_Stop()
   if ATStatus.path then
      AutoTravelAPI.TriggerEvent("OnStop");
   end
   ATStatus.path = nil;
   ATStatus.paused = nil;
   ATStatus.stuck_timer = nil;

   MoveForwardStop(0);
   TurnLeftStop(0);
   TurnRightStop(0);
   AutoTravel_MapFrame_Dirty = 1;

   AutoTravel_UpdateUI();
end

function AutoTravel_Pause()
   if not ATStatus.paused then
      AutoTravelAPI.TriggerEvent("OnPause");
   end
   ATStatus.paused = true;
   ATStatus.stuck_timer = nil;

   MoveForwardStop(0);
   TurnLeftStop(0);
   TurnRightStop(0);

   AutoTravel_UpdateUI();
end

function AutoTravel_Resume()
   if ATStatus.paused then
      AutoTravelAPI.TriggerEvent("OnResume");
   end
   ATStatus.paused = nil;
   if ATStatus.path then
      -- Need to recalculate the path!
      local last_index = table.getn(ATStatus.path);
      local last_point = ATStatus.path[last_index].point;
      AutoTravel_CalculatePath(last_point);
   end
end

function AutoTravel_FollowPath()
   local next_point;
   local p;

   AutoTravel_GetDirection();

   if not ATStatus.posx then
      AutoTravel_Pause(); 
      return;
   end

   AutoTravel_UpdateUI();

   while table.getn(ATStatus.path) > 0 do
      next_point = ATStatus.path[1];

      p = AutoTravel_GetPoint(next_point.point);

      if AutoTravel_IsAtPoint(p.x, p.y) then
	 ATStatus.path_from = next_point.point;
	 table.remove(ATStatus.path, 1);
	 AutoTravelAPI.TriggerEvent("OnWaypointReached");
	 if not ATStatus.path or ATStatus.paused then
	    return;
	 end

	 AutoTravel_MapFrame_Dirty = 1;
      else
	 break;
      end
   end
   
   if table.getn(ATStatus.path) > 0 then
      if ATStatus.path_from then
	 local point_on_road_x, point_on_road_y = AutoTravel_PointOnRoad(ATStatus.posx, ATStatus.posy, ATStatus.path_from, next_point.point);
	 if point_on_road_x then

	    local dx, dy = point_on_road_x - ATStatus.posx, point_on_road_y - ATStatus.posy;
	    local distance = MapLibrary.YardDistance(point_on_road_x, point_on_road_y,
					  ATStatus.posx, ATStatus.posy);
	    if distance > 10 then
	       AutoTravel_MoveToPoint(point_on_road_x, point_on_road_y);
	       return;
	    end

	    local p2x, p2y = p.x + point_on_road_x - ATStatus.posx, p.y + point_on_road_y - ATStatus.posy;
	    AutoTravel_MoveToPoint(p2x, p2y);
	    return;
	 end
      end
      AutoTravel_MoveToPoint(p.x, p.y);
      return;
   end

   AutoTravelAPI.TriggerEvent("OnArrive");

   AutoTravel_Stop();
end

function AutoTravel_IsAtPoint(destx, desty)
   local distance = MapLibrary.YardDistance(destx, desty,
				 ATStatus.posx, ATStatus.posy);

   -- no particular reason why I chose this number. Experimental value.
   return distance < ATStatus.speed / 5;
end

function AutoTravel_TurnToDirection(dir_x, dir_y)
   if ATStatus.turn_done and GetTime() < ATStatus.turn_done then
      return;
   end

   if GetFramerate() < 5 then
      MoveForwardStop();
      return;
   end

   MoveForwardStart(0);

   -- If you first become slow, and then don't get anywhere in some time,
   -- you're stuck!
   if ATStatus.stuck_timer then
      local dist = MapLibrary.YardDistance(ATStatus.posx, ATStatus.posy,
				ATStatus.stuck_position_x, ATStatus.stuck_position_y);
      
      if dist < 1 then
	 if GetTime() - ATStatus.stuck_timer > 4 then
	    AutoTravelAPI.TriggerEvent("OnStuck");
	    AutoTravel_Pause();
	    return;
	 end
      else
	 ATStatus.stuck_timer = nil;
	 ATStatus.stuck_position_x = nil;
	 ATStatus.stuck_position_y = nil;
      end
   elseif ATStatus.speed < 0.1 then
      ATStatus.stuck_position_x, ATStatus.stuck_position_y = ATStatus.posx, ATStatus.posy;
      ATStatus.stuck_timer = GetTime();
   end

   -- Need to check speed when crossing zones due to lack of precision in
   -- coordinate translations
   if ATStatus.speed < 0.1 or ATStatus.speed > 100 then
      return;
   end

   -- cos(v) = dot => angle = acos(dot)
   -- Not in radians, weird.
   local dot = ATStatus.dir_x * dir_x + ATStatus.dir_y * dir_y;
   local angle = acos(dot);

   -- Assume this speed (experimental value!)
   -- Assuming no acceleration
   local anglespeed = 360.0 / 2.0;

   -- Make sure we don't turn for too long.
   local time_to_turn = 0.9 * angle / anglespeed;

   ATStatus.turn_done = GetTime() + time_to_turn;

   -- At what angle do we need to stop moving?
   -- Always stop when the angle is greater than 60
   local angle_to_stop = 60;

   if angle > 1 then

      if angle > angle_to_stop then
	 MoveForwardStop(0);
      end

      local cross = ATStatus.dir_x * dir_y - ATStatus.dir_y * dir_x;
      if cross > 0 then
	 TurnRightStop(0);
	 TurnRightStart(0);
	 TurnRightStop(ATStatus.turn_done * 1000);
      else
	 TurnRightStop(0);
	 TurnLeftStart(0);
	 TurnLeftStop(ATStatus.turn_done * 1000);
      end
   else
      TurnLeftStop(0);
      TurnRightStop(0);
   end
end

function AutoTravel_MoveToPoint(dest_x, dest_y)
   local dx, dy = MapLibrary.TranslateWorldToYards(dest_x - ATStatus.posx, dest_y - ATStatus.posy);
   local len = math.sqrt(dx * dx + dy * dy);
   if len > 0 then
      dx = dx / len;
      dy = dy / len;
   end
   AutoTravel_TurnToDirection(dx, dy);
end

function AutoTravel_CalculatePath(dest_point, dest_zone, dest_subzone, dest_poi)
   AutoTravel_Stop();

   if dest_zone then
      dest_zone = string.lower(dest_zone);
   end

   if dest_subzone then
      dest_subzone = string.lower(dest_subzone);
   end

   if dest_poi then
      dest_poi = string.lower(dest_poi);
   end
   
   local posx, posy = MapLibrary.GetWorldPosition("player");
   if not posx then
      return false;
   end

   -- Find nearest point
   local best_point, best_distance = AutoTravel_NearestPoint(posx, posy);
   if not best_point then
      AutoTravel_UpdateUI();
      return false;
   end

   if best_distance > 100 then
      AutoTravel_UpdateUI();
      return false;
   end

   if dest_point and not AutoTravel_IsConnected(best_point, dest_point) then
      AutoTravel_UpdateUI();
      return false;
   end 

   -- Find nearest road
   local best_point1 = 0;
   local best_point2 = 0;
   local best_distance2 = 0;
   best_point1, best_point2, best_distance2 = AutoTravel_NearestRoad(posx, posy);

   local queue = {};
   local visited = { };
   local from = { };
   local pointlist = { };
   local visited_points = 0;

   if best_point1 and best_distance2 < best_distance then
      local por_x, por_y = AutoTravel_PointOnRoad(posx, posy, best_point1, best_point2);

      local distance = MapLibrary.YardDistance(por_x, por_y, posx, posy);

      -- point 1
      local node1 = { };
      local p = AutoTravel_GetPoint(best_point1);

      node1.distance = distance + MapLibrary.YardDistance(por_x, por_y, p.x, p.y);
      node1.point = best_point1;

      visited_points = visited_points + 1;
      node1.pointlist_index = visited_points;
      table.insert(pointlist, node1);
      AutoTravel_PQAdd(queue, node1);

      -- point 2
      local node2 = { };
      p = AutoTravel_GetPoint(best_point2)

      node2.distance = distance + MapLibrary.YardDistance(por_x, por_y, p.x, p.y);
      node2.point = best_point2;

      visited_points = visited_points + 1;
      node2.pointlist_index = visited_points;
      table.insert(pointlist, node2);
      AutoTravel_PQAdd(queue, node2);
   else
      local node = { };
      local p = AutoTravel_GetPoint(best_point)

      node.distance = MapLibrary.YardDistance(posx, posy, p.x, p.y);
      node.point = best_point;

      visited_points = visited_points + 1;
      node.pointlist_index = visited_points;
      table.insert(pointlist, node);
      AutoTravel_PQAdd(queue, node);
   end

   local player_faction = UnitFactionGroup("player");
   local dead = UnitIsDeadOrGhost("player");
   while table.getn(queue) ~= 0 do
      local point = queue[1];
      table.remove(queue, 1);

      if not visited[point.point] then
	 visited[point.point] = true;

	 local point_coords = AutoTravel_GetPoint(point.point);
	 local faction_ok = dead or (point_coords.faction == nil) or (point_coords.faction == player_faction);

	 if faction_ok then
	    local zone_ok = (dest_zone == nil) or string.find(string.lower(point_coords.zone), dest_zone, 1, 1);
	    local subzone_ok = zone_ok and ((dest_subzone == nil) or string.find(string.lower(point_coords.subzone), dest_subzone, 1, 1));
	    local point_ok = (dest_point == nil) or (point.point == dest_point);
	    local poi_ok = (dest_poi == nil) or (point_coords.poi and AutoTravel_POI_IsMatch(dest_poi, point_coords));

	    if zone_ok and subzone_ok and point_ok and poi_ok and faction_ok then
	       AutoTravel_Stop();
	       ATStatus.path = { };
	       while true do
		  table.insert(ATStatus.path, 1, point);
		  local next_point = point.from;
		  if next_point == nil then
		     if best_point1 and best_distance2 < best_distance then
			if point.point == best_point1 then
			   ATStatus.path_from = best_point2;
			else
			   ATStatus.path_from = best_point1;
			end
		     else
			ATStatus.path_from = nil;
		     end
		     ATStatus.paused = nil;
		     AutoTravel_MapFrame_Dirty = 1;
		     AutoTravelAPI.TriggerEvent("OnStart");
		     return true;
		  end
		  point = pointlist[next_point];
	       end
	    end
	    for index, tmp in AutoTravel_GetRoads(point.point) do
	       local point_coords2 = AutoTravel_GetPoint(index);
	       if point_coords2 then
		  local new_node = { };
		  new_node.from = point.pointlist_index;
		  new_node.point = index;
		  
		  new_node.distance = point.distance +
		     MapLibrary.YardDistance(point_coords.x, point_coords.y,
					     point_coords2.x, point_coords2.y);
		  
		  visited_points = visited_points + 1;
		  new_node.pointlist_index = visited_points;
		  table.insert(pointlist, new_node);
		  AutoTravel_PQAdd(queue, new_node);
	       end
	    end
	 end
      end
   end
   AutoTravel_UpdateUI();
   return false;
end

-- Implementation of priority queue, used for finding best path
function AutoTravel_PQAdd(queue, node)
   local min = 1;
   local max = table.getn(queue) + 1;

   -- binary search for where to insert the new node
   while min < max do
      -- center is rounded down
      local center = math.floor((min + max) / 2);

      if node.distance < queue[center].distance then
	 max = center;
      else
	 min = center + 1;
      end
   end

   -- Insert before min, since this is smaller than min
   table.insert(queue, min, node)
end
