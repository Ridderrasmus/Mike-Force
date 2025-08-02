/*
	File: fn_commander_loop.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Main loop for the commander AI. Handles decision making and action execution.

	Parameter(s):
		None

	Returns:
		None

	Example(s):
		[] call vn_mf_fnc_commander_loop;
*/

params ["_zone"];


// AMBUSH STUFF


systemChat format ["SP Mikeforce - Commander AI loop running for zone: %1", _zone];


