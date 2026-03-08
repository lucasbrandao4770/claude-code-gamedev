"""Grade tscn-editor eval outputs programmatically."""
import json
import re
from pathlib import Path

BASE = Path(r"D:\Workspace\Games\claude-game-dev\.claude\skills\tscn-editor-workspace\iteration-1")

def grade_eval1(tscn: str) -> list[dict]:
    """Grade create-chest-scene outputs."""
    lines = tscn.strip().split("\n")
    results = []

    # 1. Section ordering
    ext_idx = sub_idx = node_idx = -1
    for i, line in enumerate(lines):
        if line.startswith("[ext_resource") and ext_idx == -1:
            ext_idx = i
        if line.startswith("[sub_resource") and sub_idx == -1:
            sub_idx = i
        if line.startswith("[node") and node_idx == -1:
            node_idx = i
    ordered = ext_idx < sub_idx < node_idx if all(x >= 0 for x in [ext_idx, sub_idx, node_idx]) else False
    results.append({"text": "Correct section ordering", "passed": ordered,
                     "evidence": f"ext@{ext_idx} sub@{sub_idx} node@{node_idx}"})

    # 2. Script attached
    has_script = bool(re.search(r'script\s*=\s*ExtResource\(', tscn))
    results.append({"text": "Script attached via ExtResource", "passed": has_script,
                     "evidence": "Found script = ExtResource()" if has_script else "Missing"})

    # 3. CircleShape2D radius 16
    has_shape = "CircleShape2D" in tscn and "radius = 16" in tscn
    results.append({"text": "CircleShape2D with radius 16", "passed": has_shape,
                     "evidence": "Found CircleShape2D + radius = 16" if has_shape else "Missing"})

    # 4. No GDScript syntax
    bad = any(kw in tscn for kw in ["preload(", "load(", "\nvar ", "\nfunc ", "\nconst "])
    results.append({"text": "No GDScript syntax in file", "passed": not bad,
                     "evidence": "Clean" if not bad else "Found GDScript syntax"})

    # 5. Root has no parent
    first_node = re.search(r'\[node\s+[^\]]*\]', tscn)
    root_ok = first_node and 'parent=' not in first_node.group() if first_node else False
    results.append({"text": "Root node has no parent", "passed": root_ok,
                     "evidence": first_node.group() if first_node else "No node found"})

    # 6. No fabricated UIDs
    fabricated = bool(re.search(r'uid="uid://\w+_\w+"', tscn)) or bool(re.search(r'uid="uid://chest', tscn))
    results.append({"text": "No fabricated uid:// values", "passed": not fabricated,
                     "evidence": "Clean" if not fabricated else "Found fabricated UIDs"})

    return results


def grade_eval2(tscn: str) -> list[dict]:
    """Grade edit-player-add-detection outputs."""
    results = []

    # 1. DetectionZone added
    has_dz = bool(re.search(r'\[node\s+name="DetectionZone"\s+type="Area2D"\s+parent="\."\]', tscn))
    results.append({"text": "DetectionZone Area2D added with parent='.'", "passed": has_dz,
                     "evidence": "Found" if has_dz else "Missing"})

    # 2. CircleShape2D radius 80
    has_r80 = "CircleShape2D" in tscn and "radius = 80" in tscn
    results.append({"text": "CircleShape2D with radius 80", "passed": has_r80,
                     "evidence": "Found" if has_r80 else "Missing"})

    # 3. collision_layer and mask
    has_layer = "collision_layer = 0" in tscn
    has_mask = "collision_mask = 4" in tscn
    results.append({"text": "collision_layer=0, collision_mask=4", "passed": has_layer and has_mask,
                     "evidence": f"layer={has_layer}, mask={has_mask}"})

    # 4. Connection block
    has_conn = bool(re.search(r'\[connection\s+signal="body_entered".*from="DetectionZone".*to="\."', tscn))
    results.append({"text": "[connection] for body_entered", "passed": has_conn,
                     "evidence": "Found" if has_conn else "Missing"})

    # 5. Original nodes preserved
    originals = ["Player", "Sprite2D", "Camera2D", "SwordHitBox", "HurtBox"]
    missing = [n for n in originals if f'name="{n}"' not in tscn]
    results.append({"text": "All original nodes preserved", "passed": len(missing) == 0,
                     "evidence": f"Missing: {missing}" if missing else "All present"})

    # 6. Sub-resource in correct section
    lines = tscn.strip().split("\n")
    last_sub = max((i for i, l in enumerate(lines) if l.startswith("[sub_resource")), default=-1)
    first_node = min((i for i, l in enumerate(lines) if l.startswith("[node")), default=999)
    correct = last_sub < first_node if last_sub >= 0 else True
    results.append({"text": "Sub_resource before nodes", "passed": correct,
                     "evidence": f"last_sub@{last_sub} first_node@{first_node}"})

    return results


