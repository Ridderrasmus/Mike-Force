/*
	File: fn_road_usage_ticker.sqf
	Author: Ridderrasmus
	Public: Yes

	Description:
		Ticks the road usage for a player, updating their road usage statistics.
		This function is called periodically to track which roads a player is using.
		Vehicles increment usage by 2, infantry by 1. Only roads with ambush potential are tracked.

	Parameter(s):
		_player - Player being ticked [OBJECT]

	Returns:
		None

	Example(s):
		// Called from a scheduler job
		[player] call vn_mf_fnc_road_usage_ticker;
*/

params ["_player"];

// Only track alive players
if (!alive _player) exitWith {};

// Get player position and check if they're near any roads
private _playerPos = getPosATL _player;
private _nearbyRoads = _playerPos nearRoads 100; // Check within 100m radius

// If player in friendly zone, skip road usage tracking
if (_player call vn_mf_fnc_area_check) exitWith {};

// If no roads nearby, nothing to track
if (count _nearbyRoads == 0) exitWith {};

// Get the road usage map from missionNamespace
private _roadUsageMap = missionNamespace getVariable ["vn_mf_road_usage", createHashMap];

// Get player's road tracking cooldowns (local to prevent network spam)
private _playerRoadCooldowns = _player getVariable ["vn_mf_road_cooldowns", createHashMap];
private _currentTime = time;

// Determine usage increment based on player's vehicle status
private _usageIncrement = 1; // Default for infantry
private _vehicle = vehicle _player;
if (_vehicle != _player) then {
	// Player is in a vehicle, increment by 2
	_usageIncrement = 2;
};

// Collect all road usage updates for this tick in a local array
private _usageUpdates = [];

// Process each nearby road
{
	private _road = _x;
	
	// Create road key for ALL roads (not just ambush-capable ones)
	private _roadKey = [_road] call vn_mf_fnc_create_road_key;
	
	// Skip if we couldn't create a valid road key
	if (_roadKey == "") then {continue};
	
	// Check if this road is on cooldown for this player
	private _lastTrackedTime = _playerRoadCooldowns getOrDefault [_roadKey, 0];
	private _cooldownRemaining = (_lastTrackedTime + 5) - _currentTime; // 5 second cooldown
	
	// Only track if cooldown has expired
	if (_cooldownRemaining <= 0) then {
		// Store the update for later processing
		_usageUpdates pushBack [_roadKey, _usageIncrement];
		
		// Update the cooldown for this road
		_playerRoadCooldowns set [_roadKey, _currentTime];
		
		// Debug logging (remove in production)
		// diag_log format ["SP MikeForce: Player %1 used road %2, increment: %3", name _player, _roadKey, _usageIncrement];
	};
	
} forEach _nearbyRoads;

// Store updated cooldowns back on player
_player setVariable ["vn_mf_road_cooldowns", _playerRoadCooldowns];

// Send all usage updates to server for atomic processing
if (count _usageUpdates > 0) then {
	[_usageUpdates] remoteExec ["vn_mf_fnc_process_road_usage_updates", 2];
};

