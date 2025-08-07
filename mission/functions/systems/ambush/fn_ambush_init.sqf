/*
	File: fn_ambush_init.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		When called on the server it will:
			This function runs the initial road network analysis for all the points along the roads that are eligible ambush positions.
			It also sets up the necessary event handlers and initial state for ambushes.

		When called on the client it will:
			This function is used to initialize the ambush system on the client side.
			Begin the scheduler that tracks road usage and reports this back to the server.

	Parameter(s):
		None

	Returns:
		None

	Example(s):
		[] call vn_mf_fnc_ambush_init;
*/

if (isServer) then {
	// Server-side initialization
	// Preprocess the roads for ambush points
	[] call vn_mf_fnc_preprocess_roads;

	// Start road usage decay scheduler job
	["road_usage_decay", {
		private _roadUsageData = missionNamespace getVariable ["vn_mf_road_usage", createHashMap];
		private _decayRate = 0.2; // 20% decay every 30 seconds
		private _decayUpdates = []; // Collect decay updates for atomic processing
		
		{
			private _roadKey = _x;
			private _currentUsage = _y;
			private _decayAmount = _currentUsage * _decayRate;
			private _newUsage = _currentUsage - _decayAmount;
			
			// Remove roads with very low usage to prevent hashmap bloat
			if (_newUsage < 0.1) then {
				// Set to negative value to signal removal in process function
				_decayUpdates pushBack [_roadKey, -_currentUsage];
			} else {
				// Add negative increment to reduce usage
				_decayUpdates pushBack [_roadKey, -_decayAmount];
			};
		} forEach _roadUsageData;
		
		// Use the same atomic processing function as road usage ticker
		if (count _decayUpdates > 0) then {
			[_decayUpdates] call vn_mf_fnc_process_road_usage_updates;
			systemChat format ["SP Mikeforce - Road usage decay: %1 roads processed with %2%% decay", count _decayUpdates, _decayRate * 100];
		};
	}, [], 30] call para_g_fnc_scheduler_add_job; // Run every 30 seconds

	diag_log "SP MikeForce: Ambush system initialized on server";
};

if (hasInterface) then {
	// Client-side initialization
	// Start road usage tracking scheduler job
	["road_usage_tracker", {
		[player] call vn_mf_fnc_road_usage_ticker;
	}, [], 30] call para_g_fnc_scheduler_add_job; // Run every 30 seconds
	
	diag_log "SP MikeForce: Ambush system initialized on client - road usage tracking started";
};