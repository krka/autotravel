function AutoTravel_MapFrame_Setup()
   AutoTravel_MapFrame_Zone = MapLibrary.GetMapZoneName();
   if not AutoTravel_MapFrame_Zone then
      AutoTravel_MapFrame_Zone = "World";
   end
   AutoTravel_MapFrame_Dirty = 1;

   AutoTravel_MapFrame:SetMinResize(350, 200);

   AutoTravel_MapFrame_AlwaysVisibleLabel:SetText(AUTOTRAVEL_ALWAYS_VISIBLE);

   if AutoTravelSettings.player_visible then
      AutoTravel_MapFrame_AlwaysVisible:SetChecked(1);
   end

   AutoTravel_UpdateAlpha();

   AutoTravelAPI.RegisterEvent("OnResume", AutoTravel_TurnOnAlwaysFollow);
   AutoTravelAPI.RegisterEvent("OnStart", AutoTravel_TurnOnAlwaysFollow);
end

function AutoTravel_ToggleMapVisible()
   if AutoTravel_MapFrame:IsVisible() then
      AutoTravel_MapFrame:Hide();
   else
      AutoTravel_MapFrame:Show();
   end
end

function AutoTravel_MapFrame_StartMove(arg1)
   if arg1 == "LeftButton" then
      AutoTravel_MapFrame:StartMoving()
   end
end

function AutoTravel_MapFrame_StopMove(arg1)
   DropDownList1:Hide();
   if arg1 == "LeftButton" then
      AutoTravel_MapFrame:StopMovingOrSizing();
      AutoTravel_SetOffset();
   elseif arg1 == "RightButton" then
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

function AutoTravel_MapFrame_OnMouseUp(arg1)
   AutoTravel_MapFrame_IsDragging = nil;

   if not AutoTravelSettings.wheelzoom then

      local x, y = GetCursorPosition();

      if arg1 == "LeftButton" and
	 AutoTravel_ClickX == x and AutoTravel_ClickY == y then
	 AutoTravel_MapFrame_ZoomIn();
      elseif arg1 == "RightButton" then
	 AutoTravel_MapFrame_ZoomOut();
      end
   end
end

function AutoTravel_MapFrame_OnMouseDown(arg1)
   if arg1 == "RightButton" then
   elseif arg1 == "LeftButton" then
      DropDownList1:Hide();
      AutoTravel_MapFrame_DragStartX = nil;
      AutoTravel_MapFrame_DragStartY = nil;
      AutoTravel_MapFrame_IsDragging = 1;

      AutoTravel_ClickX, AutoTravel_ClickY = GetCursorPosition();
   end
end

function AutoTravel_MapFrame_OnMouseWheel(arg1)
   if AutoTravelSettings.wheelzoom then
      if arg1 > 0 then
	 AutoTravel_MapFrame_ZoomIn();
      elseif arg1 < 0 then
	 AutoTravel_MapFrame_ZoomOut();
      end
   end
end

function AutoTravel_MapFrame_ZoomIn()
   local x, y = GetCursorPosition();
   if AutoTravel_MapFrame_Zoom < 32 then
      AutoTravel_MapFrame_Zoom = AutoTravel_MapFrame_Zoom * 2;
      local x, y = GetCursorPosition();
      local vx = (x - AutoTravel_MapFrameContent:GetLeft());
      local vy = -(y - AutoTravel_MapFrameContent:GetTop());
      
      local rx = (vx + AutoTravel_MapFrame_ZoomOffsetX) * 2;
      local ry = (vy + AutoTravel_MapFrame_ZoomOffsetY) * 2;
      
      AutoTravel_SetOffset(rx - vx, ry - vy);
      AutoTravel_MapTitleText:SetText(AutoTravel_MapFrame_Zone .. " " .. AutoTravel_MapFrame_Zoom .. "x");
      ATStatus.previous_click = nil;
      AutoTravel_MapFrame_Dirty = 1;
   end
end

function AutoTravel_MapFrame_ZoomOut()
   if AutoTravel_MapFrame_Zoom > 1 then
      AutoTravel_MapFrame_Zoom = AutoTravel_MapFrame_Zoom / 2;
      local x, y = GetCursorPosition();
      local vx = (x - AutoTravel_MapFrameContent:GetLeft());
      local vy = -(y - AutoTravel_MapFrameContent:GetTop());
      
      local rx = (vx + AutoTravel_MapFrame_ZoomOffsetX) / 2;
      local ry = (vy + AutoTravel_MapFrame_ZoomOffsetY) / 2;
      
      AutoTravel_SetOffset(rx - vx, ry - vy);
      AutoTravel_MapTitleText:SetText(AutoTravel_MapFrame_Zone .. " " .. AutoTravel_MapFrame_Zoom .. "x");
   end
   ATStatus.previous_click = nil;
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_ClipTexture(object, parent, left, top, width, height, bx1, bx2, by1, by2)
   if left > bx2 or
      top > by2 or
      left + width < bx1 or
      top + height < by1 then
      object:Hide();
      return false;
   else
      local x1 = left;
      local y1 = top;

      local w = width;
      local h = height;

      local wtex1 = 0;
      local htex1 = 0;

      local wtex2 = 1;
      local htex2 = 1;

      if left <= bx1 and left + width >= bx2 then
	 w = bx2 - bx1;
	 wtex1 = (bx1 - left) / width;
	 wtex2 = (bx2 - left) / width;
	 x1 = bx1;
      elseif left <= bx1 then
	 w = left + width - bx1;
	 wtex1 = 1 - w / width;
	 x1 = bx1;
      elseif left + width >= bx2 then
	 w = bx2 - left;
	 wtex2 = w / width;
      end

      if top <= by1 and top + height >= by2 then
	 h = by2 - by1;
	 htex1 = (by1 - top) / height;
	 htex2 = (by2 - top) / height;
	 y1 = by1;
      elseif top <= by1 then
	 h = top + height - by1;
	 htex1 = 1 - h / height;
	 y1 = by1;
      elseif top + height >= by2 then
	 h = by2 - top;
	 htex2 = h / height;
      end

      if w < 1 or h < 1 then
	 object:Hide();
	 return false;
      else
	 object:SetTexCoord(wtex1, wtex2, htex1, htex2);
	 object:SetWidth(w);
	 object:SetHeight(h);
	 object:ClearAllPoints();
	 object:SetPoint("TOPLEFT", parent, "TOPLEFT", x1, -y1);
	 object:Show();
	 return true;
      end
   end
