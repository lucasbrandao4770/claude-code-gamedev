# Game Design Documents: Best Practices for AI-Assisted Prototype Development

> **Date:** 2026-03-08
> **Purpose:** Research report on GDD formats, templates, and workflows optimized for Claude Code + Godot prototype building
> **Scope:** Small indie/prototype games (2D pixel art RPGs, platformers, tower defense, puzzles)

---

## Table of Contents

1. [GDD Formats Compared](#1-gdd-formats-compared)
2. [GDD Sections Deep Dive](#2-gdd-sections-deep-dive)
3. [GDD for AI-Assisted Development](#3-gdd-for-ai-assisted-development)
4. [Interactive GDD Creation Process](#4-interactive-gdd-creation-process)
5. [From GDD to Implementation](#5-from-gdd-to-implementation)
6. [Scope Management and Quality Gates](#6-scope-management-and-quality-gates)
7. [Tools and Format Recommendations](#7-tools-and-format-recommendations)
8. [Recommended GDD Template for AI-Assisted Prototyping](#8-recommended-gdd-template-for-ai-assisted-prototyping)
9. [Interview Questions for GDD Creation](#9-interview-questions-for-gdd-creation)
10. [Quality Gate Checklist](#10-quality-gate-checklist)
11. [References and Resources](#11-references-and-resources)

---

## 1. GDD Formats Compared

### Full GDD (50-500+ pages)

Traditional game design documents used in AAA and mid-size studios. Comprehensive coverage of every system, mechanic, level, character, and technical requirement.

**Structure (LazyHatGuy/OpenGameGDD 13-chapter format):**

1. Copyright Information
2. Version History
3. Game Overview (concept, features, genre, audience, flow, scope)
4. Gameplay and Mechanics (progression, physics, movement, combat, economy, screen flow)
5. Story, Setting, and Character (narrative, world areas, character bios with stats)
6. Levels (per-level: synopsis, objectives, maps, encounters, walkthroughs)
7. Interface (HUD, menus, controls, audio systems)
8. Artificial Intelligence (enemy AI, NPC behavior, pathfinding)
9. Technical (hardware, engine, networking, scripting)
10. Game Art (concept art, style guides, asset lists)
11. Secondary Software (editors, installers)
12. Management (schedule, budget, risk, testing)
13. Appendices (complete asset inventories)

**When to use:** Teams of 10+, publisher pitches, multi-year projects.

**Not for us:** Way too heavy for prototypes. As Stone Librande (GDC) noted: "One page is often as much as anyone is willing to read of your design."

### One-Page GDD (1 page)

A single page capturing the essential vision. Popular for game jams and early-stage validation.

**Typical sections:**

- **Game Identity / Mantra** — One sentence (e.g., "Stylized action platformer about a meatball fighting the dinner table")
- **Design Pillars** — 3-5 keywords/phrases capturing target emotions (e.g., "stealthy, tactical, tense")
- **Genre** — Main genre + sub-genres
- **Core Mechanics** — What the player DOES, in 2-3 bullet points
- **Features** — Key gameplay features that distinguish the game
- **Visual Style** — Art direction in 1-2 sentences + references
- **Music & Sound** — Audio mood and style
- **Story** — Beginning, middle, end in 3 sentences
- **Platform** — Target platform and input method
- **Team / Timeline** — Who's building it and rough schedule

**When to use:** Game jams (48h constraint), initial brainstorming, concept validation before committing to development.

**Limitation:** Not enough detail for AI-assisted implementation — an LLM needs specifics about entities, attributes, and mechanics to generate correct code.

### Indie GDD (Jason Bakker / Gamedeveloper.com format)

A pragmatic middle-ground designed specifically for indie teams.

**Structure:**

1. **Intro** — One paragraph capturing the game's essence (written thematically, not as a sales pitch)
2. **Character Bios** — 1-2 paragraphs per major character, focusing on gameplay role
3. **Rough Plot** — 4-6 paragraphs from start to finish, marking cutscenes vs. gameplay
4. **Gameplay Description** — 1-2 paragraphs per distinct mode, starting with core mechanics
5. **Artistic Style Outline** — In-game art, UI, menus, audio aesthetic + reference imagery
6. **Systematic Breakdown** — Technical systems (rendering, state machines, collision, particles)
7. **Asset Breakdown** — Organized by type: Art, Text, Sound
8. **Game Flow Diagram** — Visual step-by-step player experience
9. **Project Timeline** — Work hours per team member, responsibilities
10. **Additional Ideas** — Appendix for alternate concepts and non-core features

**Philosophy:** "Everything must be allowed to change and evolve over the course of the project."

**When to use:** Small indie teams, solo devs with moderate-scope projects.

### AI-Optimized GDD (our recommended format)

A new format designed specifically for AI-assisted development. Combines human-readable markdown with machine-parseable structured data.

**Key innovation:** YAML frontmatter for structured metadata + markdown sections for narrative context. The AI gets both structured data it can parse programmatically AND natural language context for understanding intent.

**See [Section 8](#8-recommended-gdd-template-for-ai-assisted-prototyping) for the complete template.**

### Comparison Matrix

| Aspect | Full GDD | One-Page | Indie GDD | AI-Optimized |
|--------|----------|----------|-----------|--------------|
| Length | 50-500+ pages | 1 page | 5-15 pages | 3-8 pages |
| Time to create | Weeks-months | 30 min-1 hour | 1-3 days | 1-2 hours (interactive) |
| Detail level | Exhaustive | Minimal | Moderate | Targeted |
| AI-parseable | No (too verbose) | No (too vague) | Partially | Yes (by design) |
| Scope control | Strong (by volume) | Strong (by brevity) | Moderate | Strong (explicit boundaries) |
| Best for | AAA, publisher pitches | Game jams, brainstorms | Indie teams | AI-assisted prototyping |
| Maintenance | Heavy burden | Trivial | Moderate | Low (structured updates) |

---

## 2. GDD Sections Deep Dive

### What Every GDD Must Have (Genre-Independent)

Based on cross-referencing Tom Sloper's format, Unity's template, the Gamedeveloper.com guides, and the OpenGameGDD project, these sections appear in virtually every serious GDD template:

#### 2.1 Game Concept / Overview
- Elevator pitch (1-2 sentences)
- Genre classification
- Target platform and resolution
- Target audience
- Unique selling point / what makes it different

#### 2.2 Core Mechanics
- The core gameplay loop (what the player does repeatedly)
- Primary verbs (move, attack, build, explore, trade, etc.)
- Secondary mechanics (crafting, inventory, dialogue, etc.)
- Win/lose conditions
- Progression systems (how the player grows/advances)

#### 2.3 Game World / Setting
- Theme and aesthetic
- World structure (linear levels, open world, hub-and-spoke, etc.)
- Area/level descriptions with progression logic
- Environmental storytelling elements

#### 2.4 Characters / Entities
- Player character (abilities, stats, progression)
- Enemies (types, behaviors, difficulty scaling)
- NPCs (roles, dialogue, quest-giving)
- Items and collectibles (types, effects, acquisition)
- Each entity needs: visual description, behavior, attributes/stats

#### 2.5 Interface / HUD
- Main menu flow
- In-game HUD elements (health, mana, minimap, inventory)
- Pause menu
- Screen transitions
- Control scheme (keyboard, controller, touch)

#### 2.6 Art Direction
- Visual style (pixel art, low-poly, realistic, etc.)
- Color palette
- Reference images / mood boards
- Sprite sizes and resolution
- Animation requirements (idle, walk, attack, death, etc.)

#### 2.7 Audio
- Music mood per area/situation (exploration, combat, menu, victory, defeat)
- SFX list by category (player actions, enemy actions, environment, UI)
- Voice acting requirements (if any)

#### 2.8 Technical Requirements
- Engine and version
- Target resolution and aspect ratio
- Performance targets (FPS)
- Platform-specific constraints
- Save system requirements

#### 2.9 Asset Requirements
- Complete list of needed sprites/tilesets
- Audio files needed
- Font requirements
- Shader/effect needs

### Genre-Specific Additions

**For RPGs:** Character progression trees, combat formula, equipment system, quest structure, dialogue branching, economy balance.

**For Platformers:** Movement physics (jump height, gravity, acceleration), obstacle types, power-up system, level length targets.

**For Tower Defense:** Tower types with stats, enemy wave design, upgrade paths, economy balance, map layout rules.

**For Puzzle Games:** Puzzle mechanics, difficulty curve, hint system, scoring rules, tutorial sequence.

---

## 3. GDD for AI-Assisted Development

### What an AI Needs That Humans Don't

Traditional GDDs are written for human teams — designers, artists, programmers. An AI agent like Claude Code needs different information emphasis:

1. **Explicit entity definitions with attributes** — A human artist can interpret "a scary goblin." An AI needs: `name: Goblin, hp: 30, damage: 5, speed: 60, behavior: patrol_and_chase, sprite: goblin_16x16.png`

2. **Concrete numbers, not vibes** — "The player moves at a comfortable speed" is useless. "Player speed: 120 pixels/sec, sprint: 180 pixels/sec, acceleration: 0.2s" is actionable.

3. **Architecture decisions upfront** — Scene tree structure, autoload singletons, signal patterns. Without this, the AI will make conflicting architecture choices across sessions.

4. **Scope boundaries as explicit constraints** — "Do NOT implement multiplayer. Do NOT add procedural generation. Maximum 3 enemy types." Prevents the AI from adding impressive but unwanted features.

5. **File/folder conventions** — Where scripts go, how scenes are organized, naming conventions. The AI follows rules perfectly when they're written down.

6. **What NOT to do** — Past mistakes, anti-patterns, forbidden approaches. Mr. Phil Games found that "every minute spent on CLAUDE.md saves ten minutes of correcting AI-generated code."

### The CLAUDE.md + GDD Relationship

Based on Mr. Phil Games' extensive work on "CLAUDE.md for Game Devs" and his agentic game development approach, the recommended architecture is:

```
project-root/
  CLAUDE.md          ← Architecture, conventions, anti-patterns (persistent AI context)
  GDD.md             ← Game design: what to build (the spec)
  .claude/
    agents/          ← Specialized agent configurations
    skills/          ← Reusable workflow templates
```

**CLAUDE.md** = HOW to build (architecture, patterns, rules)
**GDD.md** = WHAT to build (game design, content, requirements)

The CLAUDE.md should reference the GDD: "Read GDD.md for complete game design specifications before implementing any feature."

### Lessons from Real AI Game Dev Projects

#### Lucca Sanwald's RTS Experiment (Claude + Godot)
- Created markdown files documenting the entire game concept as "ground truth"
- Design documents contradicting each other caused early confusion about character movement mechanics
- **Key failure:** Developer "lost complete touch with the underlying code" — cognitive offloading went too far
- **Lesson:** The human must understand the code even if AI writes it. Review and comprehend, don't just accept.

#### Mr. Phil Games' Stellar Throne (Claude + Godot)
- Built CLAUDE.md from day one as AI onboarding document
- Includes 7 sections: Project Overview, Tech Stack, Architecture, Conventions, Game Design Context, Common Tasks, What NOT to Do
- Uses goal-based prompting: "Design and implement a supply depot mechanic" not "write me a function"
- **Lesson:** Treat AI as junior developer — evaluate thinking, not just syntax. Critique and iterate.

#### OpenGameGDD Project
- Modular architecture: each chapter as standalone file for AI to parse independently
- Recommends starting with chapters 3, 4, and 9 (overview, mechanics, technical) for rapid iteration
- Metadata schemas in JSON for machine-readable specifications
- **Lesson:** Modular docs prevent context overload — the AI only needs to load relevant sections.

### Spec-Driven Development (SDD) for Games

The Agent Factory methodology describes three levels:

1. **Spec-First** — Written specifications precede implementation (what we want)
2. **Spec-Anchored** — Specifications guide but don't rigidly constrain (flexible iteration)
3. **Spec-as-Source** — Code regenerates from specifications (most radical, not practical for games)

For game prototypes, **Spec-Anchored** is ideal: the GDD provides clear direction, but gameplay iteration can modify the spec as playtesting reveals what's fun.

**SDD Four-Phase Workflow adapted for games:**
1. **Research** — Gather references, art assets, similar games, technical constraints
2. **Specification** — Write the GDD through interactive interview
3. **Refinement** — Validate completeness, resolve ambiguities, run quality gates
4. **Implementation** — Task-based building with atomic commits, GDD as reference

---

## 4. Interactive GDD Creation Process

### The Interview Approach

Rather than asking the game creator to write a GDD from scratch, the most effective approach is a **structured interview** where the AI asks questions and compiles the answers into a formatted GDD. This works because:

- Most game creators have a vision but struggle to articulate it formally
- Questions surface gaps and contradictions early
- The AI can validate completeness in real-time
- It's faster and more enjoyable than writing a document

### Interview Phases

#### Phase 1: Vision (2-3 minutes)
Establish the big picture before diving into details.

**Questions:**
1. Describe your game in one sentence (the elevator pitch)
2. What existing game is it MOST like? What's different about yours?
3. What genre(s) does it belong to? (RPG, platformer, puzzle, tower defense, etc.)
4. What's the visual style? (pixel art, hand-drawn, low-poly, etc.)
5. What camera perspective? (top-down, side-scroll, isometric, first-person)
6. What's the mood/feeling you want players to have? (tense, relaxed, triumphant, curious)
7. What platform? (PC, web, mobile)

#### Phase 2: Core Mechanics (5-10 minutes)
The heart of the game — what the player DOES.

**Questions:**
8. What does the player do moment-to-moment? (move, fight, build, solve, explore)
9. Describe the core gameplay loop — what cycle repeats throughout the game?
10. How does the player interact with the world? (click, WASD, controller, touch)
11. Is there combat? If yes: real-time or turn-based? Melee, ranged, or both?
12. Is there an inventory system? What can the player carry/use?
13. Is there a dialogue/interaction system with NPCs?
14. Is there crafting, building, or creation mechanics?
15. How does the player progress? (levels, skills, equipment, story progression)
16. What are the win conditions? What are the lose/fail conditions?
17. Is there a health/damage system? How does it work?

#### Phase 3: Game World and Content (5-10 minutes)
What exists in the game — the "nouns."

**Questions:**
18. How is the world structured? (linear levels, open world, hub, procedural)
19. How many distinct areas/levels for the prototype? Describe each briefly.
20. What enemies exist? (list each type with brief description)
21. What NPCs exist? (list each with role — shopkeeper, quest-giver, etc.)
22. What items/collectibles exist? (list types — health potions, keys, coins, etc.)
23. What obstacles/hazards exist in the environment?
24. Is there a story? If yes, summarize the arc (beginning, middle, end)
25. What is the player character? (describe appearance, personality, abilities)

#### Phase 4: Assets and Aesthetics (3-5 minutes)
How it looks and sounds.

**Questions:**
26. What resolution and sprite size? (e.g., 320x180 with 16x16 tiles)
27. Do you have existing art assets or will we need free/placeholder assets?
28. What tileset themes are needed? (grass, cave, dungeon, town, etc.)
29. What character sprites are needed? (player, enemies, NPCs — list animations needed)
30. What UI elements are needed? (health bar, mana bar, inventory panel, minimap)
31. What music mood for each situation? (exploration, combat, menu, boss, victory)
32. What sound effects are critical? (footsteps, attacks, pickups, menu clicks, damage)
33. Any specific font style preference? (pixel font, serif, handwritten)

#### Phase 5: Technical and Scope (3-5 minutes)
Constraints and boundaries.

**Questions:**
34. What engine and version? (Godot 4.x assumed)
35. Target resolution and window size?
36. Does the game need a save system?
37. How long should a playthrough take? (5 min, 30 min, 2 hours)
38. What features are explicitly OUT OF SCOPE for this prototype?
39. What's the definition of "done" — when is the prototype complete?
40. Are there specific asset packs or resources you want to use?

#### Phase 6: Validation
After compiling answers, review with the creator:

- Read back the elevator pitch and core loop — does it feel right?
- Verify entity list is complete — anything missing?
- Confirm scope boundaries — anything to add to "out of scope"?
- Check asset requirements against available resources
- Estimate build time and validate expectations

---

## 5. From GDD to Implementation

### Recommended Build Order for Prototypes

Based on game development best practices, game jam strategies, and Rami Ismail's milestone framework, the recommended implementation sequence for a small prototype is:

#### Step 1: Foundation (Milestone: "Walking Simulator")
- Project setup (resolution, window, main scene)
- Player character movement (the most fundamental mechanic)
- Camera system
- Basic tilemap/level geometry
- **Validation:** Player can move around a basic level

#### Step 2: Core Loop (Milestone: "Minimum Playable")
- Primary mechanic implementation (combat, puzzle-solving, building — whatever the core verb is)
- Basic enemy/obstacle with simple behavior
- Health/damage system (if applicable)
- Win/lose condition
- **Validation:** One complete cycle of the core loop works

#### Step 3: Content (Milestone: "Vertical Slice")
- All enemy types with correct behaviors
- NPC interactions (dialogue, shops)
- Items and inventory (if applicable)
- One complete level with proper layout
- Basic UI/HUD
- **Validation:** One complete level is fully playable start to finish

#### Step 4: Polish (Milestone: "Prototype Complete")
- Remaining levels/areas
- Menu system (title, pause, game over)
- Audio integration (music + SFX)
- Screen transitions
- Save system (if scoped)
- Bug fixing and balancing
- **Validation:** Complete playthrough without crashes or blockers

### Task Breakdown Method

From HacknPlan's solo dev guide:

1. **Start with milestones** — Each milestone is a goal (Alpha, Beta, Release)
2. **Split into high-level tasks** — Major features within each milestone
3. **Break into implementation tasks** — Specific, completable work units
4. **Estimate and prioritize** — Use MoSCoW (Must/Should/Could/Won't)

**Example breakdown for a 2D RPG prototype:**

```
Milestone 1: Walking Simulator
├── Project setup (resolution, main scene, folders)
├── Player scene (sprite, collision, animations)
├── Player movement (8-directional, speed, acceleration)
├── Camera (follow player, boundary clamping)
├── Tilemap (load tileset, paint basic level)
└── Area transitions (scene change, spawn points)

Milestone 2: Combat Ready
├── Attack system (input, hitbox, damage)
├── Enemy scene (sprite, collision, health)
├── Enemy AI (patrol, chase, attack)
├── Health system (player HP, damage, death)
├── HUD (health bar, basic display)
└── Game over screen

Milestone 3: Vertical Slice
├── NPC system (dialogue boxes, interaction)
├── Item pickups (coins, hearts, keys)
├── Inventory (if scoped)
├── Level 1 complete layout
├── Sound effects (attack, damage, pickup)
├── Background music (exploration track)
└── Polish and bug fixes
```

### Keeping the GDD as Living Document

- **Update after each milestone** — Mark completed features, adjust scope as needed
- **Track deviations** — When implementation differs from spec, update the spec
- **Version control the GDD** — It's markdown, commit it alongside code
- **Never add features without updating the GDD first** — Prevents scope creep

---

## 6. Scope Management and Quality Gates

### Scope Management Strategies

Based on Codecks, Wayline, and game jam best practices:

#### MoSCoW Prioritization
- **Must Have** — Core loop, player movement, primary mechanic, win/lose condition
- **Should Have** — All enemy types, NPC interactions, complete UI, audio
- **Could Have** — Polish animations, particle effects, multiple levels, achievements
- **Won't Have** — Multiplayer, procedural generation, mod support, leaderboards

#### The "Won't Have" List is Critical
For AI-assisted development, explicitly stating what NOT to build is even more important than stating what to build. An AI will happily add impressive features that weren't asked for. The GDD must include an explicit "Out of Scope" section.

#### Game Jam Wisdom Applied to Prototyping
Game jams teach ruthless scope management through time pressure:
- Scope to fit the time (a polished small game beats an ambitious broken one)
- Reserve 20% of time for bug fixing and integration
- Lock scope after initial planning — new ideas go in a "future" list
- Prototype the core loop FIRST before adding any content
- If in doubt, cut it

### Quality Gate: Pre-Implementation Checklist

Before writing any code, ALL of the following must be defined:

**Gate 1: Vision Lock**
- [ ] Elevator pitch written and approved
- [ ] Genre and subgenre defined
- [ ] Target platform and resolution specified
- [ ] Art style decided with reference images
- [ ] Core emotion/mood identified

**Gate 2: Mechanics Lock**
- [ ] Core gameplay loop documented
- [ ] All player actions (verbs) listed
- [ ] Win/lose conditions defined
- [ ] Control scheme specified
- [ ] Progression system described (or explicitly "none")

**Gate 3: Content Lock**
- [ ] All entity types listed with attributes (player, enemies, NPCs, items)
- [ ] Level/area count and descriptions provided
- [ ] Story arc documented (or explicitly "no story")
- [ ] Difficulty approach defined

**Gate 4: Asset Lock**
- [ ] Required sprites/tilesets listed
- [ ] Asset source identified (existing packs, create new, placeholder)
- [ ] Audio requirements listed (music tracks, SFX)
- [ ] Font selected

**Gate 5: Scope Lock**
- [ ] "Out of Scope" list documented
- [ ] Target playthrough time defined
- [ ] "Done" criteria written
- [ ] Build order / milestones planned
- [ ] Estimated effort acknowledged

---

## 7. Tools and Format Recommendations

### Format: Markdown + YAML Frontmatter

**Why markdown:**
- Git-friendly (diffable, version controlled)
- Claude Code reads it natively (it's literally what CLAUDE.md is)
- LLMs are trained extensively on markdown (GitHub, docs, etc.)
- Human-readable and writable
- Easy to split into sections (modular files)

**Why YAML frontmatter:**
- Machine-parseable structured data at the top of the file
- Human-readable (unlike JSON)
- Already standard in static sites, Obsidian, Hugo, Jekyll
- Can be extracted programmatically for tooling
- Less verbose than JSON (fewer tokens for AI context)

**Why NOT other formats:**
- **JSON:** Too verbose, hard to read/edit manually, quote-heavy
- **Pure YAML files:** Lose the narrative context that helps AI understand intent
- **Google Docs/Word:** Not git-friendly, no version control, can't be read by Claude Code
- **Notion/Wiki:** External dependency, can't be committed alongside code

### GDD Generator Tools

| Tool | Type | Usefulness for Our Workflow |
|------|------|----------------------------|
| **Ludo.ai** | SaaS, AI-powered | Good for brainstorming and asset generation. GDD features are template-based with AI fill. Not exportable as markdown. Better for mobile/casual games. |
| **GDDMaker.com** | SaaS | Collaborative GDD creation. Browser-based. Not optimized for AI consumption. |
| **Blueprint (Wayline)** | SaaS, AI-powered | Generates detailed GDDs from prompts. Good output quality. Not markdown-native. |
| **ChatGPT GDD Maker GPT** | Custom GPT | Template-based GDD generation. Output is generic markdown. Decent starting point. |
| **Our approach (Claude Code skill)** | Local, interactive | Best for our workflow — interactive interview, markdown output, committed to repo, directly usable as AI context. |

### GitHub GDD Template Repos

| Repository | Stars | Notes |
|-----------|-------|-------|
| [LazyHatGuy/GDDMarkdownTemplate](https://github.com/LazyHatGuy/GDDMarkdownTemplate) | Popular | 13-chapter comprehensive template. Good starting point for full GDDs. |
| [wanghaisheng/opengamegdd](https://github.com/wanghaisheng/opengamegdd) | Growing | Fork of LazyHatGuy, enhanced for AI agents. Modular chapter files. |
| [LordZardeck/gdd-gist](https://gist.github.com/LordZardeck/797143b694ddfeb6ffa63f7bb5d18b9f) | Classic | Single-file markdown GDD with project scope and asset breakdowns. |
| [kosinaz/gdd-template-for-beginners](https://github.com/kosinaz/game-design-document-template-for-beginners) | Beginner | Simplified template with advice and examples. |
| [CiaraBurkett/game-design-document.md](https://github.com/CiaraBurkett/game-design-document.md) | Converted | Google Docs template converted to markdown. |
| [saeidzebardast/game-design-document](https://github.com/saeidzebardast/game-design-document) | Outline | GDD outline, template, and examples. |

---

## 8. Recommended GDD Template for AI-Assisted Prototyping

This is the recommended template for our Claude Code + Godot workflow. It's designed to be:
- **Complete enough** that Claude Code can implement from it without ambiguity
- **Concise enough** to fit in context without wasting tokens
- **Structured** with YAML for machine parsing + markdown for human context
- **Scopeable** with explicit boundaries and "done" criteria

### Template

````markdown
---
# GDD Metadata (YAML frontmatter — machine-parseable)
title: "Game Title"
version: "0.1.0"
status: "draft"  # draft | review | approved | in-progress | complete
genre: "action-rpg"
subgenre: "zelda-like"
perspective: "top-down"
art_style: "pixel-art-16bit"
engine: "godot-4.4"
resolution:
  viewport: "320x180"
  window: "1280x720"
  stretch_mode: "canvas_items"
target_platform: "pc"
target_playtime: "15-20 minutes"
created: "2026-03-08"
updated: "2026-03-08"
---

# [Game Title] — Game Design Document

## 1. Concept

### Elevator Pitch
> [One to two sentences capturing the game's essence. What is it? Why is it fun?]

### Design Pillars
1. **[Pillar 1]** — [Brief explanation of the feeling/experience]
2. **[Pillar 2]** — [Brief explanation]
3. **[Pillar 3]** — [Brief explanation]

### Reference Games
- **[Game 1]** — [What we're borrowing from it]
- **[Game 2]** — [What we're borrowing from it]

---

## 2. Core Mechanics

### Core Loop
```
[Action 1] → [Action 2] → [Reward] → [Progression] → repeat
```
Example: `Explore → Fight Enemies → Collect Loot → Upgrade → Explore Deeper`

### Player Actions (Verbs)
| Action | Input | Description |
|--------|-------|-------------|
| Move | WASD / Arrow keys | 8-directional movement at [X] px/sec |
| Attack | Space / Z | [Melee/ranged], [damage] damage, [cooldown]s cooldown |
| Interact | E / X | Talk to NPCs, open chests, read signs |
| [Other] | [Key] | [Description] |

### Progression System
[How does the player grow? Levels? Equipment? Abilities? Or no progression for a short prototype?]

### Win Condition
[What triggers "you win"?]

### Lose Condition
[What triggers "game over"? Is there permadeath or checkpoints?]

---

## 3. Game World

### World Structure
[Linear levels? Open world? Hub-and-spoke? Describe the overall layout.]

### Areas
| # | Area Name | Theme | Size (tiles) | Enemies | Items | Connections |
|---|-----------|-------|--------------|---------|-------|-------------|
| 1 | [Name] | [grass/cave/town] | [40x30] | [types] | [types] | → Area 2 |
| 2 | [Name] | [theme] | [size] | [types] | [types] | → Area 1, 3 |

### Area Descriptions
#### Area 1: [Name]
[2-3 sentences describing the area, its mood, what happens here, notable landmarks]

---

## 4. Entities

### Player Character
```yaml
name: "[Name]"
sprite: "[filename or description]"
size: "[16x16 / 16x32]"
stats:
  hp: 100
  speed: 120  # pixels/sec
  attack_damage: 10
  attack_range: 24  # pixels
  attack_cooldown: 0.4  # seconds
animations:
  - idle (4 directions)
  - walk (4 directions)
  - attack (4 directions)
  - hurt
  - death
```

### Enemies
```yaml
enemies:
  - name: "[Enemy Type 1]"
    sprite: "[filename or description]"
    size: "[16x16]"
    stats:
      hp: 30
      speed: 60
      damage: 5
      detection_range: 80
      attack_range: 16
    behavior: "patrol_and_chase"  # patrol_and_chase | stationary_shooter | wanderer | boss
    drops:
      - item: "coin"
        chance: 0.5
    animations: [idle, walk, attack, hurt, death]

  - name: "[Enemy Type 2]"
    # ...
```

### NPCs
```yaml
npcs:
  - name: "[NPC Name]"
    role: "shopkeeper"  # shopkeeper | quest_giver | info | decoration
    location: "Area 1"
    sprite: "[filename or description]"
    dialogue:
      - "[First line of dialogue]"
      - "[Second line when interacted again]"
    shop_items:  # only if shopkeeper
      - item: "health_potion"
        price: 10
```

### Items
```yaml
items:
  - name: "Health Potion"
    type: "consumable"  # consumable | equipment | key_item | collectible | currency
    effect: "restore 30 hp"
    sprite: "[filename or description]"

  - name: "Coin"
    type: "currency"
    value: 1
    sprite: "[filename or description]"
```

---

## 5. Interface / HUD

### HUD Elements
| Element | Position | Description |
|---------|----------|-------------|
| Health Bar | Top-left | Red bar showing current/max HP |
| Currency | Top-right | Coin icon + count |
| [Other] | [Position] | [Description] |

### Screens
| Screen | Trigger | Elements |
|--------|---------|----------|
| Title Screen | Game start | Title, "Start Game", "Quit" |
| Pause Menu | Escape key | "Resume", "Quit to Title" |
| Game Over | Player death | "Retry", "Quit to Title" |
| Victory | Win condition met | [Victory message, stats] |
| Dialogue Box | NPC interaction | Speaker name, text, "Next" prompt |

### Control Scheme
| Action | Keyboard | Controller (if applicable) |
|--------|----------|---------------------------|
| Move | WASD / Arrows | Left stick / D-pad |
| Attack | Space / Z | A / X |
| Interact | E / X | B / Y |
| Pause | Escape | Start |

---

## 6. Audio

### Music
| Situation | Mood | Loop? | Reference |
|-----------|------|-------|-----------|
| Title Screen | [mood] | Yes | [optional reference track] |
| Exploration | [mood] | Yes | |
| Combat | [mood] | Yes | |
| Boss | [mood] | Yes | |
| Victory | [mood] | No | |
| Game Over | [mood] | No | |

### Sound Effects
| Category | Sound | Trigger |
|----------|-------|---------|
| Player | Footstep | Walking (every X frames) |
| Player | Attack swing | Attack action |
| Player | Damage taken | Player hit |
| Player | Death | HP reaches 0 |
| Enemy | Damage taken | Enemy hit |
| Enemy | Death | Enemy HP reaches 0 |
| Item | Pickup | Player collects item |
| UI | Menu select | Navigating menu |
| UI | Menu confirm | Selecting option |
| Environment | Door open | Area transition |

---

## 7. Art Assets

### Required Tilesets
| Tileset | Tile Size | Theme | Source |
|---------|-----------|-------|--------|
| [Name] | 16x16 | [grass/stone/dungeon] | [asset pack name or "create"] |

### Required Sprites
| Sprite | Size | Animations | Source |
|--------|------|------------|--------|
| Player | [16x32] | idle, walk, attack, hurt, death (4-dir) | [source] |
| [Enemy 1] | [16x16] | idle, walk, attack, death | [source] |
| [NPC 1] | [16x16] | idle | [source] |
| [Items] | [16x16] | [static / animated] | [source] |

### UI Assets
| Asset | Description | Source |
|-------|-------------|--------|
| Health bar | [style description] | [source or "create"] |
| Dialogue box | [style description] | [source or "create"] |
| Font | [pixel font / specific name] | [source] |

---

## 8. Technical Architecture

### Godot Project Structure
```
project-root/
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── ui/
├── scenes/
│   ├── characters/
│   │   ├── player.tscn
│   │   └── enemies/
│   ├── levels/
│   ├── ui/
│   └── main.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd
│   │   └── audio_manager.gd
│   ├── characters/
│   ├── ui/
│   └── resources/
└── resources/
    └── [.tres files for data]
```

### Autoload Singletons
| Singleton | Purpose |
|-----------|---------|
| GameManager | Game state, scene transitions, save/load |
| AudioManager | Music and SFX playback |
| [Others as needed] | |

### Key Design Patterns
- [State machine for player/enemy states]
- [Signal-based communication between systems]
- [Resource-based data definitions for items/enemies]

---

## 9. Scope

### In Scope (Must Have for Prototype)
- [ ] [Feature 1]
- [ ] [Feature 2]
- [ ] [Feature 3]
- [ ] ...

### Should Have (If Time Permits)
- [ ] [Feature A]
- [ ] [Feature B]

### Out of Scope (Explicitly NOT Building)
- ❌ [Feature X — reason]
- ❌ [Feature Y — reason]
- ❌ [Feature Z — reason]

### Done Criteria
The prototype is COMPLETE when:
1. [Criterion 1 — e.g., "Player can complete all areas from start to victory screen"]
2. [Criterion 2 — e.g., "All 3 enemy types are functional with correct behavior"]
3. [Criterion 3 — e.g., "No crash bugs during normal gameplay"]
4. [Criterion 4 — e.g., "Music and SFX play in all required situations"]

---

## 10. Build Plan

### Milestones
| # | Milestone | Key Deliverables | Target |
|---|-----------|-----------------|--------|
| 1 | Walking Simulator | Player movement, camera, basic tilemap | [date/session] |
| 2 | Core Loop | Primary mechanic, 1 enemy, health, win/lose | [date/session] |
| 3 | Vertical Slice | All enemies, NPCs, items, 1 complete level | [date/session] |
| 4 | Prototype Complete | All levels, UI, audio, polish | [date/session] |

### Implementation Notes
[Any specific technical decisions, libraries, or approaches to use]
````

---

## 9. Interview Questions for GDD Creation

### Quick Reference: Complete Question Set

These questions are designed for an interactive session where Claude Code asks the game creator and compiles answers into the GDD template above.

#### Vision (7 questions)
1. Describe your game in one sentence
2. What existing game is it most like? What's different?
3. Genre(s)?
4. Visual style?
5. Camera perspective?
6. Target mood/feeling?
7. Target platform?

#### Core Mechanics (10 questions)
8. What does the player do moment-to-moment?
9. Describe the core gameplay loop
10. How does the player interact? (controls)
11. Is there combat? Real-time or turn-based?
12. Is there an inventory system?
13. Is there dialogue/NPC interaction?
14. Is there crafting/building?
15. How does the player progress?
16. Win conditions?
17. Lose/fail conditions?

#### Game World (8 questions)
18. World structure? (linear, open, hub)
19. How many areas/levels? Brief descriptions?
20. What enemies exist?
21. What NPCs exist?
22. What items/collectibles?
23. What obstacles/hazards?
24. Is there a story? Summarize the arc
25. Describe the player character

#### Assets (8 questions)
26. Resolution and sprite size?
27. Existing art assets or need to find/create?
28. Tileset themes needed?
29. Character sprites needed?
30. UI elements needed?
31. Music moods per situation?
32. Critical sound effects?
33. Font preference?

#### Technical and Scope (7 questions)
34. Engine and version?
35. Target resolution/window size?
36. Need a save system?
37. Target playthrough time?
38. What's explicitly OUT of scope?
39. Definition of "done"?
40. Specific asset packs to use?

### Adaptive Follow-Up Questions

Based on genre, ask additional targeted questions:

**If RPG/Adventure:**
- What's the combat formula? (damage = attack - defense? Or simpler?)
- How does leveling work? What stats increase?
- Is there equipment? What slots?
- Quest structure? (main quest, side quests, fetch quests)
- Economy balance? (how much do items cost vs. how fast players earn?)

**If Platformer:**
- Jump height in tiles?
- Can the player double-jump/wall-jump?
- What hazards? (spikes, pits, moving platforms)
- Collectibles? (coins, stars, hidden items)
- Level completion criteria? (reach end, collect all, time limit)

**If Tower Defense:**
- What tower types? (damage, slow, splash, special)
- How many upgrade tiers per tower?
- Wave design philosophy? (increasing count, speed, or enemy variety?)
- Economy per wave? (fixed income, kill-based, passive)
- Creep path? (fixed, open, or semi-open)

**If Puzzle:**
- Core puzzle mechanic? (match-3, sokoban, logic, physics)
- How many puzzles for the prototype?
- Is there a hint system?
- Difficulty curve? (linear, spikes, adaptive)
- Timer/scoring? (or pure completion)

---

## 10. Quality Gate Checklist

### Pre-Implementation Quality Gate

Before ANY code is written, verify ALL items below are resolved:

#### Gate 1: Vision Lock ✅
- [ ] Elevator pitch exists (1-2 sentences)
- [ ] Genre and subgenre are named
- [ ] Platform and target resolution are specified
- [ ] Art style is decided with at least one reference image
- [ ] 3 design pillars are written
- [ ] Camera perspective is chosen

#### Gate 2: Mechanics Lock ✅
- [ ] Core loop is documented as a cycle diagram
- [ ] All player actions have input mappings
- [ ] Win condition is concrete and testable
- [ ] Lose condition is concrete and testable
- [ ] Progression system is described (or explicitly "none for prototype")
- [ ] Combat system is specified with numbers (damage, HP, cooldowns)

#### Gate 3: Content Lock ✅
- [ ] Player character is defined with stats and animation list
- [ ] ALL enemy types are listed with stats and behavior descriptions
- [ ] ALL NPC types are listed with roles and key dialogue
- [ ] ALL item types are listed with effects
- [ ] ALL areas/levels are listed with descriptions and connections
- [ ] Story arc is summarized (or explicitly "no story")

#### Gate 4: Asset Lock ✅
- [ ] Required tilesets are listed with sources identified
- [ ] Required sprite sheets are listed with sources identified
- [ ] UI elements are listed
- [ ] Music requirements are listed by situation
- [ ] SFX requirements are listed by trigger
- [ ] Font is selected
- [ ] All "source TBD" items have a plan (create, find free, buy)

#### Gate 5: Architecture Lock ✅
- [ ] Project folder structure is defined
- [ ] Autoload singletons are listed with responsibilities
- [ ] Scene tree patterns are decided (composition over inheritance, etc.)
- [ ] Key design patterns are documented (state machines, signals, etc.)
- [ ] CLAUDE.md references the GDD

#### Gate 6: Scope Lock ✅
- [ ] "In Scope" checklist exists with all must-have features
- [ ] "Out of Scope" list exists with at least 5 explicit exclusions
- [ ] "Done" criteria are written as testable statements
- [ ] Build milestones are defined with deliverables
- [ ] Target playthrough time is realistic for scope
- [ ] MoSCoW prioritization is applied to all features

### Per-Milestone Quality Gate

Before starting each new milestone:

- [ ] Previous milestone's deliverables are all working
- [ ] GDD is updated to reflect any deviations
- [ ] No new features were added without GDD approval
- [ ] Known bugs are documented (fix now vs. fix later)

---

## 11. References and Resources

### GDD Templates and Guides

- [Indie Game Academy — Free GDD Template](https://indiegameacademy.com/free-game-design-document-template-how-to-guide/)
- [Nuclino — GDD Template and Examples](https://www.nuclino.com/articles/game-design-document-template)
- [Gamedeveloper.com — GDD Template for the Indie Developer (Jason Bakker)](https://www.gamedeveloper.com/design/a-gdd-template-for-the-indie-developer)
- [Gamedeveloper.com — How to Write a GDD (2024)](https://www.gamedeveloper.com/design/how-to-write-a-game-design-document)
- [Tom Sloper — Sample GDD Outline](https://www.sloperama.com/advice/specs.html)
- [Game Dev Beginner — How to Write a GDD](https://gamedevbeginner.com/how-to-write-a-game-design-document-with-examples/)
- [Whimsy Games — Complete GDD Guide](https://whimsygames.co/blog/game-design-instructions-examples/)
- [Document360 — GDD Steps & Best Practices](https://document360.com/blog/write-game-design-document/)

### GitHub GDD Markdown Templates

- [LazyHatGuy/GDDMarkdownTemplate](https://github.com/LazyHatGuy/GDDMarkdownTemplate) — 13-chapter comprehensive template
- [wanghaisheng/opengamegdd](https://github.com/wanghaisheng/opengamegdd) — AI-agent-optimized GDD template
- [LordZardeck — GDD Markdown Gist](https://gist.github.com/LordZardeck/797143b694ddfeb6ffa63f7bb5d18b9f) — Single-file GDD template
- [kosinaz — GDD Template for Beginners](https://github.com/kosinaz/game-design-document-template-for-beginners)
- [CiaraBurkett — game-design-document.md](https://github.com/CiaraBurkett/game-design-document.md)

### AI-Assisted Game Development

- [Mr. Phil Games — CLAUDE.md for Game Devs](https://www.mrphilgames.com/blog/claude-md-for-game-devs)
- [Mr. Phil Games — Agentic Game Development](https://www.mrphilgames.com/newsletter/agentic-game-development)
- [Mr. Phil Games — How I Use Claude Like a Junior Dev](https://www.mrphilgames.com/newsletter/how-i-use-claude-like-a-junior-dev)
- [DEV Community — Building an RTS in Godot with Claude](https://dev.to/datadeer/part-1-building-an-rts-in-godot-what-if-claude-writes-all-code-49f9)
- [Agent Factory — Spec-Driven Development with Claude Code](https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development)
- [VoltAgent — Game Developer Subagent](https://github.com/VoltAgent/awesome-claude-code-subagents/blob/main/categories/07-specialized-domains/game-developer.md)
- [arXiv — Automated Unity Game Template Generation from GDDs via NLP and LLMs](https://arxiv.org/html/2509.08847)

### Scope Management

- [Codecks — How to Avoid Scope Creep in Game Development](https://www.codecks.io/blog/2025/how-to-avoid-scope-creep-in-game-development/)
- [Wayline — Scope Creep in Indie Games](https://www.wayline.io/blog/scope-creep-indie-games-avoiding-development-hell)
- [Codecks — Rethinking Agile in Game Development](https://www.codecks.io/blog/rethinking-agile-in-game-development/)

### Game Development Methodology

- [Rami Ismail — Prototypes & Vertical Slice](https://ltpf.ramiismail.com/prototypes-and-vertical-slice/)
- [Rami Ismail — Milestones](https://ltpf.ramiismail.com/milestones/)
- [HacknPlan — Project Planning for Solo Game Developers](https://hacknplan.com/project-planning-for-solo-game-developers/)
- [HacknPlan — Understanding Vertical Slicing](https://hacknplan.com/understanding-vertical-slicing/)

### Game Jam Resources

- [Jenn Sandercock — How to Get Everything Done in a Game Jam](https://jennsand.com/advice/road-jam-map/)
- [Better Programming — 10 Game Jam Strategies](https://betterprogramming.pub/10-game-jam-strategies-92c88c81f834)
- [Wayline — Game Jam Survival Guide](https://www.wayline.io/blog/game-jam-survival-guide)
- [Gamedeveloper.com — Game Jams: An Agile-ish Approach](https://www.gamedeveloper.com/production/game-jams-an-agil-ish-approach)

### GDD Generator Tools

- [Ludo.ai](https://ludo.ai/) — AI-powered game design platform with GDD integration
- [Blueprint by Wayline](https://www.wayline.io/nextframe/blueprint) — AI GDD generator
- [GDDMaker.com](https://gddmaker.com/) — Collaborative GDD creation
- [ChatGPT GDD Maker GPT](https://chatgpt.com/g/g-ITsZga7Ed-game-design-document-gdd-maker) — Custom GPT for GDD creation

### Audio Design for Games

- [Thiago Schiefer — Documentation and Organization in Game Audio](https://thiagoschiefer.com/home/documentation-and-organization-in-game-audio-with-templates/)
- [A Sound Effect — How to Write an Audio Design Document](https://www.asoundeffect.com/game-audio-design-document/)
- [Gamescrye — 7 Sound Design Elements for Your GDD](https://gamescrye.com/blog/7-sound-design-elements-to-include-in-gdd/)

### Godot + AI Integration

- [Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp) — MCP server for Godot
- [ee0pdt/Godot-MCP](https://github.com/ee0pdt/Godot-MCP) — MCP for Godot with Claude
- [FastMCP — Godot Claude Code Skill](https://fastmcp.me/skills/details/235/godot)
- [Godot AI Suite (itch.io)](https://marcengelgamedevelopment.itch.io/godot-ai-suite)

---

## Key Takeaways for Our Workflow

1. **The GDD is the spec, CLAUDE.md is the rules.** Keep them separate but cross-referenced. GDD says WHAT, CLAUDE.md says HOW.

2. **Use YAML frontmatter + markdown.** Best of both worlds for human readability and AI parsing.

3. **Entities need concrete numbers.** HP, speed, damage, drop rates — if it's not a number, Claude will invent one. Better to decide upfront.

4. **The "Out of Scope" section is as important as "In Scope."** Prevents AI from adding unwanted features. Be explicit and generous with exclusions.

5. **Build in milestone order.** Walking Simulator → Core Loop → Vertical Slice → Prototype Complete. Validate at each gate.

6. **Interactive interview > blank template.** The GDD creation skill should ASK questions, not hand the user an empty template.

7. **Keep it short.** 3-8 pages is the sweet spot. Longer than 8 pages and the AI starts losing context; shorter than 3 and critical details are missing.

8. **Version control the GDD alongside code.** It's markdown — commit it. Track deviations. The GDD is a living document.

9. **Reserve 20% for polish and bugs.** Game jam wisdom applies to prototyping too. Scope for 80% of available time.

10. **The human must understand the code.** Lucca Sanwald's lesson — review and comprehend what the AI writes. Don't just accept. The GDD doesn't replace game development knowledge; it structures it.
