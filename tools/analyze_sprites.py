"""Sprite sheet analyzer — detects frame size, layout, and animation metadata.

Analyzes PNG sprite sheets and outputs structured JSON metadata including
frame dimensions, grid layout, non-empty frame counts per row, direction
mapping suggestions, and animation timing hints. Designed to eliminate
manual guesswork when setting up sprite animations in Godot.

Usage:
    python analyze_sprites.py path/to/sprites/          # analyze directory
    python analyze_sprites.py path/to/sprite.png        # analyze single file
    python analyze_sprites.py path/ --frame-size 48     # override frame size
    python analyze_sprites.py path/ --recursive         # include subdirectories
    python analyze_sprites.py path/ --output meta.json  # save to file
"""

from __future__ import annotations

import argparse
import json
import logging
import sys
from collections import Counter
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image

logger = logging.getLogger(__name__)

COMMON_FRAME_SIZES = [128, 96, 64, 48, 32, 16]
CRAFTPIX_DIRECTION_MAP = {0: "DOWN", 1: "LEFT", 2: "RIGHT", 3: "UP"}
DEFAULT_CYCLE_DURATION = 1.0


@dataclass(frozen=True)
class SheetAnalysis:
    """Analysis result for a single sprite sheet."""

    file: str
    sheet_size: tuple[int, int]
    frame_size: tuple[int, int] | None
    columns: int
    rows: int
    total_frames: int
    frames_per_row: list[int]
    empty_frames_per_row: list[int]
    suggested_direction_map: dict[int, str] | None
    suggested_cycle_duration: float | None
    notes: list[str]


@dataclass
class AnalysisReport:
    """Complete analysis report for one or more sprite sheets."""

    analyzed_at: str
    directory: str
    sheets: list[SheetAnalysis] = field(default_factory=list)
    summary: dict[str, object] = field(default_factory=dict)


def detect_frame_size(
    width: int, height: int, explicit_size: int | None = None
) -> tuple[int, int] | None:
    """Detect the frame size that divides the sheet evenly.

    If explicit_size is given, validates it against sheet dimensions.
    Otherwise tries common sizes and picks the best candidate using a
    scoring heuristic that favors 4-row layouts (directional sprite sheets)
    and at least 2 columns.
    """
    if explicit_size is not None:
        if width % explicit_size == 0 and height % explicit_size == 0:
            return (explicit_size, explicit_size)
        return None

    candidates: list[tuple[int, float]] = []
    for size in COMMON_FRAME_SIZES:
        if width % size == 0 and height % size == 0:
            cols = width // size
            rows = height // size
            if cols >= 2 or rows == 1:
                candidates.append((size, _score_candidate(cols, rows)))

    if candidates:
        candidates.sort(key=lambda x: x[1], reverse=True)
        return (candidates[0][0], candidates[0][0])

    for size in COMMON_FRAME_SIZES:
        if width % size == 0 and height % size == 0:
            return (size, size)

    return None


def _score_candidate(columns: int, rows: int) -> float:
    """Score a frame size candidate based on layout plausibility.

    Prefers layouts with 4 rows (directional sprite sheets) and
    reasonable column counts (3-16 frames per animation).
    """
    score = 0.0

    if rows == 4:
        score += 10.0
    elif rows == 8:
        score += 5.0
    elif rows == 1:
        score += 3.0
    elif rows == 2:
        score += 1.0

    if 3 <= columns <= 16:
        score += 5.0
    elif columns >= 2:
        score += 2.0

    return score


def detect_padding(img: Image.Image, frame_size: int) -> int | None:
    """Detect consistent transparent spacing between frames.

    Checks for vertical transparent columns at regular intervals that would
    indicate padding/spacing between frames. Returns the padding width if
    detected, None otherwise.
    """
    width, height = img.size
    if width <= frame_size:
        return None

    for padding in (1, 2, 3, 4):
        cell_step = frame_size + padding
        if (width + padding) % cell_step != 0:
            continue

        all_transparent = True
        col = frame_size
        while col < width:
            for py in range(padding):
                if col + py >= width:
                    all_transparent = False
                    break
                for row_y in range(height):
                    pixel = img.getpixel((col + py, row_y))
                    if isinstance(pixel, tuple) and len(pixel) >= 4 and pixel[3] > 0:
                        all_transparent = False
                        break
                if not all_transparent:
                    break
            if not all_transparent:
                break
            col += cell_step

        if all_transparent and col >= width:
            return padding

    return None