end

function AutoTravel_MapFrame_OnUpdate()
   local zone = AutoTravel_MapFrame_Zone;
   if not zone then
      zone = "World";
      AutoTravel_MapFrame_Zone = zone;
      AutoTravel_MapFrame_Dirty = 1;
   end

   if AutoTravel_MapFrame_VertDrag then
      local cx, cy = GetCursorPosition();
      local dy;
      if AutoTravel_MapFrame_VertDragStartY then
	 dy = (cy - AutoTravel_MapFrame_VertDragStartY);

	 if dy ~= 0 then
	    local bar_height = AutoTravel_MapFrame_VertScrollBar:GetHeight();
	    local zoom = AutoTravel_MapFrame_Zoom;
	    local fheight = AutoTravel_MapFrameContent:GetHeight() / AutoTravel_MapFrameContent:GetScale();
	    
	    dy = (dy / bar_height) * (zoom * fheight);
	    AutoTravel_SetOffset(nil, AutoTravel_MapFrame_ZoomOffsetY - dy);
	 end
      end
      AutoTravel_MapFrame_VertDragStartY = cy;
   end

   if AutoTravel_MapFrame_HoriDrag then
      local cx, cy = GetCursorPosition();
      local dx;
      if AutoTravel_MapFrame_HoriDragStartX then
	 dx = (cx - AutoTravel_MapFrame_HoriDragStartX);

	 if dx ~= 0 then
	    local bar_width = AutoTravel_MapFrame_HoriScrollBar:GetWidth();
	    local zoom = AutoTravel_MapFrame_Zoom;
	    local fwidth = AutoTravel_MapFrameContent:GetWidth() / AutoTravel_MapFrameContent:GetScale();
	    
	    dx = (dx / bar_width) * (zoom * fwidth);
	    AutoTravel_SetOffset(AutoTravel_MapFrame_ZoomOffsetX + dx, nil);
	 end
      end
      AutoTravel_MapFrame_HoriDragStartX = cx;
   end

   if AutoTravel_MapFrame_IsDragging then
      local cx, cy = GetCursorPosition();
      
      local dx, dy;
      if AutoTravel_MapFrame_DragStartX and AutoTravel_MapFrame_DragStartY then
	 dx = -(cx - AutoTravel_MapFrame_DragStartX);
	 dy = (cy - AutoTravel_MapFrame_DragStartY);

	 if dx ~= 0 or dy ~= 0 then
	    AutoTravel_TurnOffAlwaysFollow();

	    AutoTravel_SetOffset(AutoTravel_MapFrame_ZoomOffsetX + dx,
				 AutoTravel_MapFrame_ZoomOffsetY + dy);

	 end
      end

      AutoTravel_MapFrame_DragStartX = cx;
      AutoTravel_MapFrame_DragStartY = cy;
   end

   if AutoTravel_MapFrame_IsResizing or
      AutoTravel_MapFrame_Dirty then

      local diff = AutoTravel_MapFrameContent:GetHeight() - AutoTravel_MapFrameContent:GetWidth() * (668 / 1002);
      if abs(diff) > 3 then
	 AutoTravel_MapFrame:SetHeight(84 +
				       AutoTravel_MapFrameContent:GetWidth() *
					  (668 / 1002) / AutoTravel_MapFrameContent:GetScale()
				    );
      end

      AutoTravel_SetOffset();

      local zoom = AutoTravel_MapFrame_Zoom;

      local fwidth = AutoTravel_MapFrameContent:GetWidth() / AutoTravel_MapFrameContent:GetScale();
      local fheight = AutoTravel_MapFrameContent:GetHeight() / AutoTravel_MapFrameContent:GetScale();

      local data = AutoTravel_GetMapData(zone);
      local zone_texture = data.filename;

      local width = (256 / 1002) * fwidth * zoom;
      local height = (256 / 668) * fheight * zoom;

      local offset_y = 0;
      for y = 0, 2 do
	 local offset_x = 0;
	 for x = 0, 3 do
	    local i = x + 1 + 4 * y;

	    local obj = getglobal("AutoTravel_MapFrameContentMain" .. i);

	    obj:SetTexture("Interface\\WorldMap\\" .. zone_texture .. "\\" .. zone_texture .. i);
	    AutoTravel_ClipTexture(obj, "AutoTravel_MapFrameContent",
				   -AutoTravel_MapFrame_ZoomOffsetX + offset_x,
				   -AutoTravel_MapFrame_ZoomOffsetY + offset_y,
				   width, height,
				   0, fwidth, 0, fheight);

	    offset_x = offset_x + width;
	 end
	 offset_y = offset_y + height;
      end

      -- Overlay stuff
      local numOverlays = data.n_overlays;
      local textureName, textureWidth, textureHeight, offsetX, offsetY;
      local textureCount = 1;
      local texture;
      local texturePixelWidth, textureFileWidth, texturePixelHeight, textureFileHeight;
      local numTexturesWide, numTexturesTall;
      for i=1, numOverlays do
	 textureName = data.overlays[i][1];
	 textureWidth = data.overlays[i][2];
	 textureHeight = data.overlays[i][3];
	 offsetX = data.overlays[i][4];
	 offsetY = data.overlays[i][5];

	 numTexturesWide = ceil(textureWidth/256);
	 numTexturesTall = ceil(textureHeight/256);
	 for j=1, numTexturesTall do
	    if ( j < numTexturesTall ) then
	       texturePixelHeight = 256;
	       textureFileHeight = 256;
	    else
	       texturePixelHeight = mod(textureHeight, 256);
	       if ( texturePixelHeight == 0 ) then
		  texturePixelHeight = 256;
	       end
	       textureFileHeight = 16;
	       while(textureFileHeight < texturePixelHeight) do
		  textureFileHeight = textureFileHeight * 2;
	       end
	    end
	    for k=1, numTexturesWide do
	       if textureCount <= 40 then
		  if ( k < numTexturesWide ) then
		     texturePixelWidth = 256;
		     textureFileWidth = 256;
		  else
		     texturePixelWidth = mod(textureWidth, 256);
		     if ( texturePixelWidth == 0 ) then
			texturePixelWidth = 256;
		     end
		     textureFileWidth = 16;
		     while(textureFileWidth < texturePixelWidth) do
			textureFileWidth = textureFileWidth * 2;
		     end
		  end
		  local offset_x = offsetX + (256 * (k-1));
		  local offset_y = offsetY + (256 * (j - 1));
		  
		  offset_x = (offset_x / 1002) * zoom * fwidth;
		  offset_y = (offset_y / 668) * zoom * fheight;
		  
		  texture = getglobal("AutoTravel_MapFrameContentOverlay"..textureCount);
		  texture:SetTexture(textureName..(((j - 1) * numTexturesWide) + k));
		  if AutoTravel_ClipTexture(texture, "AutoTravel_MapFrameContent", -AutoTravel_MapFrame_ZoomOffsetX + offset_x, -AutoTravel_MapFrame_ZoomOffsetY + offset_y,
					    (textureFileWidth / 1002) * zoom * fwidth,
					    (textureFileHeight / 668) * zoom * fheight,
					    0, fwidth, 0, fheight)
		  then
		     textureCount = textureCount +1;
		  end
	       end
	    end
	 end
      end
      for i=textureCount, 40 do
	 getglobal("AutoTravel_MapFrameContentOverlay"..i):Hide();
      end
      
      AutoTravel_MapFrame_RepaintMap();
   end
   AutoTravel_MapFrame_Dirty = nil;
   AutoTravel_MapFrame_UpdatePlayer();
   AutoTravel_MapFrame_UpdateParty();
   AutoTravel_MapFrame_UpdateCorpse();
