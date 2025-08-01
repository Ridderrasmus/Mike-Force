/*
    File: fn_add_crate_to_tracking.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Manually adds a crate to the tracking system.
        Useful for crates that might not be caught by the automatic event system.

    Parameter(s):
        _crate - The crate to add to tracking [OBJECT]

    Returns: 
        _success - Whether the crate was successfully added [BOOL]

    Example(s):
        [myCrate] call vn_mf_fnc_add_crate_to_tracking;
*/

params ["_crate"];

if (isNull _crate || !alive _crate) exitWith { false };

private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];

// Check if already tracked
if (_crate in _trackedCrates) exitWith { true };

// Add to tracking
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

diag_log format ["VN MikeForce: Manually added crate %1 to tracking", typeOf _crate];

true