def count_nonempty_frames(
    img: Image.Image,
    frame_w: int,
    frame_h: int,
    columns: int,
    rows: int,
) -> list[int]:
    """Count non-empty (has visible pixels) frames in each row."""
    nonempty_per_row: list[int] = []

    for row in range(rows):
        count = 0
        for col in range(columns):
            x0 = col * frame_w
            y0 = row * frame_h
            cell = img.crop((x0, y0, x0 + frame_w, y0 + frame_h))

            if cell.mode != "RGBA":
                count += 1
                continue

            alpha = cell.getchannel("A")
            if alpha.getbbox() is not None:
                count += 1

        nonempty_per_row.append(count)

    return nonempty_per_row


def suggest_direction_map(rows: int) -> dict[int, str] | None:
    """Suggest direction mapping based on row count."""
    if rows == 4:
        return dict(CRAFTPIX_DIRECTION_MAP)
    return None


def suggest_cycle_duration(max_frames: int) -> float | None:
    """Suggest animation cycle duration based on frame count."""
    if max_frames <= 0:
        return None
    if max_frames <= 3:
        return 0.4
    if max_frames <= 6:
        return 0.6
    if max_frames <= 10:
        return 0.8
    if max_frames <= 16:
        return 1.0
    return 1.2


def analyze_sheet(
    file_path: Path, explicit_frame_size: int | None = None
) -> SheetAnalysis:
    """Analyze a single sprite sheet PNG file."""
    notes: list[str] = []

    try:
        img = Image.open(file_path)
    except Exception as exc:
        return SheetAnalysis(
            file=file_path.name,
            sheet_size=(0, 0),
            frame_size=None,
            columns=0,
            rows=0,
            total_frames=0,
            frames_per_row=[],
            empty_frames_per_row=[],
            suggested_direction_map=None,
            suggested_cycle_duration=None,
            notes=[f"Failed to open image: {exc}"],
        )

    width, height = img.size

    if img.mode != "RGBA":
        img = img.convert("RGBA")
        notes.append(f"Converted from {img.mode} to RGBA for alpha analysis")

    frame_size = detect_frame_size(width, height, explicit_frame_size)

    if frame_size is None and explicit_frame_size is not None:
        notes.append(
            f"Explicit frame size {explicit_frame_size} does not divide "
            f"sheet {width}x{height} evenly - falling back to auto-detection"
        )
        frame_size = detect_frame_size(width, height)

    if frame_size is None:
        padding = (
            detect_padding(img, 64)
            or detect_padding(img, 48)
            or detect_padding(img, 32)
        )
        if padding:
            notes.append(f"Detected {padding}px padding between frames")

    is_single_frame = False
    if frame_size is None:
        bbox = img.getbbox()
        if bbox and width <= 256 and height <= 256:
            is_single_frame = True
            notes.append("Single frame detected (not a sprite sheet)")
            frame_size = (width, height)
        else:
            notes.append(
                f"Unable to detect frame size for {width}x{height} sheet. "
                f"Not divisible by common sizes: {COMMON_FRAME_SIZES}"
            )
            return SheetAnalysis(
                file=file_path.name,
                sheet_size=(width, height),
                frame_size=None,
                columns=0,
                rows=0,
                total_frames=0,
                frames_per_row=[],
                empty_frames_per_row=[],
                suggested_direction_map=None,
                suggested_cycle_duration=None,
                notes=notes,
            )

    frame_w, frame_h = frame_size
    columns = width // frame_w
    rows = height // frame_h

    frames_per_row = count_nonempty_frames(img, frame_w, frame_h, columns, rows)
    empty_per_row = [columns - count for count in frames_per_row]
    total_frames = sum(frames_per_row)

    direction_map = None if is_single_frame else suggest_direction_map(rows)
    max_frames = max(frames_per_row) if frames_per_row else 0
    cycle_duration = None if is_single_frame else suggest_cycle_duration(max_frames)

    img.close()

    return SheetAnalysis(
        file=file_path.name,
        sheet_size=(width, height),
        frame_size=(frame_w, frame_h),
        columns=columns,
        rows=rows,
        total_frames=total_frames,
        frames_per_row=frames_per_row,
        empty_frames_per_row=empty_per_row,
        suggested_direction_map=direction_map,
        suggested_cycle_duration=cycle_duration,
        notes=notes,
    )


