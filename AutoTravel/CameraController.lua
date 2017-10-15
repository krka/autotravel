local old_camera_style;

function AutoTravelCamera_Never()
   if not old_camera_style then
      old_camera_style = GetCVar("cameraSmoothStyle");
      SetCVar("cameraSmoothStyle", "0");
   end
end

function AutoTravelCamera_Restore()
   if old_camera_style then
      SetCVar("cameraSmoothStyle", old_camera_style);
      old_camera_style = nil;
   end
end

function AutoTravelCamera_Init()
   AutoTravelAPI.RegisterEvent("OnStuck", AutoTravelCamera_Restore);
   AutoTravelAPI.RegisterEvent("OnPause", AutoTravelCamera_Restore);
   AutoTravelAPI.RegisterEvent("OnStop", AutoTravelCamera_Restore);
   AutoTravelAPI.RegisterEvent("OnResume", AutoTravelCamera_Never);
   AutoTravelAPI.RegisterEvent("OnStart", AutoTravelCamera_Never);
end

