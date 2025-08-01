/*
    File: fn_add_vehicle_to_tracking.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Manually adds a vehicle to the tracking system.
        Useful for vehicles that might not be caught by the automatic event system.

    Parameter(s):
        _vehicle - The vehicle to add to tracking [OBJECT]

    Returns: 
        _success - Whether the vehicle was successfully added [BOOL]

    Example(s):
        [myVehicle] call vn_mf_fnc_add_vehicle_to_tracking;
*/

params ["_vehicle"];

if (isNull _vehicle || !alive _vehicle) exitWith { false };

private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];

// Check if already tracked
if (_vehicle in _trackedVehicles) exitWith { true };

// Add to tracking
_trackedVehicles pushBack _vehicle;
missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];

// Add event handlers
_vehicle addEventHandler ["Killed", {
    params ["_vehicle"];
    private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
    _trackedVehicles = _trackedVehicles - [_vehicle];
    missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
}];

_vehicle addEventHandler ["Deleted", {
    params ["_vehicle"];
    private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
    _trackedVehicles = _trackedVehicles - [_vehicle];
    missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
}];

diag_log format ["VN MikeForce: Manually added vehicle %1 to tracking", typeOf _vehicle];

true