end

function AutoTravel_DrawLine(id, point1, point2, path)
   if not path then
      path = "";
   else
      path = "-path";
   end

   local line = getglobal("AutoTravel_Line_" .. id);
   local linetexture = getglobal("AutoTravel_Line_" .. id .. "Texture");

   local pcoords1 = AutoTravel_GetPoint(point1);
   local v1x, v1y = MapLibrary.TranslateWorldToZone(pcoords1.x, pcoords1.y, AutoTravel_MapFrame_Zone);

   local pcoords2 = AutoTravel_GetPoint(point2);
   local v2x, v2y = MapLibrary.TranslateWorldToZone(pcoords2.x, pcoords2.y, AutoTravel_MapFrame_Zone);

   local fwidth = AutoTravel_MapFrameContent:GetWidth() / AutoTravel_MapFrameContent:GetScale();
   local fheight = AutoTravel_MapFrameContent:GetHeight() / AutoTravel_MapFrameContent:GetScale();
   local zoom = AutoTravel_MapFrame_Zoom;

   v1x = v1x * fwidth * zoom - AutoTravel_MapFrame_ZoomOffsetX;
   v1y = v1y * fheight * zoom - AutoTravel_MapFrame_ZoomOffsetY;

   v2x = v2x * fwidth * zoom - AutoTravel_MapFrame_ZoomOffsetX;
   v2y = v2y * fheight * zoom - AutoTravel_MapFrame_ZoomOffsetY;

   -- Cut the line to fit on screen
   if v1x ~= v2x then
      if v1x < 0 then
	 v1y = v1y + (0 - v1x) * (v2y - v1y) / (v2x - v1x);
	 v1x = 0;
      elseif v1x > fwidth then
	 v1y = v1y + (fwidth - v1x) * (v2y - v1y) / (v2x - v1x);
	 v1x = fwidth;
      end
      if v2x < 0 then
	 v2y = v2y + (0 - v2x) * (v1y - v2y) / (v1x - v2x);
	 v2x = 0;
      elseif v2x > fwidth then
	 v2y = v2y + (fwidth - v2x) * (v1y - v2y) / (v1x - v2x);
	 v2x = fwidth;
      end
   end
   if v1y ~= v2y then
      if v1y < 0 then
	 v1x = v1x + (0 - v1y) * (v2x - v1x) / (v2y - v1y);
	 v1y = 0;	 
      elseif v1y > fheight then
	 v1x = v1x + (fheight - v1y) * (v2x - v1x) / (v2y - v1y);
	 v1y = fheight;	 
      end
      if v2y < 0 then
	 v2x = v2x + (0 - v2y) * (v1x - v2x) / (v1y - v2y);
	 v2y = 0;	 
      elseif v2y > fheight then
	 v2x = v2x + (fheight - v2y) * (v1x - v2x) / (v1y - v2y);
	 v2y = fheight;	 
      end
   end

   -- Don't draw if the line is off screen
   if (v1x < 0 and v2x < 0) or
      (v1x > fwidth and v2x > fwidth) or
      (v1y < 0 and v2y < 0) or
      (v1y > fheight and v2y > fheight) then
      return false;
   end

   local x1 = math.min(v1x, v2x);
   local y1 = math.min(v1y, v2y);

   local x2 = math.max(v1x, v2x);
   local y2 = math.max(v1y, v2y);

   if x1 < 0 or y1 < 0 or
      x2 > fwidth or y2 > fheight then
      return false;
   end
      
   local real_width = math.max(3, math.abs(v1x - v2x));
   local real_height = math.max(3, math.abs(v1y - v2y));

   if real_width == 3 and real_height == 3 then
      return false;
   end

   local thickness = math.min(1, math.min(real_height, real_width) / 256);

   linetexture:SetWidth(real_width);
   linetexture:SetHeight(real_height);

   if real_width == 3 or real_width == 3 then
      linetexture:SetTexture("Interface\\AddOns\\AutoTravel\\road" .. path);
      linetexture:SetTexCoord(0, 1, 0, 1);
   elseif (v1x < v2x) ~= (v1y < v2y) then
      linetexture:SetTexture("Interface\\AddOns\\AutoTravel\\lineup" .. path);
      linetexture:SetTexCoord(0, thickness, 1 - thickness, 1);
   else
      linetexture:SetTexture("Interface\\AddOns\\AutoTravel\\linedown" .. path);
      linetexture:SetTexCoord(0, thickness, 0, thickness);
   end
   line:SetPoint("TOPLEFT",
		 "AutoTravel_MapFrameContent", 
		 "TOPLEFT", x1, -y1);

   line:Show();

   return true;
