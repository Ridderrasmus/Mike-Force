/*
	File: fn_commander_force_ambush.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Forces a zone commander to immediately send out an ambush,
		bypassing cooldown restrictions and other conditions.
		Useful for testing and debugging ambush systems.

	Parameter(s):
		_zone - Zone name to force ambush for [STRING]

	Returns:
		_success - Whether the ambush was successfully forced [BOOL]

	Example(s):
		["zone_1"] call vn_mf_fnc_commander_force_ambush;
		["cam_lao_nam_01"] call vn_mf_fnc_commander_force_ambush;
*/

params [["_zone", "", [""]]];

if (_zone == "") exitWith {
	systemChat "SP Mikeforce - Error: No zone specified for forced ambush";
	false
};

// Get or create commander data for the zone
private _commanderData = missionNamespace getVariable [format ["commander_%1_data", _zone], createHashMap];
if (_commanderData isEqualTo createHashMap) then {
	missionNamespace setVariable [format ["commander_%1_data", _zone], _commanderData];
};

// Check if zone already has maximum ambushes
private _activeAmbushes = _commanderData getOrDefault ["activeAmbushes", []];
private _maxAmbushes = _commanderData getOrDefault ["maxAmbushes", 2];

if (count _activeAmbushes >= _maxAmbushes) then {
	systemChat format ["SP Mikeforce - Warning: Zone %1 already has maximum ambushes (%2/%3)", 
		_zone, count _activeAmbushes, _maxAmbushes];
	// Continue anyway since this is a forced command
};

// Temporarily bypass cooldown by resetting last ambush time
private _originalLastAmbush = _commanderData getOrDefault ["lastAmbushTime", 0];
_commanderData set ["lastAmbushTime", 0];

systemChat format ["SP Mikeforce - Forcing ambush for zone %1 (bypassing cooldown)", _zone];

// Call the commander logic to create ambush
private _success = [_zone] call vn_mf_fnc_commander_logic;

if (_success) then {
	systemChat format ["SP Mikeforce - Successfully forced ambush creation for zone %1", _zone];
	
	// Update the forced ambush counter for tracking
	private _forcedCount = _commanderData getOrDefault ["forcedAmbushCount", 0];
	_commanderData set ["forcedAmbushCount", _forcedCount + 1];
} else {
	systemChat format ["SP Mikeforce - Failed to force ambush for zone %1 - check road usage data", _zone];
	
	// Restore original cooldown time since ambush failed
	_commanderData set ["lastAmbushTime", _originalLastAmbush];
};

_success
