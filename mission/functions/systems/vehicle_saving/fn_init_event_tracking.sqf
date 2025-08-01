/*
    File: fn_init_event_tracking.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Initializes event-based vehicle tracking for the new save/load system.
        This replaces the old ID-based tracking system.

    Parameter(s):
        None

    Returns: nothing

    Example(s):
        [] call vn_mf_fnc_init_event_tracking;
*/

if (!isServer) exitWith {};

// Initialize the global vehicle and crate tracking arrays
missionNamespace setVariable ["vn_mf_tracked_vehicles", [], true];
missionNamespace setVariable ["vn_mf_tracked_crates", [], true];

// Get crate types that should be tracked
private _supplyDropsConfig = "true" configClasses (missionConfigFile >> "gamemode" >> "supplydrops");
private _crateTypeArray = [];
{
     _crateTypeArray append ("true" configClasses _x apply {
        getText (_x >> "className");
    });
    _crateTypeArray = _crateTypeArray arrayIntersect _crateTypeArray;
} forEach _supplyDropsConfig;

// Add event handler for when vehicles/crates are created
["vehicleCreated", [
    {
        params ["_args", "_object"];

		diag_log format ["VN MikeForce: Tracking new object %1 of type %2", _object, typeOf _object];
        
        // Only track objects that should be saved (not temporary ones)
        if (!isNull _object && alive _object) then {
            private _objectType = typeOf _object;
            
            // Check if it's a vehicle or a trackable crate
            if (_object isKindOf "AllVehicles") then {
                // Only track friendly faction vehicles
                if ([_object] call vn_mf_fnc_is_friendly_vehicle && !(_object getVariable ["vn_mf_temp_vehicle", false])) then {
                    private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
                    
                    // Avoid duplicates
                    if !(_object in _trackedVehicles) then {
                        _trackedVehicles pushBack _object;
                        missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
                        
                        diag_log format ["VN MikeForce: Added friendly vehicle %1 (%2) to tracking", typeOf _object, _object];
                        
                        // Add event handlers for cleanup
                        _object addEventHandler ["Killed", {
                            params ["_object"];
                            private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
                            _trackedVehicles = _trackedVehicles - [_object];
                            missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
                        }];
                        
                        _object addEventHandler ["Deleted", {
                            params ["_object"];
                            private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
                            _trackedVehicles = _trackedVehicles - [_object];
                            missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
                        }];
                    };
                } else {
                    diag_log format ["VN MikeForce: Skipping non-friendly vehicle %1 (%2)", typeOf _object, _object];
                };
            } else {
                // Check if it's a trackable crate type
                private _crateTypeArray = missionNamespace getVariable ["vn_mf_crate_types", []];
                if (_objectType in _crateTypeArray && 
                    !((_object getVariable ["supply_drop_config", ""]) isEqualTo "") &&
                    !(_object getVariable ["vn_mf_temp_crate", false])) then {
                    
                    private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
                    
                    if !(_object in _trackedCrates) then {
                        _trackedCrates pushBack _object;
                        missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
                        
                        // Add event handlers for cleanup
                        _object addEventHandler ["Killed", {
                            params ["_object"];
                            private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
                            _trackedCrates = _trackedCrates - [_object];
                            missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
                        }];
                        
                        _object addEventHandler ["Deleted", {
                            params ["_object"];
                            private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
                            _trackedCrates = _trackedCrates - [_object];
                            missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
                        }];
                    };
                };
            };
        };
    },
    []
]] call para_g_fnc_event_add_handler;

// Store crate types for future reference
missionNamespace setVariable ["vn_mf_crate_types", _crateTypeArray, true];

// Also track existing vehicles and crates on mission start
private _existingVehicles = vehicles select {
    alive _x && 
    !(_x call vn_mf_fnc_area_check) && 
    !(_x getVariable ["vn_mf_temp_vehicle", false]) &&
    ([_x] call vn_mf_fnc_is_friendly_vehicle)
};

private _existingCrates = entities [_crateTypeArray, [], false, true] select {
    alive _x &&
    !(_x call vn_mf_fnc_area_check) &&
    !((_x getVariable ["supply_drop_config", ""]) isEqualTo "") &&
    !(_x getVariable ["vn_mf_temp_crate", false])
};

// Track existing vehicles
{
    private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
    if !(_x in _trackedVehicles) then {
        _trackedVehicles pushBack _x;
        missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
        
        // Add event handlers for existing vehicles
        _x addEventHandler ["Killed", {
            params ["_vehicle"];
            private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
            _trackedVehicles = _trackedVehicles - [_vehicle];
            missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
        }];
        
        _x addEventHandler ["Deleted", {
            params ["_vehicle"];
            private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
            _trackedVehicles = _trackedVehicles - [_vehicle];
            missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
        }];
    };
} forEach _existingVehicles;

// Track existing crates
{
    private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
    if !(_x in _trackedCrates) then {
        _trackedCrates pushBack _x;
        missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
        
        // Add event handlers for existing crates
        _x addEventHandler ["Killed", {
            params ["_crate"];
            private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
            _trackedCrates = _trackedCrates - [_crate];
            missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
        }];
        
        _x addEventHandler ["Deleted", {
            params ["_crate"];
            private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
            _trackedCrates = _trackedCrates - [_crate];
            missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
        }];
    };
} forEach _existingCrates;

diag_log format ["VN MikeForce: Vehicle/Crate tracking initialized. Tracking %1 vehicles and %2 crates.", 
    count (missionNamespace getVariable ["vn_mf_tracked_vehicles", []]),
    count (missionNamespace getVariable ["vn_mf_tracked_crates", []])
];
