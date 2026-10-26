#!/usr/bin/env python3
"""Copy the exact shipped iOS catalog and logo assets; never modify saved user records."""
import json
import shutil
from pathlib import Path

project = Path(__file__).resolve().parents[1]
ios = project.parent / "SubscriptionTracker"
main = project / "app/src/main"
text = (ios / "Catalog.swift").read_text()
raw = text.split('let json = #"""', 1)[1].split('"""#', 1)[0]
catalog = json.loads(raw)
assert len({s["id"] for s in catalog}) == len(catalog)
(main / "assets/catalog.json").write_text(json.dumps(catalog, ensure_ascii=False, indent=2))
resources = []
for image in sorted((ios / "Assets.xcassets").glob("service-*.imageset/logo.png")):
    identifier = image.parent.stem
    resource = identifier.replace("-", "_")
    shutil.copyfile(image, main / "res/drawable-nodpi" / f"{resource}.png")
    resources.append(f'    "{identifier}" -> R.drawable.{resource}')
(main / "java/com/example/mymemberships/LogoResources.kt").write_text(
    'package com.example.mymemberships\n\nfun logoResource(id: String?): Int = when(id) {\n'
    + "\n".join(resources) + '\n    else -> 0\n}\n'
)
print(f"Copied {len(catalog)} services and {len(resources)} logos.")
