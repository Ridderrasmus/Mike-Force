/*
    File: fn_veh_get_data.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Gathers information about the given vehicle and returns it.
        Uses the new event-based tracking system.

    Parameter(s):
        _veh - The vehicle to collect information about [OBJ]

    Returns: 
        [ARRAY] - Array containing the following information:
            [0] - Vehicle class
            [1] - Array containing position and direction of vehicle
                [0] - Position [Array]
                [1] - Vector dir and up [Array]
            [2] - Array containing health, fuel, turret magazines, and inventory of vehicle
                [0] - Health [Number]
                [1] - Fuel [Number]
                [2] - Turret magazines [Array]
                [3] - Array containing cargo inventory of vehicle [Array]
            [3] - Array containing cargo fuel and ammo of vehicle
                [0] - Cargo fuel [Number]
                [1] - Cargo ammo [Number]
            [4] - Whether vehicle is a packaged wreck or not [Bool]
            [5] - Custom vehicle variables for restoration [Array]

    Example(s):
        [someVehicle] call vn_mf_fnc_veh_get_data;
*/

params ["_veh"];

if (isNull _veh || !alive _veh) exitWith { [] };

// Get weapons and magazine data
private _weaponsData = [(magazinesAmmo [_veh, true])];

// Get inventory data
private _vehInventory = [_veh] call vn_mf_fnc_inv_get_data;

// Basic vehicle info
private _class = typeOf _veh;
private _loc = [getPosWorld _veh, [VectorDir _veh, vectorUp _veh]];
private _data = [damage _veh, fuel _veh, _weaponsData, _vehInventory];
private _dataCargo = [getFuelCargo _veh, getAmmoCargo _veh];
private _packaged = ((_class splitString "-") select 0 == "vn_us_komex_medium_01");

// Store important custom variables that should be restored
private _customVars = [];
private _varsToSave = [
    "vehAssetId",
    "veh_asset_spawnpointid", 
    "supply_drop_config",
    "rid_loaded"
];

{
    private _varName = _x;
    private _varValue = _veh getVariable [_varName, nil];
    if (!isNil "_varValue") then {
        _customVars pushBack [_varName, _varValue];
    };
} forEach _varsToSave;

private _vehData = [_class, _loc, _data, _dataCargo, _packaged, _customVars];
_vehData
