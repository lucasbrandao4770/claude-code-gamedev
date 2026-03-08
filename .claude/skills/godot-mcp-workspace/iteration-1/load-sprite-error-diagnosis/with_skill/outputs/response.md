# Diagnosis: "No loader found for resource" on `load_sprite`

## Root Cause

The PNG file exists on disk, but Godot does not know about it yet. Godot requires an **import step** before any file on disk becomes a usable resource. Until that import runs, the engine has no registered loader for the file, which is exactly what the error message is telling you.

This is the single most common `load_sprite` failure when using the Godot MCP.

## The Fix

Run the headless import **before** calling `load_sprite`:

```bash
godot --headless --path <your-project-folder> --import
```

For example, if your project is at `D:/Workspace/Games/my-project`:

```bash
"D:/Games/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --path "D:/Workspace/Games/my-project" --import
```

This tells Godot to scan the project directory, detect new asset files (PNGs, WAVs, fonts, etc.), and generate the corresponding `.import` sidecar files. After this completes, you will see a file like `assets/sprites/player/idle.png.import` appear next to your PNG.

Once the import finishes, retry the `load_sprite` call:

```
load_sprite(
  projectPath="D:/Workspace/Games/my-project",
  scenePath="res://scenes/player/player.tscn",
  nodePath="root/Sprite2D",
  texturePath="res://assets/sprites/player/idle.png"
)
```

## Why This Happens

The Godot MCP's `load_sprite` tool works by telling the Godot engine to load a resource at a `res://` path. Godot's resource system only recognizes files that have been imported -- raw files on disk without a matching `.import` file are invisible to the engine. The MCP cannot perform this import step on its own.

## The Correct Workflow Order

Always follow this sequence when adding new assets:

1. Place asset files into your project folder (e.g., copy PNGs into `assets/sprites/`)
2. Run `godot --headless --path <project> --import`
3. **Then** call `load_sprite` via MCP

This applies every time you add **any** new asset file -- not just the first time. If you later add more sprites, audio files, or fonts, you need to run the headless import again before using them through MCP.

## Quick Checklist If It Still Fails

- **Verify the `texturePath` uses `res://` prefix**: it should be `res://assets/sprites/player/idle.png`, not an absolute filesystem path.
- **Verify the file path casing matches exactly**: Godot on Windows can be case-sensitive for resource paths depending on how the import was registered.
- **Check that the `.import` file was generated**: look for `assets/sprites/player/idle.png.import` in your project folder after running the headless import. If it is missing, the import did not pick up the file (double-check that `project.godot` exists in the root of the path you passed to `--path`).
- **Verify the Sprite2D node exists**: `load_sprite` assigns a texture to an existing node. The node at `nodePath` must already exist in the scene (created via `add_node` beforehand).
