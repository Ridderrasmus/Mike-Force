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