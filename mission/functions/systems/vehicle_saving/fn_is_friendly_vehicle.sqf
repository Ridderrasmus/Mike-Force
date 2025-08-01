/*
    File: fn_is_friendly_vehicle.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Checks if a vehicle belongs to the player's faction and should be saved.
        Uses the vehicle respawn info configuration to determine valid vehicles.

    Parameter(s):
        _vehicle - The vehicle to check [OBJECT]

    Returns: 
        _isFriendly - Whether the vehicle belongs to player faction [BOOL]

    Example(s):
        [someVehicle] call vn_mf_fnc_is_friendly_vehicle;
*/

params ["_vehicle"];

if (isNull _vehicle) exitWith { false };

private _vehicleClass = typeOf _vehicle;

// Check if vehicle class is defined in the respawn info config
private _isConfigured = isClass (missionConfigFile >> "gamemode" >> "vehicle_respawn_info" >> "vehicles" >> _vehicleClass);

if (_isConfigured) exitWith { true };

// Fallback: Check faction prefixes for friendly vehicles
private _friendlyPrefixes = ["vn_b_", "vn_c_", "vnx_b_"];
private _isFriendlyPrefix = false;

{
    if (_vehicleClass find _x == 0) exitWith {
        _isFriendlyPrefix = true;
    };
} forEach _friendlyPrefixes;

// Also check vehicle's actual faction
private _vehicleFaction = faction _vehicle;
private _friendlyFactions = ["BLU_F", "CIV_F", "blu_f", "civ_f"];

private _isFriendlyFaction = _vehicleFaction in _friendlyFactions;

// Vehicle is friendly if it matches prefix OR faction OR is configured
(_isFriendlyPrefix || _isFriendlyFaction || _isConfigured)
