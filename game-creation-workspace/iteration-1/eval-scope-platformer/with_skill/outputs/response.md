# Scoping Your Pixel Art Platformer

Welcome to game dev! Your background as a data engineer is actually a superpower here -- you already understand state machines, event-driven systems, and tight loops. Let me translate what you're describing into a buildable plan.

## First, Some Game Dev Framing

A game is basically a real-time stream processor running at 60 events/second. Every frame: read input, update state, render. Everything your player character does -- running, jumping, dying -- is a state machine (`enum + match`), exactly like a workflow engine. Collision detection works like security group rules: each object has a "layer" (what am I?) and a "mask" (what do I detect?). You already know these patterns; they just have different names here.

The most important concept: **the core loop**. For a platformer, it's:

```
Run --> Jump --> Land --> (repeat)
```

That's it at the moment-to-moment level. If that loop isn't fun, no amount of bosses or leaderboards will fix it. This is like optimizing the critical path in a data pipeline -- if the critical path has bad latency, optimizing side paths doesn't help.

## Your Feature List, Sorted Honestly

Here's your idea list, organized by what actually makes a playable prototype vs. what's scope creep for a first session:

### MUST HAVE (the prototype is incomplete without these)
1. **Player movement** -- Run left/right with acceleration and deceleration (not instant stop)
2. **Gravity + jump** -- With "coyote time" (can jump briefly after walking off a ledge) and "jump buffering" (press jump slightly before landing, it still works). These two invisible tricks are why Mario feels good and amateur platformers feel bad.
3. **Variable jump height** -- Hold the button = jump higher, tap = short hop. This is table stakes for a platformer.
4. **Platforms and ground** -- StaticBody2D tiles the player can walk on and jump between
5. **One enemy type** -- A simple patrol enemy (walks back and forth on a platform). Player dies on side contact, kills it by stomping from above (Area2D hitbox/hurtbox pattern -- never body-to-body collision for damage).
6. **Death and respawn** -- Player falls off screen or touches enemy = respawn at checkpoint
7. **One level** -- A hand-designed level that teaches the player to run, jump, avoid the enemy, and reach a goal
8. **Goal/win condition** -- Reach the end of the level (an Area2D trigger)

### SHOULD HAVE (add only after everything above works)
- Collectible coins (Area2D pickups with a counter on the HUD)
- Basic HUD (coin count, lives remaining)
- Background music + jump/death/coin sound effects (audio transforms a prototype from "homework assignment" to "game" -- it takes 15 minutes)
- One-way platforms (can jump up through them, land on top)

### EXPLICITLY OUT OF SCOPE (not for this session)
- **Wall jumping** -- Requires reworking the entire physics feel; save for session 2
- **Double jump** -- Same reason; changes the level design requirements
- **Bosses** -- A boss is an entire game system (phases, patterns, health bar). Way too much for session 1.
- **Power-ups** -- Each power-up is a new state in the player state machine. Complexity explodes.
- **Level editor** -- This is a full application, not a game feature. Months of work.
- **Online leaderboards** -- Networking, auth, backend, database. You could build this in your sleep as a data engineer, but it has nothing to do with making the game fun.
- **Multiple levels** -- One great level beats five mediocre ones. Nail the feel first.

## Why This Scope Works

Your MUST HAVE list gives you a **complete core loop**:

```
Run --> Jump over gap --> Avoid enemy --> Reach goal --> Win!
```

That's a real game. A short one, sure, but a complete experience with challenge, action, and reward. More importantly, it validates whether YOUR platformer feels fun to play. If it does, session 2 can add wall jumping, double jump, and more levels on a solid foundation. If it doesn't, you'll know before wasting time on leaderboards.

## What the Build Looks Like

We have a platformer template ready to go with pre-configured collision layers, input maps, and asset source links. The build order would be:

1. **Player** -- CharacterBody2D with gravity, run, jump. Test it. Is it fun to move around? (This is "finding the fun.")
2. **Platforms/World** -- StaticBody2D ground and platforms. Test jumping between them.
3. **Enemy** -- Simple patrol walker. Test stomping it and dying to it.
4. **Level** -- Hand-place platforms and enemies into one level with a start and end.
5. **Polish** -- Death animation, respawn, win trigger, and audio.

Each step gets tested before moving to the next. In the first prototype I built with this workflow, testing after each entity caught direction-mapping bugs early that would have cascaded into every subsequent piece.

## Suggested Game Name

Every project needs a name -- even a working title creates momentum and makes the session more fun. Some options for a pixel platformer:

- **Pixel Leap** -- simple, says what it is
- **First Jump** -- meta, since it's your first game
- **Dash & Drop** -- action-oriented

Pick one (or make up your own) and we'll roll with it.

## Next Steps

When you're ready, say the word and we'll:
1. Write a one-pager GDD with the scope above locked in
2. Set up the project from the platformer template
3. Source free pixel art assets (the template has curated links to Kenney, CraftPix, and itch.io packs)
4. Start building -- player movement first

The whole thing should take one focused session. Scope is sacred -- if it's not on the MUST HAVE list, it doesn't get built until everything else works.
