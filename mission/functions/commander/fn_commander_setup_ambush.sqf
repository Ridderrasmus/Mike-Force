/*
	File: fn_commander_setup_ambush.sqf
	Author: Ridderrasmus
	Public: No

	Description:
		Sets up the actual ambush by:
		- Spawning two tactical squads (suppression + assault)
		- Placing command-detonated mine on road
		- Positioning units in concealment on both sides of road
		- Setting strict ROE (no engagement until triggered)

	Parameter(s):
		_ambushData - Ambush data namespace [OBJECT]

	Returns:
		None

	Example(s):
		[_ambushData] call vn_mf_fnc_commander_setup_ambush;
*/

params ["_ambushData"];

private _ambushPos = _ambushData get "ambushPos";
private _zone = _ambushData get "zone";

// Step 1: Find the exact road center and place mine there
private _nearestRoad = [_ambushPos, 50] call BIS_fnc_nearestRoad;
private _minePos = _ambushPos;

if (!isNull _nearestRoad) then {
	// Get road info to find the actual road segment
	private _roadInfo = getRoadInfo _nearestRoad;
	_roadInfo params ["_roadType", "_roadWidth", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];
	if (count _roadInfo >= 2) then {
		// Find the closest point on the road segment to our ambush position
		private _roadStart = _begPos;
		private _roadEnd = _endPos;
		private _roadVector = _roadEnd vectorDiff _roadStart;
		private _roadLength = _roadStart distance _roadEnd;
		
		if (_roadLength > 0) then {
			// Project ambush position onto the road segment
			private _toAmbush = _ambushPos vectorDiff _roadStart;
			private _projection = (_toAmbush vectorDotProduct _roadVector) / (_roadVector vectorDotProduct _roadVector);
			_projection = _projection max 0 min 1; // Clamp to road segment
			
			// Calculate the point on the road closest to ambush position
			_minePos = _roadStart vectorAdd (_roadVector vectorMultiply _projection);
			_minePos set [2, getTerrainHeightASL _minePos];
			_minePos = ASLToAGL _minePos; // Ensure mine is placed at ground level
		} else {
			_minePos = _roadStart;
		};
	} else {
		// Fallback: use road object position
		_minePos = getPos _nearestRoad;
	};
} else {
	systemChat format ["SP Mikeforce - Warning: No road found near ambush position %1", _ambushPos];
};

// Step 2: Spawn two tactical squads using Paradigm functions
private _squadSize = 4; // Squad size per side

// Get actual road direction from road data if available
private _roadDir = random 360; // Default fallback
if (!isNull _nearestRoad) then {
	private _roadInfo = getRoadInfo _nearestRoad;
	_roadInfo params ["_roadType", "_roadWidth", "_isPedestrian", "_texture", "_textureEnd", "_material", "_begPos", "_endPos", "_isBridge"];
	if (count _roadInfo >= 2) then {
		private _roadStart = _begPos;
		private _roadEnd = _endPos;
		_roadDir = _roadStart getDir _roadEnd;
	};
};

// Calculate positions for each squad on opposite sides of the road
private _suppressionPos = _minePos getPos [80, _roadDir + 90]; // Left side of road
private _assaultPos = _minePos getPos [80, _roadDir - 90]; // Right side of road

systemChat format ["SP Mikeforce - Spawning suppression squad at %1 and assault squad at %2", _suppressionPos, _assaultPos];

// Squad 1: Suppression squad (uses PATROL composition for LMGs)
private _suppressionComposition = ["PATROL", east, _squadSize, _suppressionPos] call para_g_fnc_spawning_get_squad_composition;
private _suppressionResult = [_suppressionComposition, east, _suppressionPos] call para_g_fnc_create_squad;
_suppressionResult params ["_suppressionUnits", "_suppressionGroup"];

// Squad 2: Assault squad (uses STANDARD composition for balanced firepower)
private _assaultComposition = ["STANDARD", east, _squadSize, _assaultPos] call para_g_fnc_spawning_get_squad_composition;
private _assaultResult = [_assaultComposition, east, _assaultPos] call para_g_fnc_create_squad;
_assaultResult params ["_assaultUnits", "_assaultGroup"];

// Set group IDs for identification
_suppressionGroup setGroupIdGlobal [format ["Ambush_Suppress_%1_%2", _zone, floor (random 1000)]];
_assaultGroup setGroupIdGlobal [format ["Ambush_Assault_%1_%2", _zone, floor (random 1000)]];

// Store squads in ambush data
_ambushData set ["suppressionGroup", _suppressionGroup];
_ambushData set ["assaultGroup", _assaultGroup];

