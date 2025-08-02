/*
	File: fn_get_road_ambush_points.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Retrieves ambush points for a given road key from the preprocessed road network data.
		Returns an empty array if the road has no ambush points or if preprocessing is not complete.

	Parameter(s):
		_roadKey - The road key in format "roadType_startX_startY_endX_endY" [STRING]

	Returns:
		Array of ambush points for the specified road [ARRAY of POSITIONS]

	Example(s):
		// Get ambush points for a specific road
		_ambushPoints = ["MAIN_1234_5678_1300_5700"] call vn_mf_fnc_get_road_ambush_points;
		
		// Check if any ambush points exist
		if (count _ambushPoints > 0) then {
			// Use the ambush points for setting up an ambush
		};
*/

params ["_roadKey"];

// Check if road preprocessing is complete
if (isNil {missionNamespace getVariable "vn_mf_ambush_road_preprocessing_complete"}) then {
	diag_log "SP MikeForce: Warning - Road ambush points requested before preprocessing is complete";
	[]
} else {
	// Get the road map and return points for the specified road
	private _ambushRoadMap = missionNamespace getVariable ["vn_mf_ambush_road_map", createHashMap];
	_ambushRoadMap getOrDefault [_roadKey, []]
};
