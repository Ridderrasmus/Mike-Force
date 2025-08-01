# Vehicle Saving System

## Overview

The Vehicle Saving System is an event-based persistence system that automatically tracks and saves player faction vehicles and supply crates in Mike Force missions. The system ensures that vehicles spawned by players persist across server restarts and mission reloads.

## Key Features

- **Event-Based Tracking**: Automatically detects and tracks vehicles when they're created
- **Faction Filtering**: Only saves friendly faction vehicles (prevents enemy vehicle pollution)
- **Automatic Persistence**: Vehicles maintain position, damage, fuel, inventory, and custom variables
- **Supply Crate Support**: Tracks and saves supply drop crates
- **Area Restrictions**: Respects zone-based save restrictions
- **Background Processing**: Automatic cleanup and maintenance

## Architecture

### Core Components

1. **Event Detection**: Integrates with Paradigm's event system to detect `vehicleCreated` events
2. **Tracking Arrays**: Maintains global arrays of tracked vehicles and crates
3. **Faction Filtering**: Uses vehicle respawn configuration to determine save eligibility
4. **Persistence Engine**: Handles save/load operations with full state preservation

### Data Flow

```
Vehicle Created → Event Fired → Faction Check → Add to Tracking → Auto-Save → Persistence
```

## System Functions

### Initialization
- `vn_mf_fnc_start_save_loop` - Initializes the complete system
- `vn_mf_fnc_init_event_tracking` - Sets up event-based vehicle detection

### Core Operations
- `vn_mf_fnc_full_save` - Saves all tracked vehicles and crates
- `vn_mf_fnc_full_load` - Loads and recreates saved objects
- `vn_mf_fnc_veh_get_data` - Extracts vehicle state data
- `vn_mf_fnc_veh_load` - Creates vehicles from saved data
- `vn_mf_fnc_crate_save` - Extracts crate state data  
- `vn_mf_fnc_crate_load` - Creates crates from saved data

### Management Functions
- `vn_mf_fnc_add_vehicle_to_tracking` - Manually add vehicle to tracking
- `vn_mf_fnc_remove_vehicle_from_tracking` - Remove vehicle from tracking
- `vn_mf_fnc_add_crate_to_tracking` - Manually add crate to tracking
- `vn_mf_fnc_remove_crate_from_tracking` - Remove crate from tracking
- `vn_mf_fnc_cleanup_tracked_vehicles` - Clean up non-friendly vehicles
- `vn_mf_fnc_is_friendly_vehicle` - Check if vehicle belongs to player faction

### Utility Functions
- `vn_mf_fnc_area_check` - Check if object is in restricted area
- `vn_mf_fnc_inv_get_data` / `vn_mf_fnc_inv_set_data` - Inventory serialization
- `vn_mf_fnc_add_save_load_actions` - Add manual save/load actions to objects

## Configuration

### Server Parameters
The system uses the `saving_autosave_timer` server parameter to determine save intervals:
- `0` - Autosave disabled (manual saves only)
- `> 0` - Minutes between automatic saves

### Faction Filtering
Vehicles are considered "friendly" if they meet any of these criteria:

1. **Configuration Check**: Defined in `vehicle_respawn_info.hpp`
2. **Prefix Check**: Class name starts with `vn_b_`, `vn_c_`, or `vnx_b_`  
3. **Faction Check**: Vehicle faction is `BLU_F` or `CIV_F`

### Global Variables
- `vn_mf_tracked_vehicles` - Array of tracked vehicle objects
- `vn_mf_tracked_crates` - Array of tracked crate objects
- `vn_mf_crate_types` - Array of valid supply crate class names

### Exclusion Markers
Objects can be excluded from tracking by setting:
- `vn_mf_temp_vehicle = true` - Exclude vehicles
- `vn_mf_temp_crate = true` - Exclude crates

## Saved Data Structure

