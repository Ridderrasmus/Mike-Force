/*
	File: fn_commander_init.sqf
	Author: Ridderrasmus
	Public: No

	Description:
	    Initiates the commander AI loop when a zone is activated.

	Parameter(s):
		None

	Returns:
		None

	Example(s):
		[] call vn_mf_fnc_commander_init;
*/

if (!isServer) exitWith {};


["zoneActivated", [
	{
		params ["_args", "_zone"];
		// Start the commander AI loop for the activated zone
		[format ["commander_loop_%1", _zone], vn_mf_fnc_commander_logic, [_zone], 600] call para_g_fnc_scheduler_add_job;

		systemChat format ["SP Mikeforce - Commander AI loop started for zone: %1", _zone];
	},
	[]
]] call para_g_fnc_event_add_handler;

["zoneDeactivated", [
	{
		params ["_args", "_zone"];
		// Stop the commander AI loop for the deactivated zone
		[format ["commander_loop_%1", _zone]] call para_g_fnc_scheduler_remove_job;

		systemChat format ["SP Mikeforce - Commander AI loop stopped for zone: %1", _zone];
	}, 
	[]
]] call para_g_fnc_event_add_handler;