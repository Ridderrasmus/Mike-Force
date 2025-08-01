/*
    File: fn_full_save.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Starts saving all vehicles and crates using the new event-based tracking system.

    Parameter(s):
        NONE

    Returns: nothing

    Example(s):
        [] call vn_mf_fnc_full_save;
*/

if (!isServer) exitWith {};

["SET", "veh_save_data", []] call para_s_fnc_profile_db;

// Get tracked vehicles from the global tracking system
private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];

// Filter out vehicles that are in restricted areas, destroyed, or not friendly
private _vehicles = _trackedVehicles select {
    !isNull _x && 
    alive _x && 
    !(_x call vn_mf_fnc_area_check) &&
    ([_x] call vn_mf_fnc_is_friendly_vehicle)
};

// Get tracked crates from the global tracking system
private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];

// Filter out crates that are in restricted areas or destroyed
private _crates = _trackedCrates select {
    !isNull _x && 
    alive _x && 
    !(_x call vn_mf_fnc_area_check)
};

// Prepare save data variable
private _saveData = [[], []];

// Save all tracked vehicles
private _vehsToSave = [];
{
    if (!isNull _x && alive _x) then {
        private _vehData = [_x] call vn_mf_fnc_veh_get_data;
        if (count _vehData > 0) then {
            _vehsToSave pushBack _vehData;
            diag_log format ["VN MikeForce: Saving friendly vehicle %1 at %2", typeOf _x, getPosWorld _x];
        };
    };
} forEach _vehicles;

diag_log format ["VN MikeForce: Filtered %1 friendly vehicles for saving from %2 tracked vehicles", 
    count _vehicles, count _trackedVehicles];

_saveData set [0, _vehsToSave];

// Save all crates using new system
private _cratesToSave = [];
{ 
    if (!isNull _x && alive _x) then {
        private _crateData = [_x] call vn_mf_fnc_crate_save;
        if (count _crateData > 0) then {
            _cratesToSave pushBack _crateData;
        };
    };
} forEach _crates;

_saveData set [1, _cratesToSave];

// Clean up tracking arrays - remove null/dead objects
private _cleanedVehicles = _trackedVehicles select {!isNull _x && alive _x};
missionNamespace setVariable ["vn_mf_tracked_vehicles", _cleanedVehicles, true];

private _cleanedCrates = _trackedCrates select {!isNull _x && alive _x};
missionNamespace setVariable ["vn_mf_tracked_crates", _cleanedCrates, true];

// Save the data
["SET", "veh_save_data", _saveData] call para_s_fnc_profile_db;
["SAVE"] call para_s_fnc_profile_db;

private _vehicleCount = count _vehsToSave;
private _crateCount = count _cratesToSave;
private _message = format ["Save complete - %1 vehicles, %2 crates saved", _vehicleCount, _crateCount];

_message remoteExec ["systemChat", 0];
diag_log format ["VN MikeForce: %1", _message];
