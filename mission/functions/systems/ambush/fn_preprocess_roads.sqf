/*
	File: fn_preprocess_roads.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Preprocesses the road network for ambush points.
		Analyzes the road network and identifies potential ambush points based on foliage and cover.
		It will then store these points in a missionNamespace variable hashmap that maps roads in a "roadType_roadStart_roadEnd" format to an array of ambush points for quick access later.

	Parameter(s):
		None

	Returns:
		None

	Example(s):
		// Preprocess the roads for ambush points
		[] call vn_mf_fnc_preprocess_roads;
*/

// Only run on server
if (!isServer) exitWith {};

diag_log "SP MikeForce: Starting road network preprocessing for ambush points";

// Initialize the global hashmaps
private _ambushRoadMap = createHashMap;
private _roadUsageMap = createHashMap;

// Set up the hashmaps in missionNamespace immediately so other systems can reference them
missionNamespace setVariable ["vn_mf_ambush_road_map", _ambushRoadMap, true];
missionNamespace setVariable ["vn_mf_road_usage", _roadUsageMap, true];

// Spawn the road analysis process to run asynchronously
[] spawn {
	// Get all roads on the map using nearRoads from the center of the map
	private _worldSize = worldSize;
	private _center = [_worldSize / 2, _worldSize / 2, 0];
	private _allRoads = _center nearRoads (_worldSize / 2);

	diag_log format ["SP MikeForce: Found %1 roads to analyze", count _allRoads];

	private _processedRoads = 0;
	private _eligibleRoads = 0;
	private _batchSize = 25; // Process roads in batches to prevent server lag
	
	// Get reference to our hashmaps
	private _ambushRoadMap = missionNamespace getVariable ["vn_mf_ambush_road_map", createHashMap];

	// Process roads in batches
	for "_batchStart" from 0 to (count _allRoads - 1) step _batchSize do {
		private _batchEnd = (_batchStart + _batchSize - 1) min (count _allRoads - 1);
		
		// Process this batch of roads
		for "_i" from _batchStart to _batchEnd do {
			private _road = _allRoads select _i;
			
			// Skip if road is null
			if (isNull _road) then {continue};
			
			// Get road information
			private _roadInfo = getRoadInfo _road;
			if (_roadInfo isEqualTo []) then {continue};
			
			// Extract road segment information
			_roadInfo params ["_roadType", "_roadWidth", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];
			
			
			// Check if this road segment has eligible ambush points
			private _ambushPoints = [_road] call vn_mf_fnc_check_ambush_eligibility;
			
			// If we found eligible points, store them in the hashmap
			if (count _ambushPoints > 0) then {
				// Create unique road key: "roadType_startX_startY_endX_endY"
				private _roadKey = format ["%1_%2_%3_%4_%5", 
					_roadType,
					round (_begPos select 0),
					round (_begPos select 1), 
					round (_endPos select 0),
					round (_endPos select 1)
				];
				
				// Store the ambush points for this road segment
				_ambushRoadMap set [_roadKey, _ambushPoints];
				_eligibleRoads = _eligibleRoads + 1;
				
				diag_log format ["SP MikeForce: Road %1 (%2) has %3 eligible ambush points", _roadKey, _roadType, count _ambushPoints];
			};
			
			_processedRoads = _processedRoads + 1;
		};
		
		// Update the global hashmap after each batch
		missionNamespace setVariable ["vn_mf_ambush_road_map", _ambushRoadMap, true];
		
		// Log progress
		diag_log format ["SP MikeForce: Processed batch %1-%2, total progress: %3/%4 roads (%5 eligible so far)", 
			_batchStart, _batchEnd, _processedRoads, count _allRoads, _eligibleRoads];
		
		// Small delay between batches to prevent server hitching
		uiSleep 0.05;
	};

	// Final update and summary
	missionNamespace setVariable ["vn_mf_ambush_road_map", _ambushRoadMap, true];
	
	private _totalAmbushPoints = 0;
	{
		_totalAmbushPoints = _totalAmbushPoints + count _x;
	} forEach (values _ambushRoadMap);
	
	diag_log format ["SP MikeForce: Road preprocessing complete. Processed %1 roads, found %2 roads with ambush potential containing %3 total ambush points", 
		_processedRoads, 
		_eligibleRoads, 
		_totalAmbushPoints
	];

	// Log some example road keys for debugging
	private _sampleKeys = (keys _ambushRoadMap) select [0, (count (keys _ambushRoadMap)) min 5];
	if (count _sampleKeys > 0) then {
		diag_log format ["SP MikeForce: Sample road keys: %1", _sampleKeys];
	};
	
	// Set a flag to indicate preprocessing is complete
	missionNamespace setVariable ["vn_mf_ambush_road_preprocessing_complete", true, true];
	
	diag_log "SP MikeForce: Road network preprocessing completed successfully";
};