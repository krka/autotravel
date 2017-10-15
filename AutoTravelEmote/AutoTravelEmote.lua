function AutoTravelEmote_OnStuck(event)
   DoEmote("cry");
end

function AutoTravelEmote_OnArrive(event)
   DoEmote("cheer");
end
AutoTravelAPI.RegisterEvent("OnStuck", AutoTravelEmote_OnStuck);
AutoTravelAPI.RegisterEvent("OnArrive", AutoTravelEmote_OnArrive);
