function AutoTravel_SetOffset(offx, offy)
   if offx then
      AutoTravel_MapFrame_ZoomOffsetX = offx;
   end

   if offy then
      AutoTravel_MapFrame_ZoomOffsetY = offy;
   end

   local zoom = AutoTravel_MapFrame_Zoom;

   local fwidth = AutoTravel_MapFrameContent:GetWidth() / AutoTravel_MapFrameContent:GetScale();
   local fheight = AutoTravel_MapFrameContent:GetHeight() / AutoTravel_MapFrameContent:GetScale();

   if AutoTravel_MapFrame_ZoomOffsetX < 0 then
      AutoTravel_MapFrame_ZoomOffsetX = 0;
   end
   if AutoTravel_MapFrame_ZoomOffsetX > (zoom - 1) * fwidth then
      AutoTravel_MapFrame_ZoomOffsetX = (zoom - 1) * fwidth;
   end
   if AutoTravel_MapFrame_ZoomOffsetY < 0 then
      AutoTravel_MapFrame_ZoomOffsetY = 0;
   end
   if AutoTravel_MapFrame_ZoomOffsetY > (zoom - 1) * fheight then
      AutoTravel_MapFrame_ZoomOffsetY = (zoom - 1) * fheight;
   end

   local vert_slider = AutoTravel_MapFrame_VertScrollBarSlider;
   local bar_y = -AutoTravel_MapFrame_ZoomOffsetY / (zoom * fheight);
   local bar_height = AutoTravel_MapFrame_VertScrollBar:GetHeight() / AutoTravel_MapFrameContent:GetScale();

   vert_slider:ClearAllPoints();
   vert_slider:SetPoint("TOPLEFT",
			"AutoTravel_MapFrame_VertScrollBar",
			"TOPLEFT",
			0, bar_y * bar_height);

   vert_slider:SetWidth(20);
   vert_slider:SetHeight(bar_height / zoom);

   local hori_slider = AutoTravel_MapFrame_HoriScrollBarSlider;
   local bar_x = AutoTravel_MapFrame_ZoomOffsetX / (zoom * fwidth);
   local bar_width = AutoTravel_MapFrame_HoriScrollBar:GetWidth() / AutoTravel_MapFrameContent:GetScale();

   hori_slider:ClearAllPoints();
   hori_slider:SetPoint("TOPLEFT",
			"AutoTravel_MapFrame_HoriScrollBar",
			"TOPLEFT",
			bar_x * bar_width, 0);

   hori_slider:SetHeight(20);
   hori_slider:SetWidth(bar_width / zoom);

   AutoTravel_MapFrame_Dirty = 1;
end
