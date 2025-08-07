/*
	File: fn_commander_cleanup_ambush.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Cleans up an ambush operation by removing units, mines, and updating
		zone commander data.

	Parameter(s):
		_ambushData - Ambush data namespace [OBJECT]

	Returns:
		None

	Example(s):
		[_ambushData] call vn_mf_fnc_commander_cleanup_ambush;
*/

params ["_ambushData"];

private _zone = _ambushData getOrDefault ["zone", ""];

// Clean up movement group if it still exists
private _movementGroup = _ambushData getOrDefault ["movementGroup", grpNull];
if (!isNull _movementGroup) then {
	{
		if (alive _x) then { deleteVehicle _x; };
	} forEach (units _movementGroup);
	deleteGroup _movementGroup;
};

// Clean up suppression squad if it exists
private _suppressionGroup = _ambushData getOrDefault ["suppressionGroup", grpNull];
if (!isNull _suppressionGroup) then {
	{
		if (alive _x) then { deleteVehicle _x; };
	} forEach (units _suppressionGroup);
	deleteGroup _suppressionGroup;
};

// Clean up assault squad if it exists
private _assaultGroup = _ambushData getOrDefault ["assaultGroup", grpNull];
if (!isNull _assaultGroup) then {
	{
		if (alive _x) then { deleteVehicle _x; };
	} forEach (units _assaultGroup);
	deleteGroup _assaultGroup;
};

// Clean up legacy ambush group if it exists (backward compatibility)
private _ambushGroup = _ambushData getOrDefault ["ambushGroup", grpNull];
if (!isNull _ambushGroup) then {
	{
		if (alive _x) then { deleteVehicle _x; };
	} forEach (units _ambushGroup);
	deleteGroup _ambushGroup;
};

// Clean up mine if it exists
private _mine = _ambushData getOrDefault ["mine", objNull];
if (!isNull _mine) then {
	deleteVehicle _mine;
};

// Clean up trigger if it exists
private _trigger = _ambushData getOrDefault ["trigger", objNull];
if (!isNull _trigger) then {
	deleteVehicle _trigger;
};

// Mark ambush as inactive
_ambushData set ["ambush_active", false];

// Remove from zone commander's active ambush list
if (_zone != "") then {
	private _commanderData = missionNamespace getVariable [format ["commander_%1_data", _zone], createHashMap];
	private _activeAmbushes = _commanderData getOrDefault ["activeAmbushes", []];
	private _cleanedAmbushes = _activeAmbushes select { _x != _ambushData };
	_commanderData set ["activeAmbushes", _cleanedAmbushes];
	
	systemChat format ["SP Mikeforce - Cleaned up dual-squad ambush for zone %1. Active ambushes: %2", 
		_zone, count _cleanedAmbushes];
};
