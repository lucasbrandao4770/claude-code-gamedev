# Forge of Worlds v2 — Game Design Document

## Elevator Pitch
A 16-bit top-down action RPG where a lone swordsman explores a green field, battles slimes with sword combat, and fights to survive. Think "first 5 minutes of A Link to the Past" as a standalone experience.

## Core Loop
```
Move → Find Enemy → Fight (sword) → Take/Deal Damage → Survive → Repeat
```

## Reference Games
- **The Legend of Zelda: A Link to the Past** — top-down combat feel, sword slash arc
- **Graal Online** — simple overworld exploration, direct combat
- **early Dragon Quest** — field encounters, HP management

## Design Pillars
1. **Responsive Combat** — Attacks connect instantly, enemies react with knockback, damage feels impactful
2. **Retro Nostalgia** — 16-bit pixel art, chiptune music, SNES/GBA aesthetic
3. **Accessible Simplicity** — No menus, no inventory. Move and fight. Anyone can play in 10 seconds.

## Scope

### MUST HAVE
1. Player with 4-directional movement (walk/idle animations)
2. Sword attack in facing direction with visible hitbox
3. Slime enemies: wander + chase player when in range + contact damage
4. Health system for player and enemies (HP)
5. Damage with knockback and invincibility frames (blink effect)
6. Enemy death animation, player death → restart
7. One map: green field with boundaries (ColorRect or TileMapLayer)
8. Camera following player
9. HUD: hearts display
10. Background music + sound effects

### SHOULD HAVE
- Heart pickups (restore HP)
- NPC with dialogue box

### EXPLICITLY OUT OF SCOPE
- Inventory, equipment, drops
- Multiple maps, room transitions
- Save/load, menus
- Jump mechanic
- Multiple enemy types (only Slime1)

## Art Style
- **Sprite size:** 64x64 pixels
- **Perspective:** Top-down, 4-directional
- **Palette:** CraftPix "Swordsman" + "Slime" packs (With_shadow variants)
- **Viewport:** 320x180, scaled 4x to 1280x720
- **Filter:** Nearest (crisp pixels)

## Audio
- **Music:** xDeviruchi chiptune tracks (.wav)
- **SFX:** Kenney RPG Audio (.ogg) — sword slash, hit, footsteps
