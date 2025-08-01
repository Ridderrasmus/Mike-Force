/*
    File: fn_crate_load.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Loads saved crate data and creates a new crate.
        Uses the new event-based tracking system.

    Parameter(s):
        _crateData - The data to load [ARRAY]

    Returns: 
        _crate - The created crate object [OBJECT]

    Example(s):
        [_savedCrateData] call vn_mf_fnc_crate_load;
*/

params ["_crateData"];

if (count _crateData == 0) exitWith { objNull };

_crateData params ["_class", "_loc", "_data", ["_customVars", []]];

// Create the crate at the saved position
private _crate = createVehicle [_class, (_loc select 0), [], 0, "CAN_COLLIDE"];

if (isNull _crate) exitWith {
    diag_log format ["VN MikeForce: Failed to create crate of class %1", _class];
    objNull
};

// Set position and direction
_crate setPosWorld (_loc select 0);
_crate setVectorDirAndUp (_loc select 1);

// Load saved damage
_crate setDamage (_data select 0);

// Load saved inventory
private _inv = (_data select 1);
[_crate, _inv] call vn_mf_fnc_inv_set_data;

// Restore custom variables
{
    _x params ["_varName", "_varValue"];
    _crate setVariable [_varName, _varValue, true];
} forEach _customVars;

// Mark as loaded to prevent duplicate loading
_crate setVariable ["rid_loaded", true, true];

// Add to tracked crates list
private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
if !(_crate in _trackedCrates) then {
    _trackedCrates pushBack _crate;
    missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
    
    // Add event handlers
    _crate addEventHandler ["Killed", {
        params ["_crate"];
        private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
        _trackedCrates = _trackedCrates - [_crate];
        missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
    }];
    
    _crate addEventHandler ["Deleted", {
        params ["_crate"];
        private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
        _trackedCrates = _trackedCrates - [_crate];
        missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];
    }];
};

diag_log format ["VN MikeForce: Loaded crate %1 at position %2", _class, _loc select 0];

_crate