end

function AutoTravel_MapFrame_UpdatePlayer()
   local t = AutoTravel_MapFrameContentPlayerIcon;

   local zone = AutoTravel_MapFrame_Zone;

   if zone then

      local mapzone = MapLibrary.GetCurrentZoneMap();

      local vx, vy = MapLibrary.GetWorldPosition("player", nil, 1);
      if vx then
	 vx, vy = MapLibrary.TranslateWorldToZone(vx, vy, zone);
	 if vx then
	    if vx > 0 and vy > 0 and vx < 1 and vy < 1 then
	       local fwidth = AutoTravel_MapFrameContent:GetWidth() / AutoTravel_MapFrameContent:GetScale();
	       local fheight = AutoTravel_MapFrameContent:GetHeight() / AutoTravel_MapFrameContent:GetScale();
	       local zoom = AutoTravel_MapFrame_Zoom;
	       
	       local x = vx * fwidth * zoom - AutoTravel_MapFrame_ZoomOffsetX;
	       local y = vy * fheight * zoom - AutoTravel_MapFrame_ZoomOffsetY;
	       
	       if x > 0 and y > 0 and x < fwidth and y < fheight then

		  t:ClearAllPoints();
		  t:SetPoint("CENTER", "AutoTravel_MapFrameContent", "TOPLEFT",
			     x, -y);
		  t:Show();
		  return;
	       elseif AutoTravel_MapFrame_AlwaysVisible:GetChecked() then
		  AutoTravel_SetOffset(AutoTravel_MapFrame_ZoomOffsetX + x - fwidth / 2,
				       AutoTravel_MapFrame_ZoomOffsetY + y - fheight / 2);
	       end
	    else
	       if AutoTravel_MapFrame_AlwaysVisible:GetChecked() and MapLibrary.mappedzone[mapzone] then
		  AutoTravel_SetMapZone(mapzone);
	       end
	    end
	 else
	    if AutoTravel_MapFrame_AlwaysVisible:GetChecked() and MapLibrary.mappedzone[mapzone] then
	       AutoTravel_SetMapZone(mapzone);
	    end
	 end
      else
	 if AutoTravel_MapFrame_AlwaysVisible:GetChecked() then
	    MapLibrary.GetWorldPosition("player");
	 end
      end
   end
   t:Hide();
end

function AutoTravel_MapFrame_UpdateParty()
   for i = 1, 4 do
      local t = getglobal(ATStatus.party_str[i]);

      local b = true;

      local zone = AutoTravel_MapFrame_Zone;
      if zone then
	 local vx, vy = MapLibrary.GetWorldPosition("party" .. i, nil, 1);
	 if vx then
	    vx, vy = MapLibrary.TranslateWorldToZone(vx, vy, zone);
	    if vx then
	       if vx > 0 and vy > 0 and vx < 1 and vy < 1 then
		  local fwidth = AutoTravel_MapFrameContent:GetWidth() / AutoTravel_MapFrameContent:GetScale();
		  local fheight = AutoTravel_MapFrameContent:GetHeight() / AutoTravel_MapFrameContent:GetScale();
		  local zoom = AutoTravel_MapFrame_Zoom;
		  
		  local x = vx * fwidth * zoom - AutoTravel_MapFrame_ZoomOffsetX;
		  local y = vy * fheight * zoom - AutoTravel_MapFrame_ZoomOffsetY;
		  
		  if x > 0 and y > 0 and x < fwidth and y < fheight then
		     
		     t:ClearAllPoints();
		     t:SetPoint("CENTER", "AutoTravel_MapFrameContent", "TOPLEFT",
				x, -y);
		     t:Show();
		     b = false;
		  end
	       end
	    end
	 end
      end
      if b then
	 t:Hide();
      end
   end
