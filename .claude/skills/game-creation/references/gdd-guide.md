# Game Design Document Guide

This reference covers GDD best practices, templates, and genre-specific patterns. Read this during Phase 1 (Concept & Planning) when creating the GDD.md for a new game project.

## Table of Contents

1. [GDD vs CLAUDE.md](#gdd-vs-claudemd)
2. [One-Pager Template](#one-pager-template)
3. [Prototype GDD Template](#prototype-gdd-template)
4. [Design Pillars](#design-pillars)
5. [Core Loop Documentation](#core-loop-documentation)
6. [Genre-Specific Sections](#genre-specific-sections)
7. [Writing for AI Consumption](#writing-for-ai-consumption)
8. [Living Document Pattern](#living-document-pattern)
9. [Common Mistakes](#common-mistakes)

---

## GDD vs CLAUDE.md

These are two separate documents that serve different audiences:

| | GDD.md | CLAUDE.md |
|---|---|---|
| **Audience** | Human (designer, player, stakeholder) | AI agent (Claude Code) |
| **Purpose** | Define what the game IS and WHY | Define HOW to build it |
| **Contains** | Elevator pitch, design pillars, core loop, story, feel | File structure, collision layers, coding conventions, tool workflow |
| **Tone** | Inspirational, player-focused | Technical, implementation-focused |
| **Changes** | Design pillars stable; mechanics volatile | Architecture stable; conventions accumulate |

The GDD answers "what game are we making?" The CLAUDE.md answers "how do we build it?"

---

## One-Pager Template

Start here. If the one-pager doesn't excite you, the game won't either. This is the "movie poster + elevator pitch" for your game.

```markdown
# [Game Title]

**Genre:** [e.g., Top-down Action RPG]
**Platform:** PC (Godot 4.x)
**Art Style:** [e.g., 16-bit pixel art, top-down perspective]
**Scope:** Prototype (~1 session)

## Elevator Pitch
[1-2 sentences. Use the "X meets Y" formula if it fits.]
[e.g., "Zelda combat meets roguelike progression. Explore a cursed forest,
fight elemental slimes, and upgrade your weapons between runs."]

## Design Pillars
1. **[Pillar Name]** — [One sentence explaining what this means for the player]
2. **[Pillar Name]** — [One sentence]
3. **[Pillar Name]** — [One sentence]

## Core Loop
[Action] → [Challenge] → [Reward] → (repeat)

[e.g., "Explore → Fight enemies → Collect loot → Upgrade gear → Explore harder areas"]

## Key Mechanics
- [Mechanic 1]: [One sentence]
- [Mechanic 2]: [One sentence]
- [Mechanic 3]: [One sentence]

## Reference Games
- [Game 1] — [What we're taking from it]
- [Game 2] — [What we're taking from it]

## Non-Goals
- [What this game is NOT]
- [Features explicitly out of scope]
```

---

## Prototype GDD Template

Expand to this once the one-pager holds up. Target 3-5 pages for a prototype. Each section should be self-contained — a reader (or AI agent) should understand it without reading the whole document.

```markdown
# [Game Title] — Game Design Document

**Version:** 0.1 (prototype)
**Last Updated:** [date]
**Genre:** [genre]
**Engine:** Godot 4.x (GDScript)
**Art Style:** [pixel art size, perspective, color references]

---

## 1. Overview

### Elevator Pitch
[1-2 sentences]

### Design Pillars
1. **[Name]** — [Explanation]
2. **[Name]** — [Explanation]
3. **[Name]** — [Explanation]

### Reference Games
| Game | What We Take | What We Don't |
|------|-------------|---------------|
| [Game] | [Specific mechanic/feel] | [What to avoid from it] |

---

## 2. Core Loop

### Moment-to-Moment (seconds)
[Action] → [Challenge] → [Reward] → repeat

### Session Loop (minutes)
[Larger cycle that wraps the core loop]

### Diagram
    +---------+     +-----------+     +--------+
    | EXPLORE | --> | ENCOUNTER | --> | COMBAT |
    +---------+     +-----------+     +--------+
         ^                                |
         |           +--------+           |
         +---------- | REWARD | <---------+
                     +--------+

---

## 3. Player Character

**Name:** [name]
**Description:** [1 sentence]

### Movement
- Speed: [X] pixels/sec
- Type: [8-directional / side-scroll / etc.]
- Special: [dash, dodge, etc.]

### Combat
- Attack type: [melee / ranged / both]
- Damage: [X] per hit
- Attack speed: [X] attacks/sec
- Special moves: [list]

### Health & Defense
- Max HP: [X]
- Invincibility after hit: [X] seconds
- Death behavior: [respawn / game over / lose progress]

---

## 4. Enemies

### [Enemy Name]
- **Role:** [fodder / tank / ranged / boss]
- **HP:** [X]
- **Damage:** [X]
- **Behavior:** [patrol / chase when close / ranged attack / etc.]
- **Speed:** [X] pixels/sec
- **Detection range:** [X] pixels
- **Drop:** [what the player gets for killing it]

(Repeat for each enemy type)

---

## 5. Game World

### Setting
[1-2 sentences about the world]

### Map Structure
- [How many areas/levels?]
- [How are they connected?]
- [Any locked/gated areas?]

### Environment Hazards
- [List any environmental damage sources]

---

## 6. Progression

### What the player earns
- [XP / items / abilities / currency]

### How difficulty increases
- [More enemies / harder enemies / less resources / time pressure]

### Win Condition
[What ends the game successfully?]

### Lose Condition
[What ends the game unsuccessfully?]

---

## 7. UI / HUD

### In-Game HUD
- [Health display: hearts / bar / number]
- [Score / currency display]
- [Minimap? Inventory? Ability cooldowns?]

### Menus
- [Title screen? Pause menu? Settings?]

---

## 8. Audio Direction

### Music
- Style: [chiptune / orchestral / ambient / etc.]
- When it plays: [overworld, combat, boss, menu]

### Sound Effects
- [Player actions: sword swing, footstep, jump]
- [Enemy actions: hit, death, alert]
- [UI: menu click, pickup, level up]

---

## 9. Art Direction

### Style References
- [Link or describe 2-3 visual references]

### Specifications
- Sprite size: [X]x[X] pixels
- Viewport: [X]x[X]
- Perspective: [top-down / side-scroll / isometric]
- Color palette: [describe or link]

---

## 10. Scope

### MUST HAVE (prototype is incomplete without these)
- [ ] [Feature 1]
- [ ] [Feature 2]
- [ ] [Feature 3]

### SHOULD HAVE (add if MUST HAVE is done)
- [ ] [Feature]
- [ ] [Feature]

### NICE TO HAVE (only if time permits)
- [ ] [Feature]

### EXPLICITLY OUT OF SCOPE
- [Feature that will NOT be built]
- [Feature that will NOT be built]

### NOT YET (acknowledged ideas, deferred)
- [Idea for future consideration]

---

## Changelog
- v0.1 — Initial prototype GDD
```

---

## Design Pillars

Design pillars are 3-5 statements that define the core experience. Every feature decision should serve at least one pillar. If it doesn't, it probably doesn't belong.

### How to Write Them

- **Label:** 2-4 words (e.g., "Tense Resource Scarcity")
- **Explanation:** 1 sentence describing what the player experiences
- **Testable:** You can look at any feature and ask "does this serve pillar X?"

### Examples from Real Games

| Game | Pillars |
|------|---------|
| **Zelda: BotW** | Freedom of Exploration, Physics-driven Interaction, Player Agency |
| **The Last of Us** | Crafting, Story, AI Partners, Stealth |
| **God of War (2018)** | Intense Combat, Father/Son Story, World Exploration |
| **Unpacking** | Zen Relaxation, Personal Storytelling, Tactile Satisfaction |

### Example for a Prototype

```
1. **Crunchy Combat** — Every hit should feel impactful with screen shake,
   knockback, and a satisfying sound effect.
2. **Exploration Reward** — The world rewards curiosity with hidden items,
   shortcuts, and story fragments.
3. **Quick Sessions** — A full play session should take 10-15 minutes.
   Easy to pick up, easy to put down.
```

### Pillar Count

- **3 pillars** — best for prototypes and game jams (forces focus)
- **4-5 pillars** — appropriate for larger indie projects
- **More than 5** — usually a sign of unfocused design; try to merge or cut

---

## Core Loop Documentation

### The Three Levels of Loops

1. **Core Loop (moment-to-moment)** — The smallest repeatable action. Takes seconds.
   - Zelda: Swing sword → Hit enemy → Enemy drops item → Pick up item
   - Platformer: Run → Jump → Land on platform → Run

2. **Session Loop (meta)** — What a single play session looks like. Takes minutes.
   - Zelda: Enter dungeon → Clear rooms (core loop x N) → Beat boss → Return to town → Upgrade

3. **Retention Loop (long-term)** — What brings players back. Takes days/weeks.
   - Zelda: Unlock new area → Discover story → Gain new abilities → Access harder content

### How to Document

**Text format** (always include):
```
Core: Explore → Fight → Loot → Explore
Session: Enter Area → Clear Encounters → Find Boss → Defeat Boss → Upgrade
```

**ASCII diagram** (include for complex loops):
```
    +---------+     +-----------+     +--------+
    | EXPLORE | --> | ENCOUNTER | --> | COMBAT |
    +---------+     +-----------+     +--------+
         ^                                |
         |           +--------+           |
         +---------- | REWARD | <---------+
                     +--------+
```

### Core Loop Components

Every loop needs three elements:
- **Challenge** — a task or obstacle the player must overcome
- **Action** — what the player does to overcome it
- **Reward** — what the player receives (must feed back into enabling more/harder challenges)

If any element is missing, the loop breaks. No reward = no motivation. No challenge = boring. No action = watching, not playing.

---

## Genre-Specific Sections

Add these sections to the prototype GDD template depending on genre:

### Top-Down Action RPG
- **Stat System:** HP, attack, defense, speed (keep minimal for prototype)
- **Damage Formula:** `final_damage = attack - defense` (or whatever the system uses)
- **Knockback:** Distance, duration, direction calculation
- **Invincibility:** Stun duration vs. protection duration (separate values)
- **Aggro System:** Detection range, chase speed, leash distance

### Platformer
- **Movement Feel:** Jump height (pixels), gravity multiplier, coyote time (ms), jump buffer (ms)
- **Camera:** Follow speed, look-ahead distance, vertical deadzone
- **Level Design Rules:** Max gap width, max wall height, checkpoint frequency
- **Difficulty Curve:** How each level introduces new mechanics/obstacles

### Puzzle Game
- **Puzzle Rules:** The fundamental mechanic (matching, routing, placement, etc.)
- **Difficulty Progression:** How puzzles get harder (more elements, time pressure, fewer hints)
- **Hint System:** When and how hints are offered
- **Level Count:** Target number of puzzles for the prototype

### Roguelike / Roguelite
- **Run Structure:** Average run length, number of rooms/floors
- **Permadeath vs. Persistence:** What resets on death, what persists
- **Procedural Generation:** What's randomized (map layout, enemy placement, items)
- **Item/Ability Pool:** List of possible pickups with effects

### Tower Defense
- **Wave Structure:** Number of waves, enemy count scaling, boss waves
- **Tower Types:** Name, cost, damage, range, special effect
- **Economy:** Starting gold, gold per kill, gold per wave
- **Path Design:** Fixed path, branching path, or open field

---

## Writing for AI Consumption

When the GDD will be used by Claude Code or another AI assistant, follow these rules to maximize effectiveness:

1. **Use markdown** — AI models parse headers, lists, and code blocks natively
2. **Semantic headings** — `## Combat System` not `## Section 4`
3. **Bullet points over prose** — structured lists are easier to extract from than paragraphs
4. **Concrete values** — "Player moves at 200 px/sec" not "player moves at moderate speed"
5. **Explicit constraints** — state what NOT to do; AI agents add unrequested features
6. **Self-contained sections** — each section understandable without reading the whole doc
7. **Rules format for mechanics** — "IF player HP <= 0 THEN play death animation THEN respawn at checkpoint" is clearer than narrative descriptions
8. **Keep it under 5 pages** — AI context windows are finite; a 50-page GDD wastes tokens

### Example: Vague vs. Concrete

```
BAD:  "The player should feel powerful but vulnerable"
GOOD: "Player deals 2 damage per hit, has 6 HP (3 hearts).
       Enemies deal 1-2 damage. Player dies in 3-6 hits.
       Invincibility: 1.0s after hit with sprite blink."
```

---

## Living Document Pattern

The GDD evolves as you build. Here's what to expect:

### What Stays Stable
- Elevator pitch
- Design pillars
- Genre and platform
- Art style direction
- Core loop structure

### What Changes Often
- Specific mechanic parameters (speed, damage, HP)
- Level designs and progression
- Balance numbers
- Asset lists
- Schedule estimates

### Best Practices
- **Version number + date** at the top of the GDD
- **Changelog section** at the bottom tracking major changes
- **"Not Yet" list** for ideas acknowledged but deferred
- **Review weekly** — even solo devs should re-read their GDD regularly
- **Update after playtesting** — test results should feed back into the GDD
- **Split when it grows** — if the GDD exceeds 10 pages, break into per-system docs

---

## Common Mistakes

1. **Over-documenting** — Writing 50 pages nobody reads. Prototype GDDs should be 3-5 pages.
2. **No core loop** — Pages of lore but no definition of what the player actually *does*.
3. **Vague mechanics** — "Combat should feel satisfying" gives no implementation guidance. Use numbers.
4. **No non-goals** — Without explicit "out of scope", every idea feels valid and scope creeps.
5. **Never updating** — A stale GDD is worse than no GDD. It becomes actively misleading.
6. **Scope dumping** — Using the GDD as a bucket for every idea that comes up. Use the "Not Yet" list.
7. **Ignoring the reader** — Writing too technically for designers or too vaguely for engineers.
8. **Missing the "feel"** — The GDD should convey what playing the game FEELS like, not just what systems exist.
