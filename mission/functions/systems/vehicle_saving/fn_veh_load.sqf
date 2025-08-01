/*
    File: fn_veh_load.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Loads saved vehicle data and creates a new vehicle.
        Uses the new event-based tracking system.

    Parameter(s):
        _vehData - The data to load [ARRAY]

    Returns: 
        _vehicle - The created vehicle object [OBJECT]

    Example(s):
        [_savedVehicleData] call vn_mf_fnc_veh_load;
*/

params ["_vehData"];

if (count _vehData == 0) exitWith { objNull };

_vehData params ["_class", "_loc", "_data", "_dataCargo", ["_packaged", false], ["_customVars", []]];

// Create the vehicle at the saved position
private _veh = createVehicle [_class, (_loc select 0), [], 0, "CAN_COLLIDE"];

if (isNull _veh) exitWith {
    diag_log format ["VN MikeForce: Failed to create vehicle of class %1", _class];
    objNull
};

// Set position and direction
_veh setPosWorld (_loc select 0);
_veh setVectorDirAndUp (_loc select 1);

// Load saved damage and fuel
_veh setDamage (_data select 0);
_veh setFuel (_data select 1);

// Load turret magazines
private _mags = (_data select 2) select 0;
private _turretsData = (_data select 2) - _mags;

// Clear existing magazines from all turrets
{
    private _turret = _x;
    {
        _veh removeMagazineTurret [_x, _turret];
    } forEach (_veh magazinesTurret _turret);
} forEach allTurrets _veh;

// Add saved magazines
{
    _veh addMagazine _x;
} forEach _mags;

// Load saved inventory
private _inv = (_data select 3);
[_veh, _inv] call vn_mf_fnc_inv_set_data;

// Load saved fuel and ammo cargo
if ((_dataCargo select 0) != -1) then {
    _veh setFuelCargo (_dataCargo select 0);
};
if ((_dataCargo select 1) != -1) then {
    _veh setAmmoCargo (_dataCargo select 1);
};

// Restore custom variables
{
    _x params ["_varName", "_varValue"];
    _veh setVariable [_varName, _varValue, true];
} forEach _customVars;

// Mark as loaded to prevent duplicate loading
_veh setVariable ["rid_loaded", true, true];

// Handle packaging if needed
if (_packaged) then {
    [_veh] call vn_mf_fnc_veh_asset_package_wreck;
};

// Add to tracked vehicles list
private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
if !(_veh in _trackedVehicles) then {
    _trackedVehicles pushBack _veh;
    missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
    
    // Add event handlers
    _veh addEventHandler ["Killed", {
        params ["_vehicle"];
        private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
        _trackedVehicles = _trackedVehicles - [_vehicle];
        missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
    }];
    
    _veh addEventHandler ["Deleted", {
        params ["_vehicle"];
        private _trackedVehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
        _trackedVehicles = _trackedVehicles - [_vehicle];
        missionNamespace setVariable ["vn_mf_tracked_vehicles", _trackedVehicles, true];
    }];
};

diag_log format ["VN MikeForce: Loaded vehicle %1 at position %2", _class, _loc select 0];

_veh