def grade_eval3(tscn: str) -> list[dict]:
    """Grade fix-broken-tscn outputs."""
    lines = tscn.strip().split("\n")
    results = []

    # 1. Section ordering fixed
    ext_idx = sub_idx = node_idx = -1
    for i, line in enumerate(lines):
        if line.startswith("[ext_resource") and ext_idx == -1:
            ext_idx = i
        if line.startswith("[sub_resource") and sub_idx == -1:
            sub_idx = i
        if line.startswith("[node") and node_idx == -1:
            node_idx = i
    ordered = ext_idx < sub_idx < node_idx if all(x >= 0 for x in [ext_idx, sub_idx, node_idx]) else False
    results.append({"text": "Section ordering fixed", "passed": ordered,
                     "evidence": f"ext@{ext_idx} sub@{sub_idx} node@{node_idx}"})

    # 2. preload removed
    no_preload = "preload(" not in tscn
    has_extres = bool(re.search(r'script\s*=\s*ExtResource\(', tscn))
    results.append({"text": "preload() replaced with ExtResource()", "passed": no_preload and has_extres,
                     "evidence": f"no_preload={no_preload}, has_ExtResource={has_extres}"})

    # 3. Vector2 syntax
    has_v2 = "Vector2(100, 200)" in tscn
    no_tuple = "(100, 200)" not in tscn or "Vector2(100, 200)" in tscn
    results.append({"text": "Vector2 syntax fixed", "passed": has_v2,
                     "evidence": "Found Vector2(100, 200)" if has_v2 else "Missing"})

    # 4. Parent paths fixed
    sprite_ok = bool(re.search(r'\[node\s+name="Sprite2D"[^\]]*parent="\."\]', tscn))
    results.append({"text": "Parent paths fixed (parent='.')", "passed": sprite_ok,
                     "evidence": "Sprite2D parent='.' found" if sprite_ok else "Wrong parent"})

    # 5. CollisionShape2D has parent
    cs_match = re.search(r'\[node\s+name="CollisionShape2D"[^\]]*\]', tscn)
    cs_has_parent = cs_match and 'parent=' in cs_match.group() if cs_match else False
    results.append({"text": "CollisionShape2D has parent attribute", "passed": cs_has_parent,
                     "evidence": cs_match.group() if cs_match else "Not found"})

    # 6. SubResource ref matches
    ref_ok = 'SubResource("CircleShape2D_abc")' in tscn
    results.append({"text": "SubResource ref matches declared ID", "passed": ref_ok,
                     "evidence": "Found abc" if ref_ok else "Mismatch or missing"})

    return results


def run_grading():
    evals = [
        ("eval-1-create-chest", "chest.tscn", grade_eval1),
        ("eval-2-edit-player", "player.tscn", grade_eval2),
        ("eval-3-fix-broken", "fixed.tscn", grade_eval3),
    ]

    for eval_dir, filename, grade_fn in evals:
        for variant in ["with_skill", "without_skill"]:
            path = BASE / eval_dir / variant / "outputs" / filename
            if not path.exists():
                print(f"SKIP {eval_dir}/{variant} — {filename} not found")
                continue

            tscn = path.read_text(encoding="utf-8")
            results = grade_fn(tscn)

            passed = sum(1 for r in results if r["passed"])
            total = len(results)
            print(f"\n{eval_dir}/{variant}: {passed}/{total} passed")
            for r in results:
                status = "PASS" if r["passed"] else "FAIL"
                print(f"  [{status}] {r['text']} — {r['evidence']}")

            grading = {
                "eval_name": eval_dir,
                "variant": variant,
                "expectations": results,
                "pass_rate": passed / total if total > 0 else 0
            }
            grading_path = BASE / eval_dir / variant / "grading.json"
            grading_path.write_text(json.dumps(grading, indent=2), encoding="utf-8")


if __name__ == "__main__":
    run_grading()
