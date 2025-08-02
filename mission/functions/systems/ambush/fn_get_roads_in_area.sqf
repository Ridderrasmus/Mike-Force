/*
	File: fn_get_roads_in_area.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Retrieves all roads with ambush points within a specified area.
		Returns roads sorted by their usage score (highest first) if road usage tracking is enabled.

	Parameter(s):
		_center - Center position of the search area [POSITION]
		_radius - Search radius in meters [NUMBER]

	Returns:
		Array of [roadKey, ambushPoints, usageScore] for roads in the area [ARRAY]

	Example(s):
		// Get all ambush-capable roads within 2km of an objective
		_roads = [getPos objective1, 2000] call vn_mf_fnc_get_roads_in_area;
		
		// Select the highest traffic road
		if (count _roads > 0) then {
			_roads select 0 params ["_roadKey", "_ambushPoints", "_usageScore"];
			// Use this road for ambush placement
		};
*/

params ["_center", "_radius"];

// Check if road preprocessing is complete
if (isNil {missionNamespace getVariable "vn_mf_ambush_road_preprocessing_complete"}) then {
	diag_log "SP MikeForce: Warning - Roads in area requested before preprocessing is complete";
	[]
} else {
	private _ambushRoadMap = missionNamespace getVariable ["vn_mf_ambush_road_map", createHashMap];
	private _roadUsageMap = missionNamespace getVariable ["vn_mf_road_usage", createHashMap];
	private _roadsInArea = [];
	
	// Iterate through all roads with ambush points
	{
		private _roadKey = _x;
		private _ambushPoints = _y;
		
		// Check if any ambush points are within the specified radius
		private _roadInArea = false;
		{
			if (_x distance2D _center <= _radius) exitWith {
				_roadInArea = true;
			};
		} forEach _ambushPoints;
		
		// If road is in area, add it to results with usage score
		if (_roadInArea) then {
			private _usageScore = _roadUsageMap getOrDefault [_roadKey, 0];
			_roadsInArea pushBack [_roadKey, _ambushPoints, _usageScore];
		};
		
	} forEach _ambushRoadMap;
	
	// Sort by usage score (highest first) for prioritizing high-traffic roads
	_roadsInArea sort {(_y select 2) - (_x select 2)};
	
	_roadsInArea
};
