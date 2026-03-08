# Discovery Interview & Quality Gate

This reference defines the structured interview process for Phase 1 and the quality gate that must pass before moving to Phase 2.

## The Discovery Interview

Run this interview at the START of every new game project. Ask questions conversationally, not as a rigid form. Group related questions. Skip questions the user already answered. The goal is to extract enough information to write a complete GDD.

### Round 1: Vision (what's the dream?)

1. **What kind of game do you want to make?** Genre, perspective, art style. If they're unsure, offer examples: "top-down RPG like Zelda? Side-scrolling platformer like Celeste? Tower defense like Kingdom Rush?"
2. **What's the elevator pitch?** One or two sentences. If they struggle, try the formula: "[Game A] meets [Game B]" or "You are a [role] who must [goal] by [action]."
3. **What 2-3 games inspire you?** And specifically WHAT from those games — not the whole game, but specific mechanics or feelings.
4. **What should it FEEL like to play?** Fast and frantic? Zen and relaxing? Tense and strategic? This shapes every design decision.

### Round 2: Mechanics (what does the player DO?)

5. **What's the core mechanic — the ONE thing that must feel fun?** If everything else is stripped away, what's the core action? Swinging a sword? Jumping between platforms? Placing towers? Matching blocks?
6. **How does the player move?** 4-directional, 8-directional, side-scrolling, point-and-click, grid-based?
7. **What are the player's actions beyond movement?** Attack, jump, interact, build, cast spells? List them ALL.
8. **What challenges does the player face?** Enemies, puzzles, time pressure, resource scarcity, platforming?
9. **How does the player win?** Defeat a boss? Reach a goal? Survive N waves? Solve all puzzles? Score-based?
10. **How does the player lose?** HP reaches 0? Timer runs out? Enemies reach the base? No lose condition?

### Round 3: Content (what's in the world?)

11. **Describe the player character** — What do they look like? What's their name? Knight, wizard, robot, animal?
12. **What enemies or obstacles exist?** Types, behaviors, difficulty. At least describe the basic enemy.
13. **What's the setting?** Forest, dungeon, city, space? One sentence is enough.
14. **What items or pickups exist?** Health, coins, keys, power-ups? Or none?

### Round 4: Scope & Constraints

15. **How much time do we have?** One session? Multiple sessions? A specific deadline?
16. **What's explicitly OUT of scope?** Features that might seem obvious but we're NOT building. (Inventory? Multiplayer? Save/load? Menus?)
17. **Any technical constraints?** Specific Godot version, target platform, performance concerns?
18. **Do you have assets already, or do we need to find them?** Pre-downloaded packs, specific style requirements?

### Round 5: Feel & Polish

19. **Music style?** Chiptune, orchestral, ambient, electronic? Or no strong preference?
20. **How important is visual polish vs. mechanical depth?** Some people want a beautiful prototype with simple mechanics; others want deep gameplay with programmer art.

## After the Interview

1. **Summarize the answers back to the user** — "Here's what I understood: [summary]. Does this sound right?"
2. **Draft the GDD** — Use the one-pager template from `references/gdd-guide.md`. Fill in ALL sections with concrete values from the interview.
3. **Present the GDD to the user for review** — "Here's the game design document. Please review it. Should I change anything?"
4. **Iterate until the user approves** — The GDD is a contract. Both sides must agree before building starts.

## Quality Gate

**DO NOT proceed to Phase 2 until ALL of these are true.** If any item fails, go back and fill the gap with the user.

### Gate 1: GDD Completeness

- [ ] **Elevator pitch** exists and is specific (not "a fun game")
- [ ] **Design pillars** — at least 2, each with a concrete explanation
- [ ] **Core loop** is defined with action → challenge → reward
- [ ] **Player character** has: movement type, speed (number), actions, HP (number), damage (number)
- [ ] **At least one enemy type** has: behavior, HP (number), damage (number), detection range (number)
- [ ] **Win condition** is defined
- [ ] **Lose condition** is defined
- [ ] **Art style** is defined with sprite size and perspective
- [ ] **Scope tiers** exist: MUST HAVE (5-8 items), SHOULD HAVE, OUT OF SCOPE

### Gate 2: Implementation Readiness

- [ ] **All mechanic values are NUMBERS, not adjectives** — "speed: 150px/s" not "fast"
- [ ] **Collision layers are assigned** with both layer numbers and bitmask values
- [ ] **No contradictions** between GDD sections
- [ ] **CLAUDE.md is drafted** with file structure, conventions, and anti-patterns

### Gate 3: Asset Readiness

- [ ] **Asset requirements are listed** — characters, enemies, tilesets, UI, audio
- [ ] **Asset sources are identified** — specific packs, URLs, or "need to search"
- [ ] **Art style is consistent** — all assets work together visually (same pixel size, same palette family)

## Common Interview Pitfalls

- **User says "I want to make a game like Zelda"** — Too vague. Ask: "Which Zelda? What specific part? The combat? The dungeons? The exploration? The art style?"
- **User can't decide on scope** — Suggest the smallest version: "What if we just do the ONE core mechanic and test if it's fun? We can always add more."
- **User wants everything** — Gently redirect: "Those are all great ideas. Let's put 5 in MUST HAVE and move the rest to SHOULD HAVE or NOT YET."
- **User gives vague descriptions** — Push for numbers: "When you say 'a tough enemy', how much HP? How much damage? What's the player's HP for comparison?"
- **User says "you decide"** — Offer 2-3 options with tradeoffs: "Option A: [tradeoff]. Option B: [tradeoff]. Which feels more fun to you?"
