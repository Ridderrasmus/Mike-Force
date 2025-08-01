# Mike Force Mission System

## Overview

Mike Force is a persistent, cooperative multiplayer mission for Arma 3 set during the Vietnam War. Players work together as special forces units conducting operations across multiple maps, building forward operating bases, and completing objectives in a dynamic, evolving campaign.

## Mission Concept

### Setting
- **Time Period:** Vietnam War era
- **Player Role:** Special forces units (SOG, MACV-SOG)
- **Mission Type:** Persistent cooperative campaign
- **Maps:** Multiple Vietnam-era maps (Cam Lao Nam, Khe Sanh, The Bra, Altis)

### Core Gameplay
- **Base Building:** Establish and expand forward operating bases
- **Zone Operations:** Capture and secure strategic zones
- **Dynamic Tasks:** Procedurally generated missions and objectives
- **Resource Management:** Logistics, supplies, and equipment management
- **Persistence:** Progress and assets saved between sessions

## System Architecture

### Core Systems

#### Zone System
Manages the dynamic campaign map with capturable zones and strategic objectives.

**Key Features:**
- Dynamic zone generation and status tracking
- Progressive zone unlocking based on campaign progress
- Zone-specific resources and strategic value
- Real-time status updates and visualization

#### Vehicle Saving System
Comprehensive vehicle persistence and management system.

**Key Features:**
- Event-driven vehicle tracking
- Faction-based filtering to prevent enemy vehicle pollution
- Automatic save/load functionality
- Vehicle respawn and restoration

**Documentation:** [Vehicle Saving System](systems/vehicle-saving.md)

#### Task System
Dynamic mission generation and objective management.

**Key Features:**
- Procedural task generation based on campaign state
- Multi-objective task types (capture, destroy, rescue, etc.)
- Task dependencies and prerequisites
- Progress tracking and completion rewards

#### Base Building System
Player-constructed forward operating bases with functional buildings.

**Key Features:**
- Modular building placement system
- Functional buildings (respawn points, arsenals, logistics)
- Building health and damage simulation
- Resource requirements and construction progression

#### Arsenal System
Customizable equipment and weapon management.

**Key Features:**
- Era-appropriate weapon and equipment selection
- Role-based loadout restrictions
- Custom loadout saving and sharing
- Ammunition and supply management

#### Logistics System
Supply chain management for bases and operations.

**Key Features:**
- Resource transportation and delivery
- Supply point management
- Fuel, ammunition, and medical supplies
- Helicopter and ground transport integration

### Support Systems

#### Paradigm Framework Integration
Mike Force is built on the Paradigm framework, providing:
- Event-driven architecture
- Client-server communication
- Database persistence
- Utility functions and helpers

#### Map Configuration
Per-map customization system supporting multiple terrains:
- Map-specific spawn points and zones
- Terrain-appropriate assets and vehicles
- Custom objectives and mission parameters
- Environmental and cultural adaptations

#### Mod Support
Integration with popular Arma 3 mods:
- **TFAR/ACRE:** Advanced radio communication
- **ACE:** Enhanced medical and logistics systems
- **RHS/CUP:** Extended vehicle and weapon content
- **Unsung:** Vietnam War-specific content

## File Structure

```
Mike-Force/
├── mission/                    # Core mission files
│   ├── functions/             # Mission-specific functions
│   │   ├── systems/          # Core system implementations
│   │   ├── tasks/            # Task system functions
│   │   └── core/             # Basic mission functionality
│   ├── config/               # Mission configuration
│   │   ├── subconfigs/       # System-specific configs
│   │   └── ui/               # User interface configs
│   ├── eventhandlers/        # Event handler definitions
│   └── img/                  # Mission images and icons
├── maps/                     # Map-specific configurations
│   ├── altis/               # Altis map configuration
│   ├── cam_lao_nam/         # Cam Lao Nam configuration
│   ├── vn_khe_sanh/         # Khe Sanh configuration
│   └── vn_the_bra/          # The Bra configuration
├── Paradigm/                # Framework dependency
└── docs/                    # Documentation
    └── systems/            # System documentation
```

