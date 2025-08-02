/*
	File: fn_check_ambush_eligibility.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Checks if a road has any points that are eligible for ambushes.
		This function is used to generate points along the road network that can be used for ambushes.
		Any point with some kind of foliage or cover on both sides of the road which is slightly apart from each other is considered eligible.

	Parameter(s):
		_road - Road to check [OBJECT]

	Returns:
		Array of points that are eligible for ambushes along the road [ARRAY of POINTS]

	Example(s):
		// Check if a road has any ambush points
		_road = objNull; // Replace with actual road object
		eligibleAmbushPoints = [_road] call vn_mf_fnc_check_ambush_eligibility;
*/

params ["_road"];

// Debug output - comment out for production use
// systemChat format ["Checking ambush eligibility for road: %1", _road];

// Return empty array if road is null
if (isNull _road) exitWith {[]};

private _eligiblePoints = [];
private _roadPos = getPos _road;

// Get road information including length and direction
private _roadInfo = getRoadInfo _road;
if (_roadInfo isEqualTo []) exitWith {[]};

// Extract road segment information
_roadInfo params ["_roadType", "_roadWidth", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];

// Only consider main roads and secondary roads (not paths)
//if (_roadType in ["TRACK", "TRAIL"]) exitWith {[]};

// Calculate road length and direction from begin and end positions
private _roadLength = _begPos distance2D _endPos;
private _roadDirection = _begPos getDir _endPos;

// Generate points along the actual road segment
private _pointSpacing = 10; // Check every 10 meters
private _numberOfPoints = ceil (_roadLength / _pointSpacing);

// Debug output - comment out for production use
// systemChat format ["Checking ambush eligibility for road: %1, length: %2, points: %3", _roadType, _roadLength, _numberOfPoints];

for "_i" from 0 to _numberOfPoints do {
	private _distance = _i * _pointSpacing - (_roadLength / 2);
	private _checkPoint = _roadPos getPos [_distance, _roadDirection];
	
	// Skip if point is in water
	if (surfaceIsWater _checkPoint) then {continue};
	
	// Check for foliage/cover on both sides of the road
	private _leftSide = _checkPoint getPos [25, _roadDirection - 90]; // 25m to the left
	private _rightSide = _checkPoint getPos [25, _roadDirection + 90]; // 25m to the right
	
	// Check for terrain objects (trees, bushes) on both sides - smaller radius for denser coverage
	private _leftCover = nearestTerrainObjects [_leftSide, ["TREE", "BUSH", "SMALL TREE"], 15, false, true];
	private _rightCover = nearestTerrainObjects [_rightSide, ["TREE", "BUSH", "SMALL TREE"], 15, false, true];
	
	// Point is eligible if there's dense cover on both sides (jungle environment)
	if (count _leftCover >= 8 && count _rightCover >= 8) then {
		// Additional check: ensure the covers are sufficiently apart and dense
		private _leftCoverPos = getPos (_leftCover select 0);
		private _rightCoverPos = getPos (_rightCover select 0);
		private _coverDistance = _leftCoverPos distance2D _rightCoverPos;
		
		// Also check for additional dense vegetation in a smaller area around each position
		private _leftDenseCover = nearestTerrainObjects [_leftSide, ["TREE", "BUSH", "SMALL TREE"], 8, false, true];
		private _rightDenseCover = nearestTerrainObjects [_rightSide, ["TREE", "BUSH", "SMALL TREE"], 8, false, true];
		
		// Require dense jungle coverage: at least 35m separation and very dense vegetation
		if (_coverDistance >= 35 && count _leftDenseCover >= 5 && count _rightDenseCover >= 5) then {
			_eligiblePoints pushBack _checkPoint;
		};
	};
};

// Debug markers - comment out for production use to avoid map clutter
/*
{
	_markerName = format ["ambush_%1", _x];
	createMarker [_markerName, _x];
	_markerName setMarkerColor "ColorGreen";
	_markerName setMarkerType "mil_dot";
	_markerName setMarkerSize [0.5, 0.5];
} forEach _eligiblePoints;
*/

_eligiblePoints