# Diagnosing "No loader found for resource" with `load_sprite`

The error **"No loader found for resource"** means Godot cannot find the **imported** version of your PNG file. The raw PNG exists on disk, but Godot has not yet processed it into its internal resource format. Here is the most likely cause and how to fix it, along with other things to check.

---

## Most Likely Cause: Missing Import Step

When you add a new asset file (PNG, WAV, etc.) to a Godot project, Godot must **import** it before it can be used as a resource. The Godot editor does this automatically when it is open and detects new files, but when working via MCP (headless, without the editor open), this import does not happen on its own.

**Fix:** Run the headless import command before calling `load_sprite`:

```bash
godot --headless --import
```

Or with the full Steam path if that is how Godot is installed:

```bash
"D:/Games/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe" --headless --import
```

This tells Godot to scan the project for new or changed assets and generate the corresponding `.import` sidecar files and the binary resources in the `.godot/imported/` directory. After this completes, `load_sprite` should work.

---

## Other Things to Check

### 1. Incorrect Path Format

The MCP `load_sprite` tool expects a **`res://` path**, not a filesystem path. Make sure you are passing:

```
res://assets/sprites/player/idle.png
```

Not:

```
assets/sprites/player/idle.png
C:/Users/.../project/assets/sprites/player/idle.png
```

### 2. File is Outside the Project Root

Godot can only load resources that are inside the project directory (the folder containing `project.godot`). Verify that `assets/sprites/player/idle.png` is actually inside the same directory tree as your `project.godot` file.

### 3. File Extension or Casing Issues

- Ensure the file is actually a `.png` and not misnamed (e.g., `.PNG` uppercase can sometimes cause issues depending on the OS and how the path is referenced).
- Check for typos in the path: `idle.png` vs `Idle.png`, `player` vs `Player`, etc.

### 4. Corrupted or Unsupported PNG

If the PNG file is corrupted, has an unusual color profile, or is not a standard PNG (e.g., it is actually a JPEG renamed to `.png`), Godot's importer may fail silently and produce no `.import` file. Try opening the image in an image editor and re-saving it as a standard PNG.

### 5. The `.import` File Exists but is Stale

If you replaced the PNG with a different file of the same name, the cached import may be stale. Delete the corresponding `.import` file (e.g., `assets/sprites/player/idle.png.import`) and the cached entry in `.godot/imported/`, then re-run `godot --headless --import`.

---

## Recommended Workflow

Whenever you add new asset files to a Godot project while working with the MCP, follow this sequence:

1. Place the asset file in the project directory
2. Run `godot --headless --import` (via Bash tool)
3. Verify the `.import` sidecar file was created next to your asset
4. Call `load_sprite` with the `res://` path

This ensures Godot has processed the asset before the MCP tries to reference it.