## Configuration System

### Mission Parameters
Customizable mission settings accessible through Arma 3's parameter system:

- **Difficulty Settings:** AI skill, damage multipliers, respawn options
- **Gameplay Options:** Base building enabled, vehicle persistence, task frequency
- **Logistics Settings:** Supply requirements, transportation options
- **Communication:** Radio settings, command structure options

### Map Configuration
Each supported map has dedicated configuration files:

- **Spawn Points:** Player insertion and respawn locations
- **Zone Definitions:** Strategic areas and capture objectives
- **Asset Placement:** Vehicles, supplies, and static objects
- **Environmental Settings:** Weather, time of day, atmospheric effects

### System Configuration
Individual systems have dedicated configuration files:

- **Arsenal:** Available weapons and equipment by role and era
- **Vehicles:** Spawn lists, respawn settings, and restrictions
- **Tasks:** Task types, generation parameters, and rewards
- **Base Building:** Available structures and construction requirements

## Development Guide

### Function Organization

#### Naming Convention
All Mike Force functions follow this pattern:
```
vn_mf_fnc_<system>_<function_name>
```

Examples:
- `vn_mf_fnc_veh_save` - Vehicle system save function
- `vn_mf_fnc_task_create` - Task system creation function
- `vn_mf_fnc_zone_capture` - Zone system capture function

#### Scope Indicators
Functions are organized by execution context:
- **Server Functions:** Execute on server only
- **Client Functions:** Execute on clients only
- **Shared Functions:** Can execute on both server and clients

### Event Integration

#### System Events
Mike Force integrates with Paradigm's event system:

```sqf
// Listen for vehicle creation
["vehicleCreated", {
    params ["_args", "_vehicle"];
    // Add to tracking if friendly
    if ([_vehicle] call vn_mf_fnc_is_friendly_vehicle) then {
        vn_mf_tracked_vehicles pushBack _vehicle;
    };
}] call para_g_fnc_event_add_handler;
```

#### Custom Events
Mission-specific events for system communication:

- `zoneOpened` - New zone becomes available
- `zoneCaptured` - Zone successfully captured
- `taskCompleted` - Mission objective completed
- `baseEstablished` - New forward operating base created
- `suppliesDelivered` - Logistics delivery completed

### Database Integration

#### Persistence System
Mike Force uses Paradigm's database system for persistence:

```sqf
// Save mission progress
["missionProgress", _progressData] call para_s_fnc_profile_db;

// Load saved vehicles
private _savedVehicles = ["savedVehicles", []] call para_s_fnc_profile_db;
```

#### Data Structure
Persistent data is organized by category:
- **Mission State:** Campaign progress, completed objectives
- **Vehicle Data:** Saved vehicle positions, damage, and inventory
- **Base Data:** Constructed buildings and base layouts
- **Player Data:** Individual player progress and statistics

## Gameplay Features

### Dynamic Campaign
The mission evolves based on player actions and campaign progress:

- **Zone Progression:** Capturing zones unlocks new areas and objectives
- **Adaptive Difficulty:** AI strength and mission complexity scales with progress
- **Resource Scarcity:** Limited supplies create strategic decisions
- **Persistent Consequences:** Player actions have lasting impact on campaign

### Cooperative Gameplay
Designed for teamwork and coordination:

- **Role Specialization:** Different player roles with unique capabilities
- **Shared Resources:** Common supply pools and logistics chains
- **Group Objectives:** Tasks requiring coordination between multiple players
- **Command Structure:** Leadership roles and tactical coordination tools

### Immersive Elements
Period-accurate and atmospheric features:

- **Era-Appropriate Equipment:** Vietnam War-era weapons, vehicles, and gear
- **Authentic Radio Procedures:** TFAR integration for realistic communication
- **Environmental Challenges:** Weather, terrain, and logistical constraints
- **Historical Context:** Mission briefings and objectives based on actual operations

