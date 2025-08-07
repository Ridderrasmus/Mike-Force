/*
	File: fn_commander_trigger_ambush.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Triggers an ambush by activating both squads and removing concealment.
		Called by either mine trigger or FiredNear event handlers.

	Parameter(s):
		_ambushData - Ambush data hashmap [HASHMAP]

	Returns:
		None

	Example(s):
		[_ambushData] call vn_mf_fnc_commander_trigger_ambush;
*/

params ["_ambushData"];

// Check if ambush is already triggered
private _phase = _ambushData getOrDefault ["phase", ""];
if (_phase == "TRIGGERED") exitWith {
	// Already triggered, do nothing
};

// Get both squads
private _suppressionGroup = _ambushData getOrDefault ["suppressionGroup", grpNull];
private _assaultGroup = _ambushData getOrDefault ["assaultGroup", grpNull];

if (isNull _suppressionGroup || isNull _assaultGroup) exitWith {
	systemChat "SP Mikeforce - Error: Ambush squads not found during trigger";
};

// Mark as triggered
_ambushData set ["phase", "TRIGGERED"];
_ambushData set ["triggerTime", serverTime];

systemChat "SP Mikeforce - AMBUSH TRIGGERED! Both squads engaging!";

// Activate suppression squad
private _suppressionUnits = units _suppressionGroup select {alive _x};
{
	_x setBehaviour "COMBAT";
	_x setCombatMode "RED";
	_x setSkill ["courage", 0.9]; // Higher courage for suppression role
	_x setCaptive false; // Remove concealment
	
	// Remove FiredNear event handler to prevent multiple triggers
	_x removeAllEventHandlers "FiredNear";
} forEach _suppressionUnits;

// Activate assault squad
private _assaultUnits = units _assaultGroup select {alive _x};
{
	_x setBehaviour "COMBAT";
	_x setCombatMode "RED";
	_x setSkill ["courage", 0.8]; // Standard courage for assault
	_x setCaptive false; // Remove concealment
	
	// Remove FiredNear event handler to prevent multiple triggers
	_x removeAllEventHandlers "FiredNear";
} forEach _assaultUnits;

// Detonate mine if it still exists
private _mine = _ambushData getOrDefault ["mine", objNull];
if (!isNull _mine && alive _mine) then {
	_mine setDamage 1; // Detonate the mine
	systemChat "SP Mikeforce - Ambush mine detonated!";
};

systemChat format ["SP Mikeforce - %1 suppression units and %2 assault units now engaging", 
	count _suppressionUnits, count _assaultUnits];
