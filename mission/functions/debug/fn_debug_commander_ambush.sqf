/*
	File: fn_debug_commander_ambush.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Debug command for commander ambush system.
		Lists available zones and their commander data,
		and provides easy commands to force ambushes.

	Parameter(s):
		_action - Action to perform: "list", "force", "status" [STRING]
		_zone - Zone name (required for "force" and "status" actions) [STRING]

	Returns:
		None

	Example(s):
		["list"] call vn_mf_fnc_debug_commander_ambush;
		["force", "zone_1"] call vn_mf_fnc_debug_commander_ambush;
		["status", "zone_1"] call vn_mf_fnc_debug_commander_ambush;
*/

params [["_action", "list", [""]], ["_zone", "", [""]]];

switch (toLower _action) do {
	case "list": {
		systemChat "SP Mikeforce - Commander Ambush Debug: Available Zones";
		systemChat "================================================";
		
		// Get all zone commander data from mission namespace
		private _foundZones = [];
		{
			private _varName = _x;
			if (_varName find "commander_" == 0 && _varName find "_data" > 0) then {
				private _zoneName = _varName select [10, (count _varName) - 15]; // Remove "commander_" and "_data"
				_foundZones pushBack _zoneName;
			};
		} forEach (allVariables missionNamespace);
		
		if (count _foundZones == 0) then {
			systemChat "No commander zones found. Try after some zones have been initialized.";
		} else {
			{
				private _commanderData = missionNamespace getVariable [format ["commander_%1_data", _x], createHashMap];
				private _activeAmbushes = count (_commanderData getOrDefault ["activeAmbushes", []]);
				private _lastAmbush = _commanderData getOrDefault ["lastAmbushTime", 0];
				private _forcedCount = _commanderData getOrDefault ["forcedAmbushCount", 0];
				
				systemChat format ["Zone: %1 | Active: %2 | Last: %3s ago | Forced: %4", 
					_x, _activeAmbushes, floor (time - _lastAmbush), _forcedCount];
			} forEach _foundZones;
		};
		
		systemChat "================================================";
		systemChat "Commands:";
		systemChat """[""force"", ""zone_name""] call vn_mf_fnc_debug_commander_ambush;""";
		systemChat """[""status"", ""zone_name""] call vn_mf_fnc_debug_commander_ambush;""";
	};
	
	case "force": {
		if (_zone == "") exitWith {
			systemChat "SP Mikeforce - Error: Zone name required for force command";
			systemChat """Usage: [""force"", ""zone_name""] call vn_mf_fnc_debug_commander_ambush;""";
		};
		
		systemChat format ["SP Mikeforce - Attempting to force ambush for zone: %1", _zone];
		private _success = [_zone] call vn_mf_fnc_commander_force_ambush;
		
		if (!_success) then {
			systemChat format ["SP Mikeforce - Force ambush failed for zone %1. Check if zone exists and has road data.", _zone];
		};
	};
	
	case "status": {
		if (_zone == "") exitWith {
			systemChat "SP Mikeforce - Error: Zone name required for status command";
			systemChat """Usage: [""status"", ""zone_name""] call vn_mf_fnc_debug_commander_ambush;""";
		};
		
		private _commanderData = missionNamespace getVariable [format ["commander_%1_data", _zone], createHashMap];
		if (_commanderData isEqualTo createHashMap) exitWith {
			systemChat format ["SP Mikeforce - Zone %1 not found or not initialized", _zone];
		};
		
		systemChat format ["SP Mikeforce - Status for zone: %1", _zone];
		systemChat "================================";
		
		private _activeAmbushes = _commanderData getOrDefault ["activeAmbushes", []];
		private _maxAmbushes = _commanderData getOrDefault ["maxAmbushes", 2];
		private _lastAmbush = _commanderData getOrDefault ["lastAmbushTime", 0];
		private _cooldown = _commanderData getOrDefault ["ambushCooldown", 300];
		private _forcedCount = _commanderData getOrDefault ["forcedAmbushCount", 0];
		
		systemChat format ["Active Ambushes: %1/%2", count _activeAmbushes, _maxAmbushes];
		systemChat format ["Last Ambush: %1 seconds ago", floor (time - _lastAmbush)];
		systemChat format ["Cooldown: %1 seconds", _cooldown];
		systemChat format ["Cooldown Ready: %1", if (time - _lastAmbush >= _cooldown) then {"YES"} else {"NO"}];
		systemChat format ["Forced Ambushes: %1", _forcedCount];
		
		// Show active ambush details
		{
			private _ambushData = _x;
			private _phase = _ambushData getOrDefault ["phase", "unknown"];
			private _ambushPos = _ambushData getOrDefault ["ambushPos", [0,0,0]];
			systemChat format ["  Ambush %1: Phase %2 at %3", _forEachIndex + 1, _phase, _ambushPos];
		} forEach _activeAmbushes;
	};
	
	default {
		systemChat "SP Mikeforce - Commander Ambush Debug Commands:";
		systemChat """[""list""] call vn_mf_fnc_debug_commander_ambush; // List all zones""";
		systemChat """[""force"", ""zone_name""] call vn_mf_fnc_debug_commander_ambush; // Force ambush""";
		systemChat """[""status"", ""zone_name""] call vn_mf_fnc_debug_commander_ambush; // Zone status""";
	};
};
