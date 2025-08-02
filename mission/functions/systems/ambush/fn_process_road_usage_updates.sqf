/*
	File: fn_process_road_usage_updates.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Processes road usage updates from clients in an atomic way to prevent race conditions.
		This function runs only on the server and handles all updates sequentially.

	Parameter(s):
		_usageUpdates - Array of [roadKey, incrementValue] pairs to process [ARRAY]

	Returns:
		None

	Example(s):
		// Called automatically from client via remoteExec
		[_usageUpdates] remoteExec ["vn_mf_fnc_process_road_usage_updates", 2];
*/

// Only run on server
if (!isServer) exitWith {};

params ["_usageUpdates"];

// Get the current road usage map
private _roadUsageMap = missionNamespace getVariable ["vn_mf_road_usage", createHashMap];

// Process all updates atomically
{
	_x params ["_roadKey", "_increment"];
	
	// Get current usage and add increment
	private _currentUsage = _roadUsageMap getOrDefault [_roadKey, 0];
	_roadUsageMap set [_roadKey, _currentUsage + _increment];
	
} forEach _usageUpdates;

// Update the global map once after all changes
missionNamespace setVariable ["vn_mf_road_usage", _roadUsageMap, true];

// Optional: Log summary of updates (remove in production)
// diag_log format ["SP MikeForce: Processed %1 road usage updates", count _usageUpdates];