end

function AutoTravel_MapFrame_UpdateCorpse()
   local t = AutoTravel_MapFrameContentPlayerCorpse;

   local zone = AutoTravel_MapFrame_Zone;
   if zone then
      local vx, vy = MapLibrary.GetWorldPosition("player", 1, 1);
      if vx then
	 vx, vy = MapLibrary.TranslateWorldToZone(vx, vy, zone);
	 if vx then
	    if vx > 0 and vy > 0 and vx < 1 and vy < 1 then
	       local fwidth = AutoTravel_MapFrameContent:GetWidth() / AutoTravel_MapFrameContent:GetScale();
	       local fheight = AutoTravel_MapFrameContent:GetHeight() / AutoTravel_MapFrameContent:GetScale();
	       local zoom = AutoTravel_MapFrame_Zoom;
	       
	       local x = vx * fwidth * zoom - AutoTravel_MapFrame_ZoomOffsetX;
	       local y = vy * fheight * zoom - AutoTravel_MapFrame_ZoomOffsetY;
	       

	       if x > 0 and y > 0 and x < fwidth and y < fheight then

		  t:ClearAllPoints();
		  t:SetPoint("CENTER", "AutoTravel_MapFrameContent", "TOPLEFT",
			     x, -y);
		  t:Show();
		  return;
	       end
	    end
	 end
      end
   end
   t:Hide();
end

-- moved it outside to avoid unnecessary garbage
local painted_roads = { };

function AutoTravel_MapFrame_RepaintMap()
   local next_free_icon = 1;
   local next_free_road = 1;
   local zone = AutoTravel_MapFrame_Zone;

   if zone and MapLibrary.Ready and
      MapLibrary.ZoneIsCalibrated(zone) and
      MapLibrary.mappedzone[zone].zone ~= 0 then 

      for index in painted_roads do
	 if painted_roads[index] then
	    for index2 in painted_roads[index] do
	       painted_roads[index][index2] = nil;
	    end
	 end
      end

      local pathed_point = nil;
      local pathed_road = nil;
      if ATStatus.path then

	 pathed_point = { };
	 pathed_road = { };

	 local prev = ATStatus.path_from;
	 if prev then
	    pathed_road[prev] = { };
	 end
	 for index, point in ATStatus.path do
	    pathed_point[point.point] = true;
	    if not pathed_road[point.point] then
	       pathed_road[point.point] = { };
	    end		  
	    if prev then
	       pathed_road[point.point][prev] = 1;
	       pathed_road[prev][point.point] = 1;
	    end
	    prev = point.point;
	 end
      end

      local s1 = nil;
      if ATStatus.previous_click then
	 s1 = AutoTravel_Sets_GetHead(ATStatus.previous_click);
      elseif ATStatus.selected_point then
	 s1 = AutoTravel_Sets_GetHead(ATStatus.selected_point);
      end

      local fwidth = AutoTravel_MapFrameContent:GetWidth() / AutoTravel_MapFrameContent:GetScale();
      local fheight = AutoTravel_MapFrameContent:GetHeight() / AutoTravel_MapFrameContent:GetScale();
      local zoom = AutoTravel_MapFrame_Zoom;

      if not ATStatus.zone_points[zone] then
	 return;
      end
      for index, tmp in ATStatus.zone_points[zone] do
	 if next_free_icon > ATStatus.num_points then
	    break;
	 end

	 local point = AutoTravel_GetPoint(index);

	 local visible = true;
	 if not point.poi and
	    AutoTravelSettings.hide2roads then
	    local num_roads = 0;
	    for tmp2 in AutoTravel_GetRoads(index) do
	       num_roads = num_roads + 1;
	       if num_roads > 1 then
		  break;
	       end
	    end
	    if num_roads > 1 then
	       visible = false;
	    end
	 end

	 if AutoTravelSettings.hide_other_zones and
	    point.zone ~= zone then
	    visible = false;
	 end

	 if visible then
	    local vx, vy = MapLibrary.TranslateWorldToZone(point.x, point.y, zone);

	    local x = vx * fwidth * zoom - AutoTravel_MapFrame_ZoomOffsetX;
	    local y = vy * fheight * zoom - AutoTravel_MapFrame_ZoomOffsetY;

	    if x > 2 and x < fwidth - 2 and
	       y > 2 and y < fheight - 2 then

	       local point_icon = getglobal("AutoTravel_Point_" .. next_free_icon);

	       local point_texture = getglobal("AutoTravel_Point_" .. next_free_icon .. "Texture");

	       local point_coords = AutoTravel_GetPoint(index);
	       if point_coords.faction then
		  point_texture:SetWidth(10);
		  point_texture:SetHeight(10);
	       else
		  point_texture:SetWidth(8);
		  point_texture:SetHeight(8);
	       end

	       point_icon.real_index = index;
	       point_icon:SetPoint("CENTER",
				   "AutoTravel_MapFrameContent",
				   "TOPLEFT",
				   x, -y);
	       
	       local texture = "Interface\\AddOns\\AutoTravel\\normal";
	       
	       if ATStatus.previous_click then
		  if ATStatus.previous_click == index then
		     texture = "Interface\\AddOns\\AutoTravel\\clicked";
		  elseif ATStatus.selected_point == index then
		     texture = "Interface\\AddOns\\AutoTravel\\hover";
		  elseif AutoTravel_IsRoad(index, ATStatus.previous_click) then
		     texture = "Interface\\AddOns\\AutoTravel\\near";
		  elseif AutoTravel_Sets_GetHead(ATStatus.previous_click) == s1 then
		     texture = "Interface\\AddOns\\AutoTravel\\connected";
		  end
	       elseif ATStatus.selected_point then
		  if index == ATStatus.selected_point then
		     texture = "Interface\\AddOns\\AutoTravel\\hover";
		  elseif AutoTravel_IsRoad(index, ATStatus.selected_point) then
		     texture = "Interface\\AddOns\\AutoTravel\\near";
		  elseif AutoTravel_IsConnected(s1, index) then
		     texture = "Interface\\AddOns\\AutoTravel\\connected";
		  end
		  
	       end
	       
	       if pathed_point and pathed_point[index] then
		  texture = texture .. "-path";
	       end
	       
	       point_texture:SetTexture(texture);
	       
	       if AutoTravelSettings.fade_non_poi and
		  not point.poi then
		  point_texture:SetAlpha(0.5);
	       else
		  point_texture:SetAlpha(1);
	       end
	       point_icon:Show();
	       
	       next_free_icon = next_free_icon + 1;
	    end
	 end

	 if not AutoTravelSettings.hide_roads and
	    not (AutoTravelSettings.hide_other_zones and
		 point.zone ~= zone) then
	    if not painted_roads[index] then
	       painted_roads[index] = { };
	    end
	 
	    for index2, tmp in AutoTravel_GetRoads(index) do
	       if next_free_road > ATStatus.num_lines then
		  break;
	       end
	       if not painted_roads[index][index2] then
		  if not painted_roads[index2] then
		     painted_roads[index2] = { };
		  end
		  painted_roads[index][index2] = 1;
		  painted_roads[index2][index] = 1;
		  
		  local path = nil;
		  if pathed_road and pathed_road[index] and pathed_road[index][index2] then
		     path = true;
		  end
		  if AutoTravel_DrawLine(next_free_road, index, index2, path) then
		     next_free_road = next_free_road + 1;
		  end
	       end
	    end
	 end
      end
   end
   
   while next_free_icon <= ATStatus.num_points do
      local point_icon = getglobal("AutoTravel_Point_" .. next_free_icon);
      point_icon:Hide();
      next_free_icon = next_free_icon + 1;
   end

   while next_free_road <= ATStatus.num_lines do
      local road = getglobal("AutoTravel_Line_" .. next_free_road);
      road:Hide();
      next_free_road = next_free_road + 1;
   end