### Vehicle Data Format
```sqf
[
    _class,          // [0] Vehicle class name
    _location,       // [1] [position, vectorDirAndUp]
    _vehicleData,    // [2] [damage, fuel, magazines, inventory]
    _cargoData,      // [3] [fuelCargo, ammoCargo]
    _isPackaged,     // [4] Whether vehicle is packaged wreck
    _customVars      // [5] Array of [varName, varValue] pairs
]
```

### Crate Data Format
```sqf
[
    _class,          // [0] Crate class name
    _location,       // [1] [position, vectorDirAndUp]
    _crateData,      // [2] [damage, inventory]
    _customVars      // [3] Array of [varName, varValue] pairs
]
```

## Usage Examples

### Basic Initialization
```sqf
// Initialize with 20-minute autosave interval
[20] call vn_mf_fnc_start_save_loop;

// Load existing save data
[] call vn_mf_fnc_full_load;
```

### Manual Save/Load
```sqf
// Trigger manual save
[] call vn_mf_fnc_full_save;

// Check tracked vehicles
_vehicles = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
_crates = missionNamespace getVariable ["vn_mf_tracked_crates", []];
```

### Vehicle Management
```sqf
// Add vehicle to tracking (if not auto-detected)
[myVehicle] call vn_mf_fnc_add_vehicle_to_tracking;

// Remove temporary vehicle from tracking
[tempVehicle] call vn_mf_fnc_remove_vehicle_from_tracking;

// Check if vehicle is friendly faction
_isFriendly = [someVehicle] call vn_mf_fnc_is_friendly_vehicle;
```

### Cleanup Operations
```sqf
// Remove any non-friendly vehicles from tracking
[] call vn_mf_fnc_cleanup_tracked_vehicles;
```

## Integration Points

### Event System Integration
The system binds to the `vehicleCreated` event from Paradigm's event system:
```sqf
["vehicleCreated", [handlerCode, []]] call para_g_fnc_event_add_handler;
```

### Vehicle Asset Manager Integration
- Preserves `vehAssetId` and `veh_asset_spawnpointid` variables
- Works with vehicle respawn and asset management systems
- Handles packaged wreck states

### Supply System Integration
- Tracks supply drop crates based on `supply_drop_config` variable
- Integrates with supply drop configurations from mission config

## Performance Considerations

### Automatic Cleanup
- Dead/deleted vehicles are automatically removed from tracking
- Periodic cleanup removes invalid references
- Area-restricted vehicles are filtered during save operations

### Memory Management
- Only active, valid vehicles are tracked
- Destroyed objects are immediately removed from arrays
- Save data is compressed and optimized

### Network Optimization
- Server-side processing only
- Minimal network traffic during save operations
- Event handlers attached locally per vehicle

## Troubleshooting

### Common Issues

**Vehicles not being saved**:
- Check if vehicle class is in `vehicle_respawn_info.hpp`
- Verify vehicle faction using `faction` command
- Ensure vehicle is not in restricted area

**Enemy vehicles being saved**:
- Run cleanup function: `[] call vn_mf_fnc_cleanup_tracked_vehicles`
- Check faction filtering logic in `vn_mf_fnc_is_friendly_vehicle`

**Save/Load failures**:
- Check server logs for error messages
- Verify profile database is accessible
- Ensure sufficient server permissions

### Debug Commands
```sqf
// Check tracking status
_tracked = missionNamespace getVariable ["vn_mf_tracked_vehicles", []];
diag_log format ["Tracking %1 vehicles", count _tracked];

// Test faction check
_friendly = [vehicle player] call vn_mf_fnc_is_friendly_vehicle;
hint format ["Player vehicle is friendly: %1", _friendly];

// Manual cleanup
_removed = [] call vn_mf_fnc_cleanup_tracked_vehicles;
systemChat format ["Removed %1 non-friendly vehicles", _removed];
```

## Related Systems

- **[Paradigm Event System](../../../Paradigm/docs/systems/events.md)** - Core event dispatching
- **Vehicle Asset Manager** - Vehicle spawning and management
- **Supply System** - Supply crate management  
- **Zone System** - Area-based restrictions
