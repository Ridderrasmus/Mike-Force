/*
	File: fn_commander_create_ambush.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Creates an ambush through the multi-step process:
		1. Spawn squad at zone FOB
		2. Move to ambush position
		3. Assess arrival conditions
		4. Setup ambush (despawn movement squad, place mines, spawn concealed units)
		5. Monitor and cleanup

	Parameter(s):
		_zone - Zone marker name [STRING]
		_ambushPos - Position for the ambush [ARRAY]
		_roadKey - Road key for tracking [STRING]

	Returns:
		Ambush data object [OBJECT] - namespace for tracking ambush state

	Example(s):
		["zone_ba_ria", [1000, 2000, 0], "MAIN_1000_2000_1100_2100"] call vn_mf_fnc_commander_create_ambush;
*/

params ["_zone", "_ambushPos", "_roadKey"];

// Create ambush data store using hashmap
private _ambushData = createHashMap;
_ambushData set ["zone", _zone];
_ambushData set ["ambushPos", _ambushPos];
_ambushData set ["roadKey", _roadKey];
_ambushData set ["phase", "SPAWNING"];
_ambushData set ["ambush_active", true];
_ambushData set ["createdTime", serverTime];

// Configuration
private _squadSize = 4; // Squad size per side (8 total units)
private _movementTimeout = 600; // 10 minutes to reach position
private _ambushRange = 50; // Range around ambush position to consider "arrived"

// Store timeout in the data structure for scheduler access
_ambushData set ["movementTimeout", _movementTimeout];
_ambushData set ["ambushRange", _ambushRange];

// Step 1: Spawn single movement squad at zone FOB using Paradigm functions
private _zonePos = markerPos _zone;
private _fobPos = _zonePos; // TODO: Find actual FOB position, for now use zone center

// Find good spawn position near the FOB
private _spawnPos = [_fobPos, 100, 200, 5, 0, 20, 0] call BIS_fnc_findSafePos;
if (_spawnPos isEqualTo []) then { _spawnPos = _fobPos; };

systemChat format ["SP Mikeforce - Spawning movement squad for zone %1", _zone];

// Single movement squad to scout and secure ambush position
private _movementComposition = ["STANDARD", east, _squadSize, _spawnPos] call para_g_fnc_spawning_get_squad_composition;
private _movementResult = [_movementComposition, east, _spawnPos] call para_g_fnc_create_squad;
_movementResult params ["_movementUnits", "_movementGroup"];

// Set group properties
_movementGroup setGroupIdGlobal [format ["Ambush_Scout_%1_%2", _zone, floor (random 1000)]];

// Setup ambush data structure
_ambushData set ["movementGroup", _movementGroup];
_ambushData set ["spawnTime", serverTime];
_ambushData set ["phase", "MOVING"];
_ambushData set ["ambush_active", true];
_ambushData set ["ambushPos", _ambushPos];
_ambushData set ["movementTimeout", 300]; // 5 minutes
_ambushData set ["ambushRange", 150]; // Distance threshold for arrival

// Create debug marker for ambush position
private _markerName = format ["ambush_%1", _roadKey];
private _marker = createMarker [_markerName, _ambushPos];
_marker setMarkerType "mil_dot";
_marker setMarkerColor "ColorGreen";

// Give movement orders to scout group
_movementGroup move _ambushPos;
_movementGroup setBehaviour "SAFE";
_movementGroup setSpeedMode "LIMITED";
_movementGroup setCombatMode "GREEN"; // No engagement during movement

systemChat format ["SP Mikeforce - Scout squad moving to ambush position %1", _ambushPos];

// Schedule monitoring of movement and subsequent phases
["ambush_monitor", {
	params ["_ambushData"];
	
	// Check if ambush is still valid
	if (!(_ambushData get "ambush_active")) exitWith {
		[_ambushData] call vn_mf_fnc_commander_cleanup_ambush;
	};
	
	private _phase = _ambushData get "phase";
	private _movementGroup = _ambushData get "movementGroup";
	private _ambushPos = _ambushData get "ambushPos";
	private _movementTimeout = _ambushData get "movementTimeout";
	private _ambushRange = _ambushData get "ambushRange";
	
	if (_phase == "SPAWNING" || _phase == "MOVING") then {
		// Check if movement group still exists and is alive
		if (isNull _movementGroup || !alive (leader _movementGroup) || count (units _movementGroup select {alive _x}) == 0) exitWith {
			systemChat format ["SP Mikeforce - Scout squad eliminated during movement, aborting"];
			[_ambushData] call vn_mf_fnc_commander_cleanup_ambush;
		};
		
		// Check for combat engagement during movement
		if (behaviour (leader _movementGroup) in ["COMBAT", "AWARE"]) exitWith {
			systemChat format ["SP Mikeforce - Scout squad engaged in combat during movement, aborting"];
			[_ambushData] call vn_mf_fnc_commander_cleanup_ambush;
		};
		
		// Check if movement timeout exceeded
		if (serverTime - (_ambushData get "spawnTime") > _movementTimeout) exitWith {
			systemChat format ["SP Mikeforce - Scout squad movement timeout, aborting"];
			[_ambushData] call vn_mf_fnc_commander_cleanup_ambush;
		};
		
		// Check if scout squad has arrived at ambush position
		private _scoutDist = (leader _movementGroup) distance2D _ambushPos;
		
		if (_scoutDist < _ambushRange) then {
			_ambushData set ["phase", "ARRIVED"];
			systemChat format ["SP Mikeforce - Scout squad arrived at ambush position"];
		};
	};
	
	if (_phase == "ARRIVED") then {
		// Step 3: Arrival Assessment - check if scout squad is in combat
		if (behaviour (leader _movementGroup) in ["COMBAT", "AWARE"]) exitWith {
			systemChat format ["SP Mikeforce - Scout squad in combat on arrival, aborting"];
			[_ambushData] call vn_mf_fnc_commander_cleanup_ambush;
		};
		
		// Step 4: Despawn movement group and spawn ambush squads
		systemChat format ["SP Mikeforce - Scout secured area, deploying ambush squads at %1", _ambushPos];
		
		// Remove the movement group
		{
			deleteVehicle _x;
		} forEach (units _movementGroup);
		deleteGroup _movementGroup;
		
		// Now call setup ambush which will spawn the two tactical squads
		[_ambushData] call vn_mf_fnc_commander_setup_ambush;
		_ambushData set ["phase", "ACTIVE"];
	};
	
	if (_phase == "ACTIVE") then {
		// Monitor active ambush for triggers or destruction
		private _suppressionGroup = _ambushData getOrDefault ["suppressionGroup", grpNull];
		private _assaultGroup = _ambushData getOrDefault ["assaultGroup", grpNull];
		
		// Check if groups exist (they're created during setup)
		if (isNull _suppressionGroup || isNull _assaultGroup) exitWith {
			// Still setting up, continue monitoring
		};
		
		private _suppressionUnits = units _suppressionGroup select {alive _x};
		private _assaultUnits = units _assaultGroup select {alive _x};
		private _allUnits = _suppressionUnits + _assaultUnits;
		
		if (count _allUnits == 0) exitWith {
			systemChat format ["SP Mikeforce - Both ambush squads destroyed, cleaning up"];
			[_ambushData] call vn_mf_fnc_commander_cleanup_ambush;
		};
		
		// Check if ambush has been triggered (units are in combat)
		private _triggered = false;
		{
			if (behaviour _x in ["COMBAT", "AWARE"]) then { _triggered = true; };
		} forEach _allUnits;
		
		if (_triggered && (_ambushData getOrDefault ["phase", ""]) != "TRIGGERED") then {
			// Use centralized trigger function
			[_ambushData] call vn_mf_fnc_commander_trigger_ambush;
		};
		
		// After engagement, attempt withdrawal
		if (_phase == "TRIGGERED" && (serverTime - (_ambushData getOrDefault ["triggerTime", 0])) > 180) then {
			systemChat format ["SP Mikeforce - Ambush squads withdrawing after engagement"];
			{
				if (alive _x) then {
					_x doMove ([_ambushPos, 500, 800] call BIS_fnc_relPos);
				};
			} forEach _allUnits;
			_ambushData set ["phase", "WITHDRAWING"];
		};
		
		// Cleanup after withdrawal
		if (_phase == "WITHDRAWING" && (serverTime - (_ambushData getOrDefault ["triggerTime", 0])) > 300) then {
			[_ambushData] call vn_mf_fnc_commander_cleanup_ambush;
		};
	};
	
}, [_ambushData], 10] call para_g_fnc_scheduler_add_job;

// Add to zone commander's active ambushes
private _commanderData = missionNamespace getVariable format ["commander_%1_data", _zone];
private _activeAmbushes = _commanderData get "activeAmbushes";
_activeAmbushes pushBack _ambushData;
_commanderData set ["activeAmbushes", _activeAmbushes];

_ambushData