end

function AutoTravel_Point_OnEnter(id)
   ATStatus.last_leaving_point = nil;
   ATStatus.selected_point = this.real_index;

   ATStatus.delete_point_click_counter = 0;

   AutoTravel_MapFrame_Dirty = 1;

   local point = AutoTravel_GetPoint(ATStatus.selected_point);

   if not point then
      return;
   end

   local text = "";
   if point.poi then
      text = HIGHLIGHT_FONT_COLOR_CODE ..point.poi .. FONT_COLOR_CODE_CLOSE;
   end

   if point.faction then
      if text ~= "" then
	 text = text .. "\n";
      end
      text = text .. GRAY_FONT_COLOR_CODE ..getglobal("AUTOTRAVEL_FACTION_" .. string.upper(point.faction)) .. FONT_COLOR_CODE_CLOSE;
   end

   if text ~= "" then
      local x, y = GetCursorPosition();
      if x > UIParent:GetWidth() / 2 then
	 GameTooltip:SetOwner(this, "ANCHOR_LEFT");
      else
	 GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
      end
      GameTooltip:SetText(text);
      GameTooltip:Show();
   end
end

function AutoTravel_Point_OnLeave(id)
   ATStatus.delete_point_click_counter = -1;
   ATStatus.selected_point = nil;

   if ATStatus.last_leaving_point ~= id then
      ATStatus.last_leaving_point = id;
      AutoTravel_MapFrame_Dirty = 1;
   end

   GameTooltip:Hide();
end

function AutoTravel_Point_OnClick(arg1, id)
   if arg1 == "LeftButton" then
      if IsControlKeyDown() then
	 ATStatus.selected_point = nil;
	 ATStatus.previous_click = nil;
	 AutoTravel_RemovePoint(this.real_index);
	 AutoTravel_MapFrame_Dirty = 1;
      elseif IsShiftKeyDown() then
	 ATStatus.previous_click = nil;
	 if (AutoTravel_CalculatePath(this.real_index, nil, nil)) then
	    if AutoTravelSettings.togglemap_onwalk then
	       AutoTravel_ToggleMapVisible();
	    end
	 end
      else
	 if ATStatus.previous_click then
	    local p1 = ATStatus.previous_click;
	    local p2 = this.real_index;

	    if p1 ~= p2 and AutoTravel_GetPoint(p1) and AutoTravel_GetPoint(p2) then
	       if AutoTravel_IsRoad(p1, p2) then
		  
		  local prev_point = nil;
		  if ATStatus.path then
		     for index, point in ATStatus.path do
			if (point.point == p1 and prev_point == p2) or
			   (point.point == p2 and prev_point == p1) then
			   AutoTravel_Stop();
			   break;
			end
			prev_point = point.point;
		     end
		  end
		  AutoTravel_RemoveRoad(p1, p2);
	       else
		  AutoTravel_AddRoad(p1, p2);
	       end
	       ATStatus.previous_click = nil;
	       AutoTravel_MapFrame_Dirty = 1;
	    end
	    ATStatus.previous_click = nil;
	 else
	    ATStatus.previous_click = this.real_index;
	    AutoTravel_MapFrame_Dirty = 1;
	 end
      end
   elseif arg1 == "RightButton" then
      ATStatus.menu_id = this.real_index;
      DropDownList1:Hide();
      local x, y = GetCursorPosition(); 
      ToggleDropDownMenu(1, nil, AutoTravel_Point_Menu, "UIParent", x, y);
   end
