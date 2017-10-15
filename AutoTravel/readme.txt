--- Contents ---
- What is this?
- Installation
- The basics
- Calibration
- The main frame
- Points of interest
- The settings
- The map
- Keybindings
- Console commands
- Included extras!
- Quirks
- Known problems
- Algorithms used
- Example of usage
- Todo
- For developers
- Thanks to
- Bug reporting

- What is this?
This addon enables you to walk automatically between points in the world that
you have already visited and created a path to. Created by Kristofer Karlsson (krka@kth.se) in april 2005.

- Installation
Install the addon by downloading the zipfile and extracting it into wow/Interface/AddOns/
You should get the directory wow/Interface/AddOns/AutoTravel/

- The basics
The basic two elements of this addon are points and roads.
A point is a position on the map, identified by its coordinates (x and y).
A road is something that connects two points directly.
Many roads can then form a path.

The idea is that you walk along as usual adding waypoints where you want to.
Then you check to map view and build roads between those points.
Now, if you've connected roads so that there is a path between two points, you can automatically walk between them.

IMPORTANT: Creating waypoints, roads and thus building your graph
This is the most important part of setting up this addon. Before you are able to walk between different points, you have to add a lot of points and this is done by standing where you want the point to be and hitting the key binding for adding point. A good idea is to make points at every big turn and at every crossroad, since the addon follows a path by walking in a straight line between points.

After having added points, you should visit the map view to see them. Hover a point to see which other points are directly connected. Those points are yellow. This means that the addon thinks that there is a straight path between these two points. By clicking on first the first point and then the second point, you can add roads between two points, so that they become directly connected. Only make roads between points that you know you can walk straight between!

Now, after having set up roads, you should see some points being orange when hovering a point. Those are the points that are indirectly connected. This means that it is possible to walk from the hovered point to any point that is either yellow or orange.

With autoroad turned on, you should in most cases not have to worry about making roads. When adding a new point, autoroading finds the closest point and connects them directly. Sometimes it makes "mistakes" though, when the closest point isn't the one you'd want it to be connected to, so you have to check the map to see if it really is the way you like it.

- Calibration
In this version, you need to calibrate each zone you visit first the time. Once done, you never have to do it again. Calibration is done automatically. All you need to do is walk around in the zone for a short while. You need to walk both 5 yards in the x-direction and 5 yards in the y-direction. Don't worry too much about it though. Just walk around and it'll work.

- Main frame
The main frame is a small frame that serves two purposes. First of all it shows
the destination zone, remaining time and remaining distance when following a path. Second of all, right clicking on it will show the menu for AutoTravel.
With the left mouse button, you can also drag around the frame to place it where you like.