def collect_png_files(path: Path, recursive: bool = False) -> list[Path]:
    """Collect PNG files from a path (file or directory)."""
    if path.is_file():
        if path.suffix.lower() == ".png":
            return [path]
        logger.warning("Skipping non-PNG file: %s", path)
        return []

    if path.is_dir():
        pattern = "**/*.png" if recursive else "*.png"
        png_files = sorted(path.glob(pattern))
        non_png = sorted(
            p
            for p in (path.rglob("*") if recursive else path.iterdir())
            if p.is_file()
            and p.suffix.lower() != ".png"
            and not p.suffix.lower() == ".import"
        )
        for f in non_png:
            logger.warning("Skipping non-PNG file: %s", f.name)
        return png_files

    logger.error("Path does not exist: %s", path)
    return []


def build_summary(sheets: list[SheetAnalysis]) -> dict[str, object]:
    """Build a summary across all analyzed sheets."""
    if not sheets:
        return {
            "total_files": 0,
            "common_frame_size": None,
            "frame_size_consistent": True,
        }

    frame_sizes = [s.frame_size for s in sheets if s.frame_size is not None]
    size_counter: Counter[tuple[int, int]] = Counter(frame_sizes)

    common_frame_size = size_counter.most_common(1)[0][0] if size_counter else None
    consistent = len(size_counter) <= 1

    return {
        "total_files": len(sheets),
        "common_frame_size": list(common_frame_size) if common_frame_size else None,
        "frame_size_consistent": consistent,
    }


def analyze_sprites(
    path: Path,
    frame_size: int | None = None,
    recursive: bool = False,
) -> AnalysisReport:
    """Analyze sprite sheets at the given path and return a structured report."""
    png_files = collect_png_files(path, recursive=recursive)

    if not png_files:
        logger.warning("No PNG files found at: %s", path)

    sheets = [analyze_sheet(f, explicit_frame_size=frame_size) for f in png_files]

    directory = str(path.parent) if path.is_file() else str(path)

    return AnalysisReport(
        analyzed_at=datetime.now(timezone.utc).isoformat(timespec="seconds"),
        directory=directory.replace("\\", "/"),
        sheets=sheets,
        summary=build_summary(sheets),
    )


def report_to_dict(report: AnalysisReport) -> dict:
    """Convert report to a JSON-serializable dictionary."""
    data = asdict(report)
    for sheet in data["sheets"]:
        if sheet["sheet_size"]:
            sheet["sheet_size"] = list(sheet["sheet_size"])
        if sheet["frame_size"]:
            sheet["frame_size"] = list(sheet["frame_size"])
    return data


def build_parser() -> argparse.ArgumentParser:
    """Build the CLI argument parser."""
    parser = argparse.ArgumentParser(
        description="Analyze sprite sheet PNGs and output structured metadata as JSON.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  %(prog)s assets/sprites/player/\n"
            "  %(prog)s assets/sprites/idle.png --frame-size 48\n"
            "  %(prog)s assets/sprites/ --recursive --output meta.json\n"
        ),
    )
    parser.add_argument(
        "path",
        type=Path,
        help="Path to a PNG file or directory containing PNG sprite sheets",
    )
    parser.add_argument(
        "--frame-size",
        type=int,
        default=None,
        metavar="PX",
        help="Explicit square frame size in pixels (overrides auto-detection)",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        default=None,
        metavar="FILE",
        help="Save JSON output to a file instead of only stdout",
    )
    parser.add_argument(
        "--recursive",
        "-r",
        action="store_true",
        help="Recursively analyze subdirectories",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    """CLI entry point."""
    logging.basicConfig(
        level=logging.WARNING,
        format="%(levelname)s: %(message)s",
        stream=sys.stderr,
    )

    parser = build_parser()
    args = parser.parse_args(argv)

    target_path: Path = args.path.resolve()
    if not target_path.exists():
        logger.error("Path does not exist: %s", target_path)
        return 1

    report = analyze_sprites(
        path=target_path,
        frame_size=args.frame_size,
        recursive=args.recursive,
    )

    result = report_to_dict(report)
    json_output = json.dumps(result, indent=2, ensure_ascii=False)

    print(json_output)

    if args.output:
        output_path: Path = args.output.resolve()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json_output + "\n", encoding="utf-8")
        logger.warning("Saved to: %s", output_path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