end

function AutoTravel_Point_Menu_OnLoad()
   UIDropDownMenu_Initialize(AutoTravel_Point_Menu, AutoTravel_Point_Menu_Initialize, "MENU");
end

function AutoTravel_Point_Menu_Initialize(level)
   if level == 2 and UIDROPDOWNMENU_MENU_VALUE == AUTOTRAVEL_FACTION_POINT then
      local info = {};
      info.text = AUTOTRAVEL_FACTION_POINT;
      info.notClickable = 1;
      info.isTitle = 1;
      UIDropDownMenu_AddButton(info, level);

      info = {};
      info.text = AUTOTRAVEL_ANY_FACTION;
      info.value = "";
      info.func = AutoTravel_SetFaction;
      local point_coords = AutoTravel_GetPoint(ATStatus.menu_id);
      if point_coords.faction == nil then
	 info.checked = 1;
      end
      UIDropDownMenu_AddButton(info, level);

      info = {};
      info.value = "Alliance";
      info.text = AUTOTRAVEL_FACTION_ALLIANCE;
      if point_coords.faction == "Alliance" then
	 info.checked = 1;
      end
      info.func = AutoTravel_SetFaction;
      UIDropDownMenu_AddButton(info, level);

      info = {};
      info.value = "Horde";
      info.text = AUTOTRAVEL_FACTION_HORDE;
      if point_coords.faction == "Horde" then
	 info.checked = 1;
      end
      info.func = AutoTravel_SetFaction;
      UIDropDownMenu_AddButton(info, level);

      info = {};
      info.value = "Dead";
      info.text = AUTOTRAVEL_FACTION_DEAD;
      if point_coords.faction == "Dead" then
	 info.checked = 1;
      end
      info.func = AutoTravel_SetFaction;
      UIDropDownMenu_AddButton(info, level);

      return;
   end

   local info = {};
   info.text = AUTOTRAVEL_LOCATION;
   info.notClickable = 1;
   info.isTitle = 1;
   UIDropDownMenu_AddButton(info);

   if not ATStatus.menu_id then
      return;
   end
  
   local point_coords = AutoTravel_GetPoint(ATStatus.menu_id);

   info = {};
   info.text = point_coords.zone;
   info.notClickable = 1;
   UIDropDownMenu_AddButton(info);

   if point_coords.subzone and point_coords.subzone ~= "" then
      info = {};
      info.text = point_coords.subzone;
      info.notClickable = 1;
      UIDropDownMenu_AddButton(info);
   end

   info = {};
   info.text = AUTOTRAVEL_POINT_OPTIONS;
   info.notClickable = 1;
   info.isTitle = 1;
   UIDropDownMenu_AddButton(info);

   local poi_edit_text = AUTOTRAVEL_EDIT_POI;

   if point_coords.poi then
      poi_edit_text = poi_edit_text .. " [" .. point_coords.poi .. "]";
   end
   info = {};
   info.text = poi_edit_text;
   info.func = AutoTravel_Point_Menu_POI_OnClick;
   info.keepShownOnClick = nil;
   UIDropDownMenu_AddButton(info);

   info = {};
   info.text = AUTOTRAVEL_FACTION_POINT;
   info.hasArrow = 1;
   info.value = AUTOTRAVEL_FACTION_POINT;
   UIDropDownMenu_AddButton(info);

   info = {};
   info.text = AUTOTRAVEL_DELETE_POINT;
   info.func = AutoTravel_Point_Menu_Delete_OnClick;
   UIDropDownMenu_AddButton(info);
   info = {};
   info.text = AUTOTRAVEL_TRAVEL_OPTIONS;
   info.notClickable = 1;
   info.isTitle = 1;
   UIDropDownMenu_AddButton(info);

   if ATStatus.path then
      info = {};
      info.text = AUTOTRAVEL_STOP;
      info.func = AutoTravel_Stop;
      UIDropDownMenu_AddButton(info);
   end

   info = {};
   info.text = AUTOTRAVEL_GO_TO_POINT;
   info.func = AutoTravel_Point_Menu_Travel_OnClick;
   UIDropDownMenu_AddButton(info);
end

function AutoTravel_Point_Menu_POI_OnClick()
   local point = ATStatus.menu_id;
   if not point then
      return;
   end

   local point_coord = AutoTravel_GetPoint(point);
   local text = point_coord.poi;
   if not text then
      text = "";
   end

   getglobal("StaticPopup1EditBox"):SetText(text);

   StaticPopup_Show("AUTOTRAVEL_POI");
end

function AutoTravel_Point_Menu_Delete_OnClick()
   ATStatus.selected_point = nil;
   AutoTravel_RemovePoint(ATStatus.menu_id);
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_Point_POI_Editbox_OnAccept()
   local point = ATStatus.menu_id;
   if not point then
      return;
   end

   local text = getglobal("StaticPopup1EditBox"):GetText();
   local point_coord = AutoTravel_GetPoint(point);
   AutoTravel_POI_SetPoi(point_coord, text);
end

function AutoTravel_Point_POI_Editbox_OnCancel()
end

function AutoTravel_Point_Menu_Travel_OnClick()
   local point = ATStatus.menu_id;
   if not point then
      return;
   end

   if (AutoTravel_CalculatePath(point, nil, nil)) then
      if AutoTravelSettings.togglemap_onwalk then
	 AutoTravel_ToggleMapVisible();
      end
   end
