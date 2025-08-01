/*
    File: fn_start_save_loop.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Initializes the new event-based vehicle saving system.
        This should be called during server initialization to set up the tracking.

    Parameter(s):
        _minBtwnSaves - The amount of minutes between saves [INT] (default: 20)

    Returns: nothing

    Example(s):
        [] call vn_mf_fnc_start_save_loop;
        [15] call vn_mf_fnc_start_save_loop;
*/

params [["_minBtwnSaves", 20]];

if (!isServer) exitWith {};

diag_log "VN MikeForce: Initializing event-based vehicle saving system...";

// Initialize event tracking for vehicles
[] call vn_mf_fnc_init_event_tracking;

// Clean up any existing non-friendly vehicles from tracking
[] call vn_mf_fnc_cleanup_tracked_vehicles;

// Start the autosave loop
_minBtwnSaves spawn {
    while {true} do {
        sleep (_this * 60);
        [] call vn_mf_fnc_full_save;
    };
};

diag_log format ["VN MikeForce: Vehicle saving system initialized with %1 minute intervals", _minBtwnSaves];
