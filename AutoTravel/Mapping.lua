function AutoTravel_GetDirection()
   ATStatus.oldx, ATStatus.oldy = ATStatus.posx, ATStatus.posy;
   ATStatus.posx, ATStatus.posy = MapLibrary.GetWorldPosition("player");

   if not ATStatus.posx or not ATStatus.oldx then
      ATStatus.dir_x, ATStatus.dir_y = 0, 0;
      ATStatus.speed = 0;
      return;
   end

   local zone = MapLibrary.GetMapZoneName();
   if zone ~= ATStatus.zone then
      ATStatus.zone = zone;
      ATStatus.oldx, ATStatus.oldy = ATStatus.posx, ATStatus.posy;
   end
   local dir_x, dir_y = MapLibrary.TranslateWorldToYards(ATStatus.posx - ATStatus.oldx,
					      ATStatus.posy - ATStatus.oldy);

   local dir_size = math.sqrt(dir_x * dir_x + dir_y * dir_y);
   if dir_size > 0 then
      dir_x = dir_x / dir_size;
      dir_y = dir_y / dir_size;
   end

   ATStatus.speed = 0;
   local time = GetTime();
   if ATStatus.last_get_direction_time then
      local dtime = time - ATStatus.last_get_direction_time;

      ATStatus.speed = dir_size / dtime;
   end
   ATStatus.last_get_direction_time = time;

   ATStatus.dir_x, ATStatus.dir_y = dir_x, dir_y;
   ATStatus.dir_size = dir_size;
end
