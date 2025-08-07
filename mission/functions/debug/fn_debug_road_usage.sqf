/*
	File: fn_debug_road_usage.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Debug command for visualizing road usage data with markers.
		Toggles display of road usage markers showing current usage scores.
		Markers are updated in real-time when enabled.

	Parameter(s):
		_action - Action to perform: "toggle", "on", "off", "status" [STRING]

	Returns:
		None

	Example(s):
		["toggle"] call vn_mf_fnc_debug_road_usage;
		["on"] call vn_mf_fnc_debug_road_usage;
		["off"] call vn_mf_fnc_debug_road_usage;
		["status"] call vn_mf_fnc_debug_road_usage;
*/

// Only run on server
if (!isServer) exitWith {
	systemChat "SP Mikeforce - Error: Road usage debug only works on server";
};

params [["_action", "toggle", [""]]];

private _debugActive = missionNamespace getVariable ["vn_mf_debug_road_usage_active", false];
private _debugMarkers = missionNamespace getVariable ["vn_mf_debug_road_usage_markers", createHashMap];

switch (toLower _action) do {
	case "toggle": {
		if (_debugActive) then {
			["off"] call vn_mf_fnc_debug_road_usage;
		} else {
			["on"] call vn_mf_fnc_debug_road_usage;
		};
	};
	
	case "on": {
		if (_debugActive) exitWith {
			systemChat "SP Mikeforce - Road usage debug already active";
		};
		
		systemChat "SP Mikeforce - Enabling road usage debug markers";
		missionNamespace setVariable ["vn_mf_debug_road_usage_active", true];
		
		// Check if we have any road usage data
		private _roadUsageData = missionNamespace getVariable ["vn_mf_road_usage", createHashMap];
		
		// Start the marker update scheduler
		["debug_road_usage_markers", {
			private _roadUsageData = missionNamespace getVariable ["vn_mf_road_usage", createHashMap];
			private _debugMarkers = missionNamespace getVariable ["vn_mf_debug_road_usage_markers", createHashMap];
			private _debugActive = missionNamespace getVariable ["vn_mf_debug_road_usage_active", false];
			
			// Exit if debug was turned off
			if (!_debugActive) exitWith {
				["debug_road_usage_markers"] call para_g_fnc_scheduler_remove_job;
			};
			
			
			// Track which markers we've updated this cycle
			private _updatedMarkers = createHashMap;
			
			// Update/create markers for current road usage data
			{
				private _roadKey = _x;
				private _usageScore = _y;
				
				// Parse road key format: "roadType_startX_startY_endX_endY"
				private _keyParts = _roadKey splitString "_";
				if (count _keyParts >= 5) then {
					// Calculate center position from start and end coordinates
					private _startX = parseNumber (_keyParts select 1);
					private _startY = parseNumber (_keyParts select 2);
					private _endX = parseNumber (_keyParts select 3);
					private _endY = parseNumber (_keyParts select 4);
					
					private _centerX = (_startX + _endX) / 2;
					private _centerY = (_startY + _endY) / 2;
					private _markerPos = [_centerX, _centerY, 0];
					
					private _markerName = format ["debug_road_usage_%1", _roadKey];
					
					// Check if marker already exists
					private _existingMarker = _debugMarkers getOrDefault [_roadKey, ""];
					
					if (_existingMarker != "" && {getMarkerType _existingMarker != ""}) then {
						// Update existing marker
						_existingMarker setMarkerText format ["%1", _usageScore];
						_existingMarker setMarkerColor (if (_usageScore >= 5) then {"ColorRed"} else {if (_usageScore >= 2) then {"ColorOrange"} else {"ColorYellow"}});
					} else {
						// Create new marker
						private _marker = createMarker [_markerName, _markerPos];
						_marker setMarkerType "mil_circle";
						_marker setMarkerSize [0.3, 0.3];
						_marker setMarkerText format ["%1", _usageScore];
						_marker setMarkerColor (if (_usageScore >= 5) then {"ColorRed"} else {if (_usageScore >= 2) then {"ColorOrange"} else {"ColorYellow"}});
						
						_debugMarkers set [_roadKey, _marker];
						
						// Debug: Log marker creation
					};
					
					_updatedMarkers set [_roadKey, true];
				} else {
					// Debug: Log parsing failures
				};
			} forEach _roadUsageData;
			
			// Remove markers for roads that no longer exist in usage data
			private _markersToRemove = [];
			{
				private _roadKey = _x;
				private _marker = _y;
				
				if (!(_updatedMarkers getOrDefault [_roadKey, false])) then {
					deleteMarker _marker;
					_markersToRemove pushBack _roadKey;
				};
			} forEach _debugMarkers;
			
			// Clean up removed markers from tracking
			{
				_debugMarkers deleteAt _x;
			} forEach _markersToRemove;
			
			// Update global marker tracking
			missionNamespace setVariable ["vn_mf_debug_road_usage_markers", _debugMarkers];
			
		}, [], 5] call para_g_fnc_scheduler_add_job; // Update every 5 seconds
		
		systemChat "SP Mikeforce - Road usage debug markers enabled (updating every 5 seconds)";
	};
	
	case "off": {
		if (!_debugActive) exitWith {
			systemChat "SP Mikeforce - Road usage debug already inactive";
		};
		
		systemChat "SP Mikeforce - Disabling road usage debug markers";
		missionNamespace setVariable ["vn_mf_debug_road_usage_active", false];
		
		// Remove the scheduler job
		["debug_road_usage_markers"] call para_g_fnc_scheduler_remove_job;
		
		// Delete all debug markers
		{
			deleteMarker _y;
		} forEach _debugMarkers;
		
		// Clear marker tracking
		missionNamespace setVariable ["vn_mf_debug_road_usage_markers", createHashMap];
	};
	
	case "status": {
		private _markerCount = count _debugMarkers;
		private _roadCount = count (missionNamespace getVariable ["vn_mf_road_usage", createHashMap]);
		
		systemChat format ["SP Mikeforce - Road Usage Debug Status: %1", if (_debugActive) then {"ACTIVE"} else {"INACTIVE"}];
		systemChat format ["Debug Markers: %1 | Tracked Roads: %2", _markerCount, _roadCount];
		
		if (_debugActive) then {
			systemChat "Marker Colors: Red (≥5.0) | Orange (≥2.0) | Yellow (<2.0)";
			systemChat """[""off""] call vn_mf_fnc_debug_road_usage"""; // To disable""";
		} else {
			systemChat """[""on""] call vn_mf_fnc_debug_road_usage"""; // To enable""";
		};
	};
	
	default {
		systemChat "SP Mikeforce - Road Usage Debug Commands:";
		systemChat """[""toggle""] call vn_mf_fnc_debug_road_usage"""; // Toggle on/off""";
		systemChat """[""on""] call vn_mf_fnc_debug_road_usage"""; // Enable markers""";
		systemChat """[""off""] call vn_mf_fnc_debug_road_usage"""; // Disable markers""";
		systemChat """[""status""] call vn_mf_fnc_debug_road_usage"""; // Show status""";
	};
};
