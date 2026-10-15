#!/usr/bin/env python3
"""Compare RAM test folders using only Python's standard library."""

from __future__ import annotations

import argparse
import csv
import json
import re
import statistics
from pathlib import Path
from typing import Any


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig", errors="replace")


def stats(values: list[float]) -> dict[str, float | int] | None:
    if not values:
        return None
    return {
        "n": len(values),
        "mean": round(statistics.mean(values), 4),
        "min": round(min(values), 4),
        "max": round(max(values), 4),
    }


def result_files(directory: Path) -> list[Path]:
    return sorted(directory.rglob("*.txt"))


def extract_measurements(directory: Path) -> dict[str, Any]:
    texts = [(path, read_text(path)) for path in result_files(directory)]
    winsat: list[float] = []
    idle_latency: list[float] = []
    max_bandwidth: dict[str, list[float]] = {}
    peak_bandwidth: dict[str, list[float]] = {}
    loaded_curves: list[dict[int, tuple[float, float]]] = []

    winsat_re = re.compile(r"Memory Performance\s+([\d.,]+)\s+MB/s", re.I)
    idle_re = re.compile(r"Each iteration took\s+[\d.]+\s+base frequency clocks\s*\(\s*([\d.]+)\s*ns\)", re.I)
    bandwidth_re = re.compile(r"(ALL Reads|3:1 Reads-Writes|2:1 Reads-Writes|1:1 Reads-Writes|Stream-triad like)\s*:\s*([\d.,]+)", re.I)
    curve_re = re.compile(r"^\s*(\d+)\s+([\d.]+)\s+([\d.]+)\s*$", re.M)

    # A folder can contain exploratory non-elevated runs and a later matched
    # elevated matrix. Prefer the latter per benchmark family when present.
    winsat_texts = [(path, body) for path, body in texts if winsat_re.search(body)]
    elevated_winsat = [(path, body) for path, body in winsat_texts if any("elevated" in part.casefold() for part in path.parts)]
    if elevated_winsat:
        winsat_texts = elevated_winsat
    mlc_texts = [(path, body) for path, body in texts if any(test in path.name.casefold() for test in ("idle_latency", "max_bandwidth", "peak_injection_bandwidth", "loaded_latency"))]
    elevated_mlc = [(path, body) for path, body in mlc_texts if any("elevated" in part.casefold() for part in path.parts)]
    if elevated_mlc:
        mlc_texts = elevated_mlc

    for path, body in winsat_texts:
        for match in winsat_re.finditer(body):
            winsat.append(float(match.group(1).replace(",", "")))

    for path, body in mlc_texts:
        lower_name = path.name.casefold()
        if "idle_latency" in lower_name:
            match = idle_re.search(body)
            if match:
                idle_latency.append(float(match.group(1)))
        if "max_bandwidth" in lower_name and "peak_injection" not in lower_name:
            for match in bandwidth_re.finditer(body):
                key = match.group(1).casefold()
                max_bandwidth.setdefault(key, []).append(float(match.group(2).replace(",", "")))
        if "peak_injection_bandwidth" in lower_name:
            for match in bandwidth_re.finditer(body):
                key = match.group(1).casefold()
                peak_bandwidth.setdefault(key, []).append(float(match.group(2).replace(",", "")))
        if "loaded_latency" in lower_name:
            curve = {
                int(match.group(1)): (float(match.group(2)), float(match.group(3)))
                for match in curve_re.finditer(body)
            }
            if curve:
                loaded_curves.append(curve)

    loaded_latency: dict[str, dict[str, float | int]] = {}
    if loaded_curves:
        common_delays = set.intersection(*(set(curve) for curve in loaded_curves))
        for delay in sorted(common_delays):
            latency_values = [curve[delay][0] for curve in loaded_curves]
            bandwidth_values = [curve[delay][1] for curve in loaded_curves]
            loaded_latency[str(delay)] = {
                "latency_ns": stats(latency_values),
                "bandwidth_mb_s": stats(bandwidth_values),
            }

    return {
        "winsat_memory_mb_s": stats(winsat),
        "mlc_idle_latency_ns": stats(idle_latency),
        "mlc_max_bandwidth_mb_s": {key: stats(values) for key, values in sorted(max_bandwidth.items())},
        "mlc_peak_injection_bandwidth_mb_s": {key: stats(values) for key, values in sorted(peak_bandwidth.items())},
        "mlc_loaded_latency_by_inject_delay": loaded_latency,
    }


def read_machine(directory: Path) -> Any:
    for name in ("machine.json", "system.json", "hardware.json"):
        path = directory / name
        if path.is_file():
            try:
                return json.loads(read_text(path))
            except (json.JSONDecodeError, OSError) as error:
                return {"error": str(error), "file": name}
    return None


def normalize_header(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.casefold())


def telemetry_from_wide_csv(path: Path) -> dict[str, Any] | None:
    with path.open(newline="", encoding="utf-8-sig") as source:
        rows = list(csv.DictReader(source))
    if not rows:
        return None
    aliases = {
        "available_mib": {"availablemib", "available_mbytes", "availablembytes"},
        "committed_gib": {"committedgib"},
        "pages_input_per_s": {"pagesinputpersec", "pages_input_per_s", "pagesinputsec"},
        "pages_output_per_s": {"pagesoutputpersec", "pages_output_per_s", "pagesoutputsec"},
        "page_reads_per_s": {"pagereadspersec", "pagereadssec"},
        "page_faults_per_s": {"pagefaultspersec", "page_faults_per_s", "pagefaultssec"},
        "cpu_total_pct": {"cputotalpct", "processor_total_processor_time"},
        "disk_read_sec": {"diskreadsec"},
        "disk_write_sec": {"diskwritesec"},
        "disk_queue": {"diskqueue", "currentdiskqueuelength"},
    }
    normalized_rows = [{normalize_header(key): value for key, value in row.items()} for row in rows]
    normalized_aliases = {target: {normalize_header(name) for name in names} for target, names in aliases.items()}
    output: dict[str, Any] = {"sample_count": len(rows)}
    for target, names in aliases.items():
        values: list[float] = []
        for row in normalized_rows:
            match_key = next((key for key in normalized_aliases[target] if key in row), None)
            if match_key is not None and row[match_key] not in (None, ""):
                try:
                    values.append(float(row[match_key]))
                except ValueError:
                    continue
        if values:
            output[target] = stats(values)
    return output if len(output) > 1 else None


def telemetry_from_long_csv(path: Path) -> dict[str, Any] | None:
    with path.open(newline="", encoding="utf-8-sig") as source:
        rows = list(csv.DictReader(source))
    if not rows or not {"Path", "CookedValue"}.issubset(rows[0]):
        return None
    aliases = {
        "available_mib": "available mbytes",
        "committed_gib": "committed bytes",
        "commit_limit_gib": "commit limit",
        "pages_input_per_s": "pages input/sec",
        "pages_output_per_s": "pages output/sec",
        "page_reads_per_s": "page reads/sec",
        "page_faults_per_s": "page faults/sec",
    }
    values_by_metric: dict[str, list[float]] = {key: [] for key in aliases}
    for row in rows:
        counter = row.get("Path", "").split("\\")[-1].casefold()
        for key, alias in aliases.items():
            if counter == alias:
                try:
                    value = float(row["CookedValue"])
                    if key.endswith("_gib"):
                        value /= 1024**3
                    values_by_metric[key].append(value)
                except (KeyError, ValueError):
                    pass
    output = {key: stats(values) for key, values in values_by_metric.items() if values}
    output["sample_count"] = len({row.get("Timestamp") for row in rows if row.get("Timestamp")})
    return output if len(output) > 1 else None


def read_telemetry(directory: Path) -> Any:
    candidates = (
        "telemetry.csv",
        "monitor.csv",
        "workload.csv",
        "after-benchmark-normal-session.csv",
        "paging-pressure.csv",
    )
    for filename in candidates:
        path = directory / filename
        if path.is_file():
            result = telemetry_from_wide_csv(path) or telemetry_from_long_csv(path)
            if result:
                return {"file": filename, **result}
    return None


def parse_config(value: str) -> tuple[str, Path]:
    if "=" not in value:
        raise argparse.ArgumentTypeError("Use LABEL=PATH for each --config.")
    label, raw_path = value.split("=", 1)
    if not label or not raw_path:
        raise argparse.ArgumentTypeError("Both label and path are required in LABEL=PATH.")
    path = Path(raw_path).expanduser().resolve()
    if not path.is_dir():
        raise argparse.ArgumentTypeError(f"Configuration directory does not exist: {path}")
    return label, path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", action="append", type=parse_config, required=True, metavar="LABEL=PATH", help="Repeat for each hardware configuration.")
    parser.add_argument("--telemetry", action="append", type=parse_config, default=[], metavar="LABEL=PATH", help="Optional separate monitor folder to associate with a configuration label.")
    parser.add_argument("--output", type=Path, help="Optional JSON report path; stdout is used by default.")
    args = parser.parse_args()
    config_labels = [label for label, _ in args.config]
    if len(set(config_labels)) != len(config_labels):
        parser.error("Each --config label must be unique.")
    unknown_telemetry = sorted({label for label, _ in args.telemetry} - set(config_labels))
    if unknown_telemetry:
        parser.error("--telemetry labels must match a --config label: " + ", ".join(unknown_telemetry))
    telemetry_by_label = {label: read_telemetry(path) for label, path in args.telemetry}
    report = {
        "format_version": 1,
        "configs": [
            {
                "label": label,
                "directory": str(path),
                "machine": read_machine(path),
                "performance": extract_measurements(path),
                "telemetry": telemetry_by_label.get(label) or read_telemetry(path),
            }
            for label, path in args.config
        ],
    }
    serialized = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        if args.output.exists():
            parser.error(f"Refusing to overwrite report: {args.output}")
        args.output.write_text(serialized, encoding="utf-8")
    else:
        print(serialized, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
