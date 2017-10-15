function AutoTravel_AddPointToZones(point)
   local point_coord = AutoTravel_GetPoint(point);
   for zone, tmp in MapLibraryData.translation do
      
      if not ATStatus.zone_points[zone] then
	 ATStatus.zone_points[zone] = { };
      end

      local vx, vy = MapLibrary.TranslateWorldToZone(point_coord.x, point_coord.y, zone);
      if vx and vx > 0 and vy > 0 and vx < 1 and vy < 1 then
	 ATStatus.zone_points[zone][point] = true;
      end
   end
end

function AutoTravel_RemovePointFromZones(point)
   for zone, tmp in ATStatus.zone_points do
      ATStatus.zone_points[zone][point] = nil;
   end
end

function AutoTravel_AddPointsToZone(zone)
   local a2x, a2y = MapLibrary.TranslateZoneToWorld(0, 0, zone);
   local b2x, b2y = MapLibrary.TranslateZoneToWorld(1, 1, zone);

   ATStatus.zone_points[zone] = { };
   
   for index, point in AutoTravel_GetPoints() do
      if point.x > a2x and point.y > a2y and
	 point.x < b2x and point.y < b2y then
	 ATStatus.zone_points[zone][index] = true;
      end
   end
end

function AutoTravel_AddPointsToZones()
   for zone, tmp in MapLibraryData.translation do
      if MapLibrary.ZoneIsCalibrated(zone) then
	 AutoTravel_AddPointsToZone(zone);
      end
   end
end
