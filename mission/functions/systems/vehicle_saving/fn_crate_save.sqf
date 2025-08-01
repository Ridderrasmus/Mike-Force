/*
    File: fn_crate_save.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Gathers information about the given crate and returns it.
        Uses the new event-based tracking system.

    Parameter(s):
        _crate - The crate to collect information about [OBJECT]

    Returns: 
        [ARRAY] - Array containing the following information:
            [0] - Crate class [STRING]
            [1] - Position and direction [ARRAY]
                [0] - Position [ARRAY]
                [1] - Vector dir and up [ARRAY]
            [2] - Crate data [ARRAY]
                [0] - Health [NUMBER]
                [1] - Inventory data [ARRAY]
            [3] - Custom variables [ARRAY]

    Example(s):
        [someCrate] call vn_mf_fnc_crate_save;
*/

params ["_crate"];

if (isNull _crate || !alive _crate) exitWith { [] };

// Basic crate info
private _class = typeOf _crate;
private _loc = [getPosWorld _crate, [VectorDir _crate, vectorUp _crate]];

// Get inventory data
private _crateInventory = [_crate] call vn_mf_fnc_inv_get_data;
private _data = [damage _crate, _crateInventory];

// Store important custom variables that should be restored
private _customVars = [];
private _varsToSave = [
    "supply_drop_config",
    "rid_loaded"
];

{
    private _varName = _x;
    private _varValue = _crate getVariable [_varName, nil];
    if (!isNil "_varValue") then {
        _customVars pushBack [_varName, _varValue];
    };
} forEach _varsToSave;

private _crateData = [_class, _loc, _data, _customVars];
_crateData
