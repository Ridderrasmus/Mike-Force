# ReImplement a road‑ambush mechanic where player movement drives ambush site selection within zone commander operational areas. Each player runs a small client‑side script that records which roads they travel on and updates a shared server variable storing usage scores for road segments. Zone commanders evaluate player activity within their operational range and deploy guerrilla ambushes through a multi-step process involving AI spawning, movement, and setup phases.orked Road Ambush System — Issue Specification (Zone Commander System)




## Progress:

Currently the system work in very very broad strokes. There's an ambush script which is managed by an ai commander and it send out squads which get set up in the field on their designated positions...

However, when the mine spawned explodes something seems to error in the script that the trigger is supposed to run, also the determined ambush position is not within the expected max distance of the highest value found road segment. (Or it might be but since I've turned down the min value for the road segments to 0, it might be that the selected road segment is just a random one far away...)
The ai commander also is able to check for road usage far outside its previously intended operational radius, so that needs to be fixed as well.


## Overview / Objective

Implement a road‑ambush mechanic where player movement drives ambush site selection. Each player runs a small client‑side script that records which roads they travel on and updates a shared server variable storing usage scores for road segments. Only objectives marked as active should use those scores to deploy guerrilla ambushes; inactive objectives simply accumulate road‑usage data for later. This revision removes the concept of per‑objective “cells” and centralises ambush management at the objective level.

**Key design priorities:**
- Only actual roads are considered, not off-road paths or combat heatmaps.
- Both vehicles and infantry on roads are tracked. Vehicles increment the score by 2, infantry by 1.
- System should avoid requiring manual marker placement for ambush zones. Ambush-eligible road segments are auto-detected at mission start.
- Ambush sites must be pre-filtered at mission init for suitability (e.g., forest/bushes on both sides); unsuitable segments are ignored.
- Road segments are identified by a unique key (e.g., type_start_end).
- Only roads of "large" and "small" (main/secondary) types are considered, not paths.
- Zone commanders manage ambushes within their operational radius, with limits on concurrent ambushes and minimum cooldown periods.
- Ambush creation follows a realistic multi-step process: spawn at FOB → move to position → setup ambush.
- Scheduler system (e.g., Paradigm's) should be used for mission-start road analysis to avoid server load spikes.
- The system must be robust for persistent missions and not require manual editor setup.

---

## Key Requirements

### 1. Road Network Preprocessing (Mission Init)
- At mission start, server iterates all road segments.
- For each segment, checks if it is ambush-suitable (e.g., has forest/bushes on both sides and is of accepted type).
- Only suitable segments are stored in a global hashmap with unique keys (e.g., type_start_end).
- The suitability check only runs once per segment, with results cached for efficiency.
- Unsuitable segments are permanently excluded from consideration.
- Scheduler/async system should be used for this processing to avoid server hitches.
- Optionally, bias toward segments within 1–2km of FOBs and enemy HQs for guaranteed ambush presence in high-traffic areas.

### 2. Client‑side road tracking
- On each client, start a scheduled script once the mission begins.
- Every N seconds (configurable, e.g., 10–60), check if the player is on/near a road segment (within 50–100m).
- If player is on foot or in a vehicle and near a valid road segment:
    - Increment local usage count for that segment.
    - Vehicles increment by 2, infantry by 1.
- Locally batch usage counts, then send updates to the server every M seconds (configurable, e.g., 30–120).
- Road segment is identified using the unique key defined in preprocessing.
- Only segments that passed the suitability check are tracked.

### 3. Server‑side road usage store
- Maintain a global hashmap (e.g., `MF_roadUsage`) mapping road segment keys to usage scores.
- When clients send usage data, increment the appropriate counters.
- Periodically decay usage values on a timer (configurable) to ensure recent movement is weighted more.
- Persistent missions: optionally save/load `MF_roadUsage` to profileNamespace or database if supported.

### 4. Zone commander ambush management
- Each zone commander operates within a defined operational radius around their zone.
- Zone commanders can only evaluate player activity and select ambush positions within their operational range.
- Each zone commander has a maximum number of concurrent ambushes they can manage (configurable).
- Minimum cooldown period between ambush orders being created by the same zone commander (configurable).
- Zone commanders continuously monitor road usage scores within their area and identify high-traffic segments.
- Only zone commanders with active status may initiate ambush operations.

### 5. Multi-step ambush creation process
**Step 1: Ambush Squad Spawning**
- Zone commander selects a high-score, valid road segment within their operational range.
- AI squad is spawned at the zone's FOB (Forward Operating Base).
- Squad receives movement orders to the selected ambush position.

**Step 2: Movement to Position**
- Squad moves from FOB to the designated ambush site.
- If squad encounters active combat during movement, abort ambush creation.
- Monitor squad status during transit - if squad is eliminated, abort and retry later.

**Step 3: Arrival Assessment**
- When squad arrives at ambush position, check if they are actively engaged in combat.
- If squad is in combat upon arrival, despawn the squad and abort ambush setup.
- If squad arrives safely without combat engagement, proceed to setup phase.

**Step 4: Ambush Setup**
- Despawn the movement squad and begin proper ambush placement.
- Place a command-detonated mine at the center of the road segment.
- Spawn concealed AI units in foliage on both sides of the road.
- AI units are positioned lying down in concealment.
- AI units are given strict ROE: do not engage anything until fired upon or mine explodes.
- Ambush is now active and waiting for player trigger.

**Step 5: Ambush Execution and Cleanup**
- Ambush triggers when mine explodes or AI units take fire.
- After brief engagement, surviving attackers attempt tactical withdrawal.
- Zone commander's ambush count is decremented when ambush concludes or is destroyed.

### 6. Configuration and toggles
- Expose constants for:
    - Road-tracking interval (client-side)
    - Batch update frequency (client-server)
    - Decay interval and rate (server-side)
    - Zone commander operational radius
    - Maximum concurrent ambushes per zone commander
    - Minimum cooldown time between ambush orders (per zone commander)
    - Ambush squad size and composition
    - Movement timeout for squads traveling to ambush positions
    - Road segment suitability parameters (e.g., required vegetation density, allowed road types)
    - AI Rules of Engagement settings for ambush units
- Mission makers can tweak these in mission params or a config file.

---

## Developer Tasks

- [ ] **Road network preprocessing**: Write server/init script to scan road network, check for suitability, and populate global hashmap.
- [ ] **Client-side tracking**: Script to track player movement on roads, batch counts, and send to server.
- [ ] **Server-side usage store**: Implement robust, persistent usage score storage with decay.
- [ ] **Zone commander system**: Implement zone commander logic with operational radius, ambush limits, and cooldown timers.
- [ ] **Multi-step ambush creation**: Implement the full ambush workflow from FOB spawning to setup completion.
- [ ] **AI movement and assessment**: Script for squad movement from FOB to ambush site with combat detection.
- [ ] **Ambush setup and ROE**: Implement mine placement, AI positioning, and strict engagement rules.
- [ ] **Configuration**: Expose all relevant parameters and document them.
- [ ] **Testing**: Validate performance, network load, and gameplay impact with multiple players and zone commanders.

---

## Acceptance Criteria

- Clients report road usage with negligible performance or network impact.
- Road suitability checks are done once per segment, at mission start, with results cached.
- Server accumulates and decays usage data correctly and efficiently.
- Zone commanders operate within their defined operational radius and respect concurrent ambush limits.
- Zone commanders enforce minimum cooldown periods between ambush orders.
- Multi-step ambush creation works: FOB spawn → movement → arrival assessment → setup → execution.
- AI squads properly abort ambush creation if engaged in combat during movement or arrival.
- Ambush setup correctly places mines and concealed AI with proper ROE (no engagement until triggered).
- Parameters are adjustable via mission settings for tuning.
- The system requires no manual placement of ambush markers or zones in the editor.

---

### Out-of-scope (may revisit later)
- Supply convoy and logistics interactions (floated as a possible future extension but not part of this spec).
- Combat heatmap-based ambush selection.
- Manual marker-based ambush zones.