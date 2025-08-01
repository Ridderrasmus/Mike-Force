/*
    File: fn_full_load.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Starts loading all vehicles and crates using the new event-based system.
        This version creates vehicles directly instead of relying on asset IDs.

    Parameter(s):
        NONE

    Returns: nothing

    Example(s):
        [] call vn_mf_fnc_full_load;
*/

if (!isServer) exitWith {};

private _savedData = [[], []];

// Load saved data
["GET", "veh_save_data", _savedData] call para_s_fnc_profile_db params ["", "_savedData"];

// Load vehicles using the new system
private _loadedVehicles = [];
{
    private _vehicle = [_x] call vn_mf_fnc_veh_load;
    if (!isNull _vehicle) then {
        _loadedVehicles pushBack _vehicle;
    };
} forEach (_savedData select 0);

// Load crates using the new system
private _loadedCrates = [];
{
    private _crate = [_x] call vn_mf_fnc_crate_load;
    if (!isNull _crate) then {
        _loadedCrates pushBack _crate;
    };
} forEach (_savedData select 1);

private _vehicleCount = count _loadedVehicles;
private _crateCount = count _loadedCrates;
private _message = format ["Load complete - %1 vehicles, %2 crates loaded", _vehicleCount, _crateCount];

_message remoteExec ["systemChat", 0];
diag_log format ["VN MikeForce: %1", _message];
