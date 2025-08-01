/*
    File: fn_cleanup_tracked_vehicles.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Cleans up the tracked vehicles array by removing any non-friendly vehicles.
        This is useful to clean up tracking arrays that may contain enemy vehicles
        from before faction filtering was implemented.

    Parameter(s):
        None

    Returns: 
        _removedCount - Number of vehicles removed [NUMBER]

    Example(s):
        [] call vn_mf_fnc_cleanup_tracked_vehicles;
*/

if (!isServer) exitWith { 0 };

private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
private _originalCount = count _trackedVehicles;

// Filter out non-friendly vehicles
private _friendlyVehicles = _trackedVehicles select {
    !isNull _x && 
    alive _x && 
    ([_x] call vn_mf_fnc_is_friendly_vehicle)
};

// Update the tracking array
missionNamespace setVariable ["vn_mf_tracked_vehicles", _friendlyVehicles, true];

private _removedCount = _originalCount - (count _friendlyVehicles);

if (_removedCount > 0) then {
    diag_log format ["VN MikeForce: Cleaned up %1 non-friendly vehicles from tracking. %2 friendly vehicles remain.", 
        _removedCount, count _friendlyVehicles];
} else {
    diag_log format ["VN MikeForce: No cleanup needed. %1 friendly vehicles in tracking.", count _friendlyVehicles];
};

_removedCount
