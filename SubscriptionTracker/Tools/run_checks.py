#!/usr/bin/env python3
"""Run deterministic model/catalog checks without requiring an iOS simulator."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="subscription-checks-") as directory:
    script = Path(directory) / "Checks.swift"
    script.write_text("\n".join((root / file).read_text() for file in
                               ["Subscription.swift", "Membership.swift", "Catalog.swift", "Tests/ModelChecks.swift"]))
    subprocess.run(["swift", "-module-cache-path", str(Path(directory) / "cache"), str(script)], check=True)

with tempfile.TemporaryDirectory(prefix="receipt-checks-") as directory:
    script = Path(directory) / "ReceiptChecks.swift"
    script.write_text("\n".join((root / file).read_text() for file in
                               ["Subscription.swift", "Membership.swift", "Catalog.swift", "ReceiptParser.swift", "Tests/ReceiptChecks.swift"]))
    subprocess.run(["swift", "-module-cache-path", str(Path(directory) / "cache"), str(script)], check=True)