// Step 3: Place mine at road center with trigger detection
private _mine = createMine ["vn_mine_m15", _minePos, [], 0];
_mine setDamage 0; // Ensure it's not damaged on creation
_ambushData set ["mine", _mine];
_ambushData set ["minePos", _minePos];

// Create trigger for mine detection
private _trigger = createTrigger ["EmptyDetector", _minePos];
_trigger setTriggerArea [15, 15, 0, false]; // 15m radius detection
_trigger setTriggerActivation ["WEST", "PRESENT", true];
_trigger setTriggerStatements [
	"this", 
	format ["[%1] call vn_mf_fnc_commander_trigger_ambush;", _ambushData],
	""
];
_ambushData set ["trigger", _trigger];

systemChat format ["SP Mikeforce - Placed mine with trigger at road center %1", _minePos];

// Step 4: Position both squads in concealment
private _allUnits = _suppressionUnits + _assaultUnits;

// Position suppression squad on left side of road
{
	private _distance = 40 + (random 30); // 40-70m from road for concealment
	private _angle = (_roadDir + 90) + (random 40 - 20); // Left side with spread
	private _basePos = _minePos getPos [_distance, _angle];
	
	// Find concealment position
	private _coverPos = [_basePos, 0, 25, 3, 0, 30, 0, ["Tree", "Bush", "Rock", "Wall", "House"]] call BIS_fnc_findSafePos;
	if (_coverPos isEqualTo []) then { _coverPos = _basePos; };
	
	// Move unit to concealed position
	_x setPos _coverPos;
	_x setDir (random 360);
	
	// Set concealment behavior
	_x setBehaviour "STEALTH";
	_x setCombatMode "BLUE"; // Hold fire until triggered
	_x setSkill ["spotDistance", 0.9]; // Good spotting
	_x setSkill ["courage", 0.9]; // High courage for suppression role
	_x setCaptive true; // Make them harder to detect initially
	
	// Add FiredNear event handler to trigger ambush
	_x addEventHandler ["FiredNear", {
		params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];
		if (_distance < 150) then {
			// Get ambush data from unit's variable
			private _ambushData = _unit getVariable ["ambushData", createHashMap];
			if (!(_ambushData isEqualTo createHashMap)) then {
				// Trigger the ambush
				[_ambushData] call vn_mf_fnc_commander_trigger_ambush;
			};
		};
	}];
	
	// Store reference to ambush data in the unit
	_x setVariable ["ambushData", _ambushData];
	
} forEach _suppressionUnits;

// Position assault squad on right side of road  
{
	private _distance = 40 + (random 30); // 40-70m from road for concealment
	private _angle = (_roadDir - 90) + (random 40 - 20); // Right side with spread
	private _basePos = _minePos getPos [_distance, _angle];
	
	// Find concealment position
	private _coverPos = [_basePos, 0, 25, 3, 0, 30, 0, ["Tree", "Bush", "Rock", "Wall", "House"]] call BIS_fnc_findSafePos;
	if (_coverPos isEqualTo []) then { _coverPos = _basePos; };
	
	// Move unit to concealed position
	_x setPos _coverPos;
	_x setDir (random 360);
	
	// Set concealment behavior
	_x setBehaviour "STEALTH";
	_x setCombatMode "BLUE"; // Hold fire until triggered
	_x setSkill ["spotDistance", 0.8]; // Good spotting
	_x setSkill ["courage", 0.8]; // Standard courage for assault role
	_x setCaptive true; // Make them harder to detect initially
	
	// Add FiredNear event handler to trigger ambush
	_x addEventHandler ["FiredNear", {
		params ["_unit", "_firer", "_distance", "_weapon", "_muzzle", "_mode", "_ammo", "_gunner"];
		if (_distance < 150) then {
			// Get ambush data from unit's variable
			private _ambushData = _unit getVariable ["ambushData", createHashMap];
			if (!(_ambushData isEqualTo createHashMap)) then {
				// Trigger the ambush
				[_ambushData] call vn_mf_fnc_commander_trigger_ambush;
			};
		};
	}];
	
	// Store reference to ambush data in the unit
	_x setVariable ["ambushData", _ambushData];
	
} forEach _assaultUnits;

systemChat format ["SP Mikeforce - Positioned %1 suppression units and %2 assault units in concealment", 
	count _suppressionUnits, count _assaultUnits];

// Update ambush data
_ambushData set ["ambushUnits", _allUnits];
_ambushData set ["setupTime", serverTime];

systemChat format ["SP Mikeforce - Dual-squad ambush fully deployed and ready"];