end

function AutoTravel_MapFrame_ContinentDropDown_OnShow()
   UIDropDownMenu_Initialize(AutoTravel_MapFrame_ContinentDropDown, AutoTravel_MapFrame_ContinentDropDown_Initialize);
   
   local continent = "";
   if ATStatus then
      local c = MapLibrary.GetCurrentZoneMap();
      if c then
	 c = MapLibrary.mappedzone[c];
	 if c then
	    continent = MapLibrary.continent_names[c.continent];
	 end
      end
   end

   UIDropDownMenu_SetText(continent, AutoTravel_MapFrame_ContinentDropDown);
   UIDropDownMenu_SetWidth(130, AutoTravel_MapFrame_ContinentDropDown);
end

function AutoTravel_MapFrame_ContinentDropDown_Initialize()
   if not ATStatus then
      local info = {};
      info.text = "";
      info.value = "";
      UIDropDownMenu_AddButton(info);
      return;
   end

   for i, c in MapLibrary.continent_names do
      local info = {};
      info.text = c;
      info.value = i;
      info.func = AutoTravel_MapFrame_ContinentDropDown_OnClick;
      UIDropDownMenu_AddButton(info);
   end
end

function AutoTravel_MapFrame_ContinentDropDown_OnClick()
   local cont = MapLibrary.continent_names[this.value];
   UIDropDownMenu_SetText(cont, AutoTravel_MapFrame_ContinentDropDown);
   AutoTravel_MapFrame_ZoneDropDown_OnShow();
end

function AutoTravel_MapFrame_ZoneDropDown_OnShow()
   UIDropDownMenu_Initialize(AutoTravel_MapFrame_ZoneDropDown, AutoTravel_MapFrame_ZoneDropDown_Initialize);
   if AutoTravel_MapFrame_Zone then
      UIDropDownMenu_SetText(AutoTravel_MapFrame_Zone, AutoTravel_MapFrame_ZoneDropDown);
   else
      UIDropDownMenu_SetText("", AutoTravel_MapFrame_ZoneDropDown);
   end
   UIDropDownMenu_SetWidth(130, AutoTravel_MapFrame_ZoneDropDown);
end

function AutoTravel_MapFrame_ZoneDropDown_Initialize()
   if not ATStatus then
      local info = {};
      info.text = "";
      info.value = "";
      UIDropDownMenu_AddButton(info);
      return;
   end

   local continent = UIDropDownMenu_GetText(AutoTravel_MapFrame_ContinentDropDown);
   if not continent or continent == "" then
      return;
   end

   local cont_index = MapLibrary.mappedzone[continent].continent;

   local zones = { };
   for zone, tmp in MapLibrary.mappedzone do
      if tmp.continent == cont_index then
	 table.insert(zones, zone);
      end
   end
   table.sort(zones);
      
   for index, zone in zones do
      local info = {};
      info.text = zone;
      info.value = zone;
      info.func = AutoTravel_MapFrame_ZoneDropDown_OnClick;
      UIDropDownMenu_AddButton(info);
   end
end

function AutoTravel_MapFrame_ZoneDropDown_OnClick()
   if AutoTravelSettings.player_visible and
      this.value ~= AutoTravel_MapFrame_Zone then
      AutoTravel_TurnOffAlwaysFollow();
   end
   AutoTravel_SetMapZone(this.value);
end

function AutoTravel_SetZoom(zoom)
   if zoom ~= AutoTravel_MapFrame_Zoom then
      AutoTravel_MapFrame_Zoom = zoom;
      AutoTravel_MapFrame_Dirty = 1;
      AutoTravel_SetOffset();
   end
   AutoTravel_MapTitleText:SetText(AutoTravel_MapFrame_Zone .. " " .. zoom .. "x");
end

function AutoTravel_SetMapZone(zone)
   if zone ~= AutoTravel_MapFrame_Zone and MapLibrary.mappedzone[zone] then
      AutoTravel_MapFrame_Zone = zone;
      AutoTravel_MapFrame_Dirty = 1;
      AutoTravel_SetOffset();
      AutoTravel_MapTitleText:SetText(AutoTravel_MapFrame_Zone .. " " .. AutoTravel_MapFrame_Zoom .. "x");
      AutoTravel_MapFrame_ContinentDropDown_OnShow();
      AutoTravel_MapFrame_ZoneDropDown_OnShow();
      ATStatus.previous_click = nil;
   end
end

function AutoTravel_UpdateAlpha()
   AutoTravel_MapFrame:SetAlpha(AutoTravelSettings.mapalpha);
end

function AutoTravel_SetFaction()
   local point_coords = AutoTravel_GetPoint(ATStatus.menu_id);
   if this.value == "" then
      point_coords.faction = nil;
   else
      point_coords.faction = this.value;
   end
   AutoTravel_MapFrame_Dirty = 1;
end

function AutoTravel_TurnOffAlwaysFollow()
   AutoTravelSettings.player_visible = false;
   AutoTravel_MapFrame_AlwaysVisible:SetChecked(0);
end

function AutoTravel_TurnOnAlwaysFollow()
   AutoTravelSettings.player_visible = true;
   AutoTravel_MapFrame_AlwaysVisible:SetChecked(1);
end

function AutoTravel_ToggleAlwaysFollow()
   if AutoTravelSettings.player_visible then
      AutoTravel_TurnOffAlwaysFollow();
   else
      AutoTravel_TurnOnAlwaysFollow();
   end
end