## Technical Requirements

### Mods Required
- **Unsung Vietnam War Mod** - Core Vietnam content
- **TFAR or ACRE** - Radio communication (recommended)
- **CBA_A3** - Community Base Addons

### Mods Recommended
- **ACE** - Enhanced medical and logistics
- **RHS** - Additional vehicles and weapons
- **CUP** - Extended content library

### Server Requirements
- **Dedicated Server:** Recommended for persistent gameplay
- **Database Support:** For persistence functionality
- **Performance:** Adequate CPU and memory for AI and simulation

## Mission Flow

### Campaign Start
1. **Initial Briefing:** Mission overview and objectives
2. **Base Establishment:** Choose and secure initial operating base
3. **Asset Allocation:** Distribute initial vehicles and supplies
4. **Zone Reconnaissance:** Scout available zones and plan operations

### Operational Phase
1. **Task Generation:** Dynamic missions based on campaign state
2. **Execution:** Coordinate and complete objectives
3. **Logistics:** Manage supplies and transportation
4. **Base Expansion:** Construct additional facilities and defenses

### Campaign Progression
1. **Zone Capture:** Secure strategic objectives
2. **Resource Accumulation:** Build supplies and capabilities
3. **Area Expansion:** Unlock new operational areas
4. **Final Objectives:** Complete campaign-ending missions

## Performance Optimization

### Server Performance
- **AI Management:** Dynamic AI spawning and cleanup
- **Object Cleanup:** Automatic removal of abandoned objects
- **Database Optimization:** Efficient data storage and retrieval
- **Network Optimization:** Minimized network traffic

### Client Performance
- **LOD Management:** Distance-based detail reduction
- **Effect Optimization:** Reduced particle effects at distance
- **UI Efficiency:** Optimized interface updates
- **Memory Management:** Cleanup of unused assets

## Troubleshooting

### Common Issues

#### Vehicle Persistence Problems
- Check faction filtering in vehicle save system
- Verify database connectivity and permissions
- Review vehicle tracking event handlers

#### Task System Issues
- Validate task configuration files
- Check zone availability and prerequisites
- Verify event handler registration

#### Base Building Problems
- Check building placement permissions
- Verify resource availability
- Review construction prerequisites

### Debugging Tools

#### Debug Mode
Enable detailed logging:
```sqf
vn_mf_debug_enabled = true;
```

#### Console Commands
Administrative commands for testing:
- `call vn_mf_fnc_debug_vehicle_save` - Test vehicle persistence
- `call vn_mf_fnc_debug_task_create` - Generate test tasks
- `call vn_mf_fnc_debug_zone_status` - Display zone information

## Contributing

### Code Standards
- Follow established naming conventions
- Include comprehensive function documentation
- Test all changes thoroughly
- Maintain compatibility with existing saves

### Documentation
- Update system documentation for changes
- Include usage examples
- Document configuration options
- Maintain accuracy with code

### Testing
- Test in single-player and multiplayer
- Verify persistence functionality
- Check performance impact
- Validate mod compatibility

## Version History

### Current Features
- Event-based vehicle saving with faction filtering
- Dynamic zone and task system
- Comprehensive base building
- Multi-map support
- Persistence across sessions

### Known Issues
- Performance degradation with large numbers of AI
- Occasional synchronization issues in multiplayer
- Map-specific balance adjustments needed

### Planned Features
- Enhanced AI behavior and tactics
- Expanded base building options
- Additional task types and complexity
- Improved player progression system

## Support

### Documentation
- System documentation in `docs/systems/`
- Configuration examples in source files
- Troubleshooting guides for common issues

### Community
- GitHub repository for issues and contributions
- Community forums for discussion
- Regular updates and improvements

## License

Mike Force is released under the terms specified in LICENSE.txt. The mission includes content from various community mods and resources used with permission.
