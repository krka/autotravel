-- Minimize interference with WorldMap

function AutoTravel_GetMapData(zone)
   if not ATStatus.map_cache then
      ATStatus.map_cache = { };
   end
   if not ATStatus.map_cache[zone] or zone == MapLibrary.GetMapZoneName() then
      if not ATStatus.map_cache[zone] then
	 ATStatus.map_cache[zone] = { };

	 local id = MapLibrary.mappedzone[zone];
	 if id then
	    SetMapZoom(id.continent, id.zone);
	 end
      end
      ATStatus.map_cache[zone].filename = GetMapInfo();
      if ATStatus.map_cache[zone].filename == nil then
	 ATStatus.map_cache[zone].filename = "World";
      end
      local n_overlays = GetNumMapOverlays();
      ATStatus.map_cache[zone].n_overlays = n_overlays;

      if not ATStatus.map_cache[zone].overlays then
	 ATStatus.map_cache[zone].overlays = { };
      end

      local textureName, textureWidth, textureHeight, offsetX, offsetY;
      for i = 1, n_overlays do
	 textureName, textureWidth, textureHeight, offsetX, offsetY = GetMapOverlayInfo(i);
	 ATStatus.map_cache[zone].overlays[i] = {textureName, textureWidth, textureHeight, offsetX, offsetY};
      end
   end
   return ATStatus.map_cache[zone];
end