The main menu contains lots of useful stuff. First is the command to add a point. This adds a waypoint at the current position (only works if the zone you're in has been calibrated). Second comes two "go to"-menus.
The first lets you walk to the nearest point of a specific zone or subzone.
The second lets you walk to the nearest Point of interest of a specific type.

- Points of interest
What is a point of interest? When playing the game, you will notice that
certain points are regularly visited. In my case those are the
Inn, Mailbox, Taxi (gryphon riders), Train, Gear repair, and so on. You may not
want to have to remember which point on the map is the Inn or the Mailbox, so
my solution to this is that you name the specific point "Inn". Typically, many points will share the same POI-name. Then, when choosing to go to Inn from the
POI menu, the addon will find the nearest point that has that name. This is very useful! You can also have categories (only one level) of POI.
Type in the names "Trainer|Hunter" and "Trainer|Skinner" on different points and Trainer will become a category. This helps you organize the POI menu.

- The settings
Below these menus are the settings menus. First is the one for maps:

-- Toggle map on walk: If enabled, the map will be close when selecting a point to walk to on the map.
-- Hide roads on map: If enabled, this will hide all the roads.
-- Show only POI and endpoints: If enabled, this will hide all points except those that are POI or an endpoint (thus, has only one road).
-- Hide points outside zone: This hides all points that are in another zone than the one that is active.
-- Fade non POI: Fade non-POI points to make POI easily seen.

Pathing settings:
-- Show ETA: This shows time remaining on the main frame when walking
-- Move old point when adding new too close: When you add a point, you may already be close to another point. I don't want points to be too close (because those are most likely mistakes) so you have two choices. If this is enabled, the old point that was close will be moved to the current player position. If disabled, nothing will happen at all.

Now, there are two autoroading strategies, and the second one will take precedence. Autoroading means that when you're adding a new point, a road will automatically be created to some other point.
-- Autoroad to nearest point: The newly created point will be connected to its nearest point.
-- Autoroad to previous point: The newly created point will be connected to the previously added point (if any).

For both cases, the distance to the point to add to must be at most 200 yards.

- The map

On the map you will see points and roads (if you have any). To connect or unconnect two points (build or remove roads between them), click on both of them in turns. You will directly see the newly built road if done correctly.
Right clicking on a point will bring up the point menu. The options there should be straight forward.

There are two things implemented to help you do stuff faster.
Shift + left click is the same as choosing go to point from the menu.
Ctrl + left click is the same as choosing delete point from the menu.

When you are following a path, you will see the roads as blue on the map.
Other interesting colours for points are:
Turquoise: Hovered point.
Green: Clicked point (halfway through building or removing a road)
Red: Not reachable from selected point.
Orange: Reachable.
Yellow: Has road to hovered point.

The map is movable, just drag by the title with the left mouse button.
It is also resizable, drag by the bottom right corner with the left mouse button.
Clicking on the map will zoom in and out with left and right mousebutton. Holding down the left mouse button on the map will move it around.

- Key bindings
Add point: This adds a waypoint at your current location.
Toggle pause / resume: This simply stops or starts autotraveling.
Toggle visible: Toggle the visibility of the information frame.
Toggle map: Toggle the visibility of the map.

-- Console commands
You can also do most stuff through commandline:
The commands are:
/at stop
/at pause
/at resume
/at add

/at toggle hidden - toggle UI visible
/at hide - hide UI
/at show - show UI

/at go <poi> - start walk to the nearest point of interest with the specific name. Case insensitive.
Example 1: /at go Inn
Example 2: /at go Taxi

/at mapalpha <percentage> to set the transparency of the map.
100 is max (solid) and 0 is minimum (invisible).

- Included extras!
Included with this are two other addons: AutoTravelEmote
AutoTravelEmote just makes emotes when stuck and on arrival. This is good
notification if you're not paying attention.
AutoTravelCorpse autorevives and runs back to the corpse and resumes your
previous journey.

These are not in any way required for this addon to work but I think they are
useful.

If you're using both Titan Panel and AutoTravel, you may want to take a look at the addon that adds an AutoTravel controller to Titan Pinal. This is not made by me but I think it's great and worth advertising.

- Quirks
Since this uses the positioning on the map, it may need to change map zones automatically when either:
* Following a path
* Calibrating a zone
As a result of this, dropdown menus will change to a list of zones, and you 
can't choose map to look at.
* This basically only works in 2d. Don't try it on stairs and stuff. The indendent usage is for walking along roads between distant places. Tight corridors and turns might also be a problem, but should work if you set the points in a smart ay.

- Known problems
* Doesn't like older versions of DefendYourself. The latest version is fine though.
* Seems like some people can't move or resize the map frame. I have no idea why that is unfortunately. Can anyone figure it out?

- Algorithms
* For finding the optimal path, this simple uses a modified Breadth First Search, but with a priority queue instead of a queue.
* To determine if two points are connected, I first let each point belong to its own set, and then merge two set of points together if they share a road.
* To walk in the correct direction, I first detect the direction by walking forward and see the change position. Then I turn the appropiate amount of angles to aim towards the next point on the path. Also, if the player is far away from the road, he will first walk straight towards it.

- Example of usage (Thanks to Kord for this)
AutoTravel is configured by defining a network of waypoints linked by 'roads'. Unlike the usual method of 'constructing x number of linear paths'.

Each waypoint in the network has 1 or more 'roads' linking it to neighbouring waypoints.

For example, suppose you're in the centre of town (waypoint A), and there are 8 shops (waypoints 1-8) you want to be able to visit. You define 8 roads ( A to 1, A to 2, ..., A to 8 ). The difference with AutoTravel is that you could now be at shop 5, and say 'go to shop 3'. AT will then dynamically calculate the best route to travel between the waspoint 5 and 3... pretty simple for this example... '5 to A to 3'.

Continuing with that example... now that you know AT calculates routes dynamically, you might want to add extra waypoints between the shops to enable AT to calculate more direct routes. Adding those extra waypoints gives AutoTravel more options for calculating the best path.

- Todo (maybe!)
* Show points on minimap (Don't know how to do this yet)
* Export / Import paths

- For developers
I have now begun work on a developer API. The idea is that you can interact with AutoTravel in your own addons. Extracting information, controlling, and get triggered by AutoTravel events. This is useful for lots of stuff!

See the file API.lua for how to use it. I have also made two example addons, see AutoTravelEmote and AutoTravelCorpse, included in the zipfile.

Go ahead and do things I have never thought of! Make a better death handling perhaps? The current one is perhaps not that good, and since it's just around 100 lines of code, you should have little difficulty figuring out how it works and improve it!

Let me know if you are missing some API function, and I'll add it!

- Thanks to
* Rowne for making the Fetch addon.
* All you people who submitted detailed debug information for me!

- Bug reporting
You found some bug? Good, I want to know about it. But please, first logout and disable all other addons and try again.
Is the bug still there? Tell me how you produced the bug.
Is the bug gone? Tell me what other addon caused the interference.
