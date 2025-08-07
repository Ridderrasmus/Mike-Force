/*
	File: fn_get_roads_in_area.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Retrieves all roads within a specified area, sorted by usage score.
		Returns roads sorted by their usage score (highest first) if road usage tracking is enabled.

	Parameter(s):
		_center - Center position of the search area [POSITION]
		_radius - Search radius in meters [NUMBER]

	Returns:
		Array of [roadObject, usageScore] for roads in the area [ARRAY]

	Example(s):
		// Get all roads within 2km of an objective, sorted by usage
		_roads = [getPos objective1, 2000] call vn_mf_fnc_get_roads_in_area;
		
		// Select the highest traffic road
		if (count _roads > 0) then {
			_roads select 0 params ["_roadObject", "_usageScore"];
			// Use this road for further processing
		};
*/

params ["_center", "_radius"];

// Get all roads in the area
private _roadsInArea = _center nearRoads _radius;
private _roadUsageMap = missionNamespace getVariable ["vn_mf_road_usage", createHashMap];
private _roadsWithUsage = [];

// Create array of [roadObject, usageScore] pairs
{
	private _roadObject = _x;
	// Use the same road key format as the usage tracking system
	private _roadInfo = getRoadInfo _roadObject;
	if (count _roadInfo >= 2) then {
		_roadInfo params ["_mapType", "_width", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];
		private _roadKey = format ["%1_%2_%3_%4_%5", 
			_mapType, 
			round (_begPos select 0),
			round (_begPos select 1), 
			round (_endPos select 0),
			round (_endPos select 1)
		];
		private _usageScore = _roadUsageMap getOrDefault [_roadKey, 0];
		_roadsWithUsage pushBack [_roadObject, _usageScore];
	};
} forEach _roadsInArea;

// Sort by usage score (highest first) for prioritizing high-traffic roads
_roadsWithUsage = [_roadsWithUsage, [], {_x select 1}, "DESCEND"] call BIS_fnc_sortBy;

_roadsWithUsage
