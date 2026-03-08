Great choice -- a top-down Zelda-like is one of the best genres for a first prototype because the core loop (move, fight, explore) is simple and satisfying. And good news: I have a battle-tested template for exactly this genre, plus lessons from a previous build ("Forge of Worlds") that will save us significant time.

Let me walk you through the plan, and then we will tackle Phase 1 together right now.

---

## How This Will Work (5 Phases)

1. **Concept & Planning** (now) -- Define scope, name the game, write a GDD and a CLAUDE.md
2. **Asset Pipeline** -- Organize your CraftPix sprites, analyze sheet layouts, import into Godot
3. **Build Core** -- Player movement, slime AI, sword combat, world map, HUD (one entity at a time, testing after each)
4. **Polish** -- Audio, screen shake, knockback, damage numbers
5. **Wrap Up** -- Final playtest, cleanup, commit

We build incrementally: Player first, then slime, then combat, then world, then HUD. Each step gets tested before moving on. This catches bugs early -- in the Forge of Worlds build, this approach caught direction-mapping bugs that would have cascaded into every entity.

---

## What We Should Do First: Phase 1 (Concept & Planning)

Before writing a single line of code, we need two documents. This takes about 10 minutes and prevents hours of wasted work later.

### Step 1: Scope the Prototype

Based on your description, here is a proposed scope. Tell me what to add or cut:

**MUST HAVE (prototype is incomplete without these):**
- Player: 8-directional movement with walk/idle animations
- Sword attack: slash in facing direction with hitbox
- Slime enemy: wander + chase player when close + contact damage
- Health system: player and enemies have HP
- Damage feedback: flash + knockback + invincibility frames (1s blink)
- Death: slime death fade, player death triggers restart
- One map: green field with grass, trees, rocks (TileMapLayer)
- Camera following the player
- HUD: hearts display

**SHOULD HAVE (after MUST HAVE works):**
- Background music (chiptune)
- Sound effects (sword swing, hit, pickup)
- Heart pickups that restore HP

**EXPLICITLY OUT OF SCOPE (we will not build these):**
- Inventory or equipment
- Multiple maps or room transitions
- Save/load system
- Menu screens (title, pause, settings)
- Multiple enemy types
- Leveling or XP

### Step 2: A Few Questions for You

Before I draft the GDD and CLAUDE.md, I need to confirm a few things:

1. **Game name** -- Even a working title helps. Something like "Slime Fields," "Blade of the Wilds," or whatever resonates with you. Naming creates engagement and makes the session more fun.

2. **Your CraftPix assets** -- Which specific packs do you have? The CraftPix top-down packs use a specific row convention (DOWN=0, LEFT=1, RIGHT=2, UP=3) and some sheets have non-uniform frame counts. I need to analyze the exact sheets before writing animation code. Common packs for this genre:
   - Swordsman character (48x48 or 64x64)
   - Slime mobs pack
   - Top-down tileset

3. **Viewport size** -- For 64x64 sprites, I recommend a 640x360 viewport with 2x camera zoom. This gives a good field of view without sprites being too small or too large.

4. **Language for code comments** -- Any preference? (English, Portuguese, etc.)

### Step 3: What I Will Create (After Your Answers)

Once you confirm the scope and answer those questions, I will produce:

1. **GDD.md** -- A one-pager game design document covering:
   - Elevator pitch and design pillars
   - Core loop: Explore -> Fight -> Survive -> Explore
   - Player stats (HP, damage, speed)
   - Slime AI behavior (wander, chase range, damage)
   - Reference games and non-goals

2. **CLAUDE.md** -- The technical architecture document covering:
   - Collision layer assignments (Player=2, Enemies=3, PlayerHitbox=4, EnemyHitbox=5, etc.)
   - File structure (scenes/, scripts/, assets/)
   - GDScript conventions
   - MCP workflow notes and anti-patterns
   - Sprite sheet conventions for your specific assets

3. **Project setup** -- Copy the `zelda-like-rpg` template (which has a pre-configured `project.godot` with pixel art settings, input maps, and collision layers already defined).

---

## Key Technical Decisions (Already Battle-Tested)

These come from real build sessions and will save us from common pitfalls:

| Decision | Why |
|----------|-----|
| **Area2D for all damage** (not body-to-body collision) | Body collisions cause the player to get pushed around by enemies |
| **Dual damage detection**: `area_entered` signal + periodic `get_overlapping_areas()` | The signal fires only once on overlap -- if an enemy stays on top of you, damage stops. Periodic polling catches ongoing contact. |
| **Cycle-based animation speed** (total_time / frame_count) | CraftPix sheets sometimes have different frame counts per direction (e.g., UP idle has 4 frames while others have 12). Fixed per-frame delay makes some directions animate 3x faster. |
| **CanvasLayer for all UI** | World-space UI text is blurry at low pixel-art resolutions |
| **Pause game during dialog** | Without pausing, enemies attack while the player reads text |
| **Short stun (0.3s) + long invincibility (1.0s)** | Blocking all input during hurt state means the player can never escape enemies |

---

## What Happens After Planning

Once we have the GDD and CLAUDE.md nailed down, the build order is:

```
1. Organize your CraftPix sprites into assets/sprites/player/, enemies/, etc.
2. Analyze each sprite sheet (dimensions, frame count, row order)
3. Import assets: godot --headless --import
4. Build Player scene -> test movement
5. Build Slime scene -> test AI behavior
6. Build combat (hitbox/hurtbox) -> test hitting and dying
7. Build world (TileMapLayer + boundaries) -> test spawning
8. Build HUD (CanvasLayer + hearts) -> test HP display
9. Add audio (music + sword SFX)
10. Polish and playtest
```

I will use Godot MCP to create scenes and add nodes, and you will be able to watch nodes materialize in real-time in the editor. The MCP also lets me run the game, capture debug output, and fix issues in rapid 3-second iteration cycles.

---

**So -- what would you like to name the game, and which CraftPix packs do you have downloaded?** Once I have those answers, I will draft both documents and we can start building.
