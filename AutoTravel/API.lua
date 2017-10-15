AutoTravelAPI = {
   
   -- Functions for controlling
   
   -- Parameters: none
   -- Return value: none
   Stop = AutoTravel_Stop,
   
   -- Parameters: none
   -- Return value: none
   Pause = AutoTravel_Pause,
   
   -- Parameters: none
   -- Return value: none
   Resume = AutoTravel_Resume,

   -- Parameters: point_index, zone, subzone, poi
   --   point_index is an integer and should be one of the points
   --   on the map.
   --   zone, subzone and poi are strings.
   --   All of these parameters can be nil. Those that are nil
   --   will make no constraint on the destination point.
   --   At least one of them should be non-nil, otherwise all points will
   --   be valid destinations.
   --   You can combine these. Example: Start(nil, "Wetlands", nil, "Inn")
   --   will accept any point that is an Inn and is in Wetlands.
   --   All strings are case insensitive.
   
   -- Return value: false if no path to destination, true otherwise
   Start = AutoTravel_CalculatePath;
   

   -- Functions for getting information
   
   -- Parameters: none
   -- Return value: nil if no path
   --               the point index, if there is a path
   GetDestination = function()
		       if ATStatus.path then
			  return ATStatus.path[table.getn(ATStatus.path)].point;
		       end
		       return nil;
		    end,
   
   -- Parameters: none
   -- Return value: true if there is a path and it is paused, otherwise false
   IsPaused = function()
		 return ATStatus.path and ATStatus.paused;
	      end,
   
   -- Parameters: none
   -- Return value: nil if paused or not have a path,
   --               otherwise the distance measured in yards
   GetDistance = AutoTravel_GetDistance,
   
   -- Parameters: none
   -- Return value: nil if not moving, otherwise the estimated time in seconds
   GetETA = AutoTravel_GetETA,
   
      


   -- Functions for catching events
   
   -- Parameters: event, func
   --   event: a string of the event to catch
   --   func: your function that should catch the event
   -- Returns: the unique id for this event. Used for unregistering.
   --          nil of invalid event
   -- func will be called with first and only parameter being the event string
   
   RegisterEvent = function(event, func)
		      if not AutoTravelAPI.handlers[event] then
			 return nil;
		      end
		      local id = AutoTravelAPI.handlers_next_id[event];

		      AutoTravelAPI.handlers[event][id] = func;

		      AutoTravelAPI.handlers_next_id[event] = id + 1;

		      return id;
		   end,
   
   -- Parameters: event, id
   --   event: the event to unregister from
   --   id: the handler to unregister from event
   -- Returns: nothing
   UnregisterEvent = function(event, id)
			if not AutoTravelAPI.handlers[event] then
			   return;
			end
			AutoTravelAPI.handlers[event][id] = nil;
		     end,
   
   TriggerEvent = function(event)
		     table.insert(AutoTravelAPI.trigger_queue, event);
		  end,

   FlushTriggerQueue = function()
			  -- For safety reasons, never loop more than
			  -- 10 times (should only happen upon bad code)
			  local maximum = 10;
			  while maximum > 0 and
			     not AutoTravel_IsTableEmpty(AutoTravelAPI.trigger_queue) do
			     maximum = maximum - 1;
			     local tmp_queue = AutoTravelAPI.trigger_queue;
			     AutoTravelAPI.trigger_queue = { };
			     for index, event in tmp_queue do
				for id, func in AutoTravelAPI.handlers[event] do
				   func(event);
				end
			     end
			  end
		       end
}

AutoTravelAPI.handlers = { };
AutoTravelAPI.handlers_next_id = { };

AutoTravelAPI.trigger_queue = { };

function AutoTravel_AddEvent(event)
   AutoTravelAPI.handlers[event] = { };
   AutoTravelAPI.handlers_next_id[event] = 1;
end

AutoTravel_AddEvent("OnInitialized");
AutoTravel_AddEvent("OnStart");
AutoTravel_AddEvent("OnStop");
AutoTravel_AddEvent("OnPause");
AutoTravel_AddEvent("OnResume");
AutoTravel_AddEvent("OnStuck");
AutoTravel_AddEvent("OnArrive");
AutoTravel_AddEvent("OnWaypointReached");
