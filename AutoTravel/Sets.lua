-- Connected points functions
function AutoTravel_IsConnected(p1, p2)
   if not ATStatus.connected_valid then
      AutoTravel_CalculateConnectedPoints();
   end

   return AutoTravel_Sets_GetHead(p1) ==
      AutoTravel_Sets_GetHead(p2);
end

function AutoTravel_Sets_GetHead(index)
   if not ATStatus.connected_valid then
      AutoTravel_CalculateConnectedPoints();
   end
   if ATStatus.connected_sets[index] == nil then
      ATStatus.connected_sets[index] = index;
      return index;
   end
   if ATStatus.connected_sets[index] == index then
      return index;
   else
      ATStatus.connected_sets[index] = AutoTravel_Sets_GetHead(ATStatus.connected_sets[index]);
      return ATStatus.connected_sets[index];
   end
end
 
function AutoTravel_ConnectionAdd(p1, p2)
   if not ATStatus.connected_valid then
      AutoTravel_CalculateConnectedPoints();
   end
   local s1 = AutoTravel_Sets_GetHead(p1);
   local s2 = AutoTravel_Sets_GetHead(p2);
   ATStatus.connected_sets[s2] = s1;
end


function AutoTravel_CalculateConnectedPoints()
   if not ATStatus.connected_sets then
      ATStatus.connected_sets = { };
   else
      for index in ATStatus.connected_sets do
	 ATStatus.connected_sets[index] = index;
      end
   end

   ATStatus.connected_valid = true;
  
   -- Connect using roads
   for index, point in AutoTravel_GetPoints() do
      for index2, tmp in AutoTravel_GetRoads(index) do
	 if index < index2 then
	    AutoTravel_ConnectionAdd(index, index2);
	 end
      end
   end
end
