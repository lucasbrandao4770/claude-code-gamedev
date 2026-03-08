# Scoping Your First Platformer

Great instinct asking this before diving in. Feature creep is the number one killer of first game projects, and your list already has enough scope for a commercial release. Let's cut it down to something you can actually finish in one session (roughly 2-4 hours).

## The Core Principle: One Mechanic, One Level, One Goal

A platformer only needs three things to feel like a game:

1. A character that moves and jumps
2. Platforms to jump between
3. A reason to reach the end

Everything else is polish. And polish comes after "it works."

## Your One-Session Scope: "First Jump"

Here is exactly what we would build:

### Must Have (the prototype)

| Feature | Why it makes the cut |
|---|---|
| Player with left/right movement + single jump | This is the genre. Without it, there is no platformer. |
| Gravity and ground collision | Physics make jumping feel real. |
| 3-5 static platforms (TileMap or StaticBody2D) | Enough to create a challenge without needing a level editor. |
| A goal/finish zone (Area2D) | Gives the player a reason to move right.触reaching it shows "You Win!" |
| Camera that follows the player | Without this, the player walks off-screen. |
| One hazard: bottomless pit (KillZone) | Falling = reset to start. Creates stakes with zero AI code. |

That is 6 items. Each one maps to a clear Godot scene or node. No enemy AI, no inventory system, no networking.

### What Gets Cut and Why

| Feature | Verdict | Reason |
|---|---|---|
| Double jump | CUT | Single jump is not even working yet. Add after prototype works. |
| Wall jumping | CUT | Requires wall detection, state machine changes. Session 2 material. |
| Enemies | CUT | AI patrol/chase logic is a whole system. Replace with static hazards (spikes, pits). |
| Bosses | CUT | You need enemies working before you can make a special one. |
| Power-ups | CUT | Requires pickup system + player state changes. Not needed for "is this fun?" |
| Collectibles | MAYBE (session 2) | Simple Area2D + counter, but it is not core. Skip for now. |
| Level editor | CUT | You do not have a game to edit levels for yet. |
| Online leaderboards | CUT | Networking is a project unto itself. Not a platformer problem. |

### The Build Order

This is the sequence we would follow with Claude Code + Godot MCP:

```
1. Project setup (project.godot with pixel art settings, input map)
2. Player scene: CharacterBody2D + Sprite2D + CollisionShape2D
3. Player script: move_and_slide(), gravity, jump on is_on_floor()
4. World scene: TileMap or StaticBody2D platforms, background color
5. Camera2D on the player, set limits
6. KillZone (Area2D at the bottom) -> respawn player at start
7. Goal zone (Area2D at the end) -> show "You Win" label
8. Playtest and tweak jump height / gravity / speed until it feels good
```

Step 8 is where the fun is. Tuning `jump_velocity`, `gravity`, and `speed` until the jump arc feels right is what separates a good platformer from a bad one. You want to spend time here, not debugging a leaderboard API.

## After the Session: Your Expansion Roadmap

Once the prototype works and feels good, here is the order I would add features in future sessions:

1. **Spikes/hazards** (static Area2D, same pattern as KillZone)
2. **Collectibles** (coins with a counter on HUD)
3. **Double jump** (add a jump counter to the player script)
4. **One simple enemy** (patrol between two points, damage on touch)
5. **Multiple levels** (scene transitions)
6. **Wall jump** (wall detection + state changes)
7. **Power-ups** (requires an inventory/state system)
8. **Bosses** (requires enemy system + health + patterns)
9. **Level editor** (requires serialization, UI framework)
10. **Online leaderboards** (requires backend, auth, networking)

Notice how each item builds on the one before it. You cannot skip ahead without creating a mess.

## Ready to Start?

If this scope sounds right, we can start building. I will set up the project, create the player scene with movement and jumping, lay out some platforms, and get you to a playable prototype. The whole thing will be about 5-7 scenes and scripts.

One session. One level. One jump that feels good. That is the goal.
