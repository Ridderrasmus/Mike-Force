/*
	File: fn_create_road_key.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Creates a unique road key from a road object in the format "roadType_startX_startY_endX_endY".
		This key format matches the one used in the preprocessing system for consistent lookups.

	Parameter(s):
		_road - Road object to create key for [OBJECT]

	Returns:
		Road key string, or empty string if road is invalid [STRING]

	Example(s):
		// Create a road key for tracking usage
		_roadKey = [_roadObject] call vn_mf_fnc_create_road_key;
		
		// Check if the road has ambush points
		_ambushPoints = [_roadKey] call vn_mf_fnc_get_road_ambush_points;
*/

params ["_road"];

// Return empty string for invalid roads
if (isNull _road) exitWith {""};

// Get road information
private _roadInfo = getRoadInfo _road;
if (_roadInfo isEqualTo []) exitWith {""};

// Extract road segment information
_roadInfo params ["_roadType", "_roadWidth", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];

// Create the same key format used in preprocessing: "roadType_startX_startY_endX_endY"
format ["%1_%2_%3_%4_%5", 
	_roadType,
	round (_begPos select 0),
	round (_begPos select 1), 
	round (_endPos select 0),
	round (_endPos select 1)
];
