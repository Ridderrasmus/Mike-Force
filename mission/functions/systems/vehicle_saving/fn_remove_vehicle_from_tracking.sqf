/*
    File: fn_remove_vehicle_from_tracking.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Manually removes a vehicle from the tracking system.
        Useful for temporary vehicles that shouldn't be saved.

    Parameter(s):
        _vehicle - The vehicle to remove from tracking [OBJECT]

    Returns: 
        _success - Whether the vehicle was successfully removed [BOOL]

    Example(s):
        [myTempVehicle] call vn_mf_fnc_remove_vehicle_from_tracking;
*/

params ["_vehicle"];

private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];

// Check if tracked
if !(_vehicle in _trackedVehicles) exitWith { false };

// Remove from tracking
_trackedVehicles = _trackedVehicles - [_vehicle];
missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];

// Mark as temporary to prevent re-adding
_vehicle setVariable ["vn_mf_temp_vehicle", true, true];

diag_log format ["VN MikeForce: Removed vehicle %1 from tracking", typeOf _vehicle];

true
