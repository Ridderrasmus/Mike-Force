/*
	File: fn_commander_logic.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Main loop for the commander AI. Handles decision making and action execution.
		Manages ambush operations within the zone commander's operational radius.

	Parameter(s):
		_zone - Zone marker name [STRING]

	Returns:
		None

	Example(s):
		["zone_ba_ria"] call vn_mf_fnc_commander_logic;
*/

params ["_zone"];

// If the zone is an array (used in event handlers), extract the first element
if (typeName _zone == "ARRAY") then {
	_zone = _zone select 0;
};



// Configuration constants
private _additionalRadius = 600; // additional radius around the zone for ambush operations
private _operationalRadius = (((getMarkerSize _zone) select 0) * -1) + _additionalRadius; // operational radius around the zone
private _maxConcurrentAmbushes = 2; // Maximum ambushes per zone commander
private _minCooldownTime = 600; // 10 minutes between ambush orders
private _minimumUsageThreshold = 2; // Minimum road usage score to consider
private _maxAmbushPointDistance = 500; // Maximum distance from road to ambush point

// Initialize zone commander data if not exists
if (isNil {missionNamespace getVariable format ["commander_%1_data", _zone]}) then {
	private _commanderData = createHashMapFromArray [
		["activeAmbushes", []],
		["lastAmbushTime", 0],
		["totalAmbushesCreated", 0]
	];
	missionNamespace setVariable [format ["commander_%1_data", _zone], _commanderData];
};

private _commanderData = missionNamespace getVariable format ["commander_%1_data", _zone];
private _zonePos = markerPos _zone;

systemChat format ["SP Mikeforce - Commander AI evaluating zone: %1", _zone];

// Clean up completed/destroyed ambushes
private _activeAmbushes = _commanderData getOrDefault ["activeAmbushes", []];
private _validAmbushes = _activeAmbushes select { 
	!(_x isNotEqualTo objNull) && _x getOrDefault ["ambush_active", false] 
};
_commanderData set ["activeAmbushes", _validAmbushes];

// Check if we can create new ambushes
private _canCreateAmbush = (
	count _validAmbushes < _maxConcurrentAmbushes &&
	(serverTime - (_commanderData get "lastAmbushTime")) > _minCooldownTime
);

if (_canCreateAmbush) then {
	// Get roads within operational radius, sorted by usage

	private _roadsInArea = [_zonePos, _operationalRadius] call vn_mf_fnc_get_roads_in_area;
	
	if (count _roadsInArea > 0) then {
		// Filter roads by minimum usage threshold (already sorted by usage)
		private _viableRoads = _roadsInArea select { 
			(_x select 1) >= _minimumUsageThreshold 
		};
		
		if (count _viableRoads > 0) then {
			// Get the ambush road map for finding nearby ambush points
			private _ambushRoadMap = missionNamespace getVariable ["vn_mf_ambush_road_map", createHashMap];
			private _selectedAmbushData = [];
			
			// Iterate through viable roads (highest usage first) to find one with nearby ambush points
			{
				_x params ["_roadObject", "_usageScore"];
				private _roadPos = getPos _roadObject;
				private _foundAmbushPoint = false;
				
				// Find the closest ambush point within the maximum distance from this high-usage road
				private _closestAmbushPoint = objNull;
				private _closestAmbushRoadKey = "";
				private _closestDistance = _maxAmbushPointDistance + 1;

				{
					private _ambushRoadKey = _x;
					private _ambushPoints = _y;

					{
						private _ambushPoint = _x;
						private _distance = _ambushPoint distance2D _roadPos;
						if (_distance <= _maxAmbushPointDistance && {_distance < _closestDistance}) then {
							_closestAmbushPoint = _ambushPoint;
							_closestAmbushRoadKey = _ambushRoadKey;
							_closestDistance = _distance;
						};
					} forEach _ambushPoints;
				} forEach _ambushRoadMap;

				if (_closestAmbushPoint isNotEqualTo objNull ) then {
					_selectedAmbushData = [_roadObject, _closestAmbushPoint, _usageScore, _closestAmbushRoadKey];
					_foundAmbushPoint = true;
				};
				
				if (_foundAmbushPoint) exitWith {};
			} forEach _viableRoads;
			
			if (count _selectedAmbushData > 0) then {
				_selectedAmbushData params ["_roadObject", "_ambushPos", "_usageScore", "_ambushRoadKey"];
				
				systemChat format ["SP Mikeforce - Zone %1 commander initiating ambush at %2 (road usage: %3, distance from road: %4m)", 
					_zone, _ambushPos, _usageScore, (getPos _roadObject) distance2D _ambushPos];
				
				// Create the ambush
				[_zone, _ambushPos, _ambushRoadKey] call vn_mf_fnc_commander_create_ambush;
				
				// Update commander data
				_commanderData set ["lastAmbushTime", serverTime];
				_commanderData set ["totalAmbushesCreated", (_commanderData get "totalAmbushesCreated") + 1];
			} else {
				systemChat format ["SP Mikeforce - Zone %1 commander: No ambush points found within %2m of viable roads", _zone, _maxAmbushPointDistance];
			};
		} else {
			systemChat format ["SP Mikeforce - Zone %1 commander: No viable roads found (insufficient usage)", _zone];
		};
	} else {
		systemChat format ["SP Mikeforce - Zone %1 commander: No roads found in operational area", _zone];
	};
} else {
	private _reasonMsg = "";
	if (count _validAmbushes >= _maxConcurrentAmbushes) then {
		_reasonMsg = format ["at ambush limit (%1/%2)", count _validAmbushes, _maxConcurrentAmbushes];
	} else {
		private _timeRemaining = _minCooldownTime - (serverTime - (_commanderData get "lastAmbushTime"));
		_reasonMsg = format ["in cooldown (%1 min remaining)", _timeRemaining / 60];
	};
	
	systemChat format ["SP Mikeforce - Zone %1 commander: Cannot create ambush - %2", _zone, _reasonMsg];
};


