/*
    File: fn_remove_crate_from_tracking.sqf
    Author: Ridderrasmus
    Public: No

    Description:
        Manually removes a crate from the tracking system.
        Useful for temporary crates that shouldn't be saved.

    Parameter(s):
        _crate - The crate to remove from tracking [OBJECT]

    Returns: 
        _success - Whether the crate was successfully removed [BOOL]

    Example(s):
        [myTempCrate] call vn_mf_fnc_remove_crate_from_tracking;
*/

params ["_crate"];

private _trackedCrates = missionNamespace getVariable ["vn_mf_tracked_crates", []];

// Check if tracked
if !(_crate in _trackedCrates) exitWith { false };

// Remove from tracking
_trackedCrates = _trackedCrates - [_crate];
missionNamespace setVariable ["vn_mf_tracked_crates", _trackedCrates, true];

// Mark as temporary to prevent re-adding
_crate setVariable ["vn_mf_temp_crate", true, true];

diag_log format ["VN MikeForce: Removed crate %1 from tracking", typeOf _crate];

true
