#!/usr/bin/env python3
"""Write a Rojo-style sourcemap.json WITHOUT Rojo (for sandboxes where `rojo` is not installed).

On a normal machine use the real thing instead:  rojo sourcemap default.project.json --output sourcemap.json

usage: make_sourcemap.py [--stubs] [OUT]      (default OUT: sourcemap.json)
  --stubs   map ServerPackages/ to analysis/stubs/ServerPackages/ (use when `wally install` has not run)
Handles only what this template uses: $className, $path directories, *.luau scripts, init files, nested folders.
"""
import json, os, sys

args = [a for a in sys.argv[1:] if not a.startswith("--")]
use_stubs = "--stubs" in sys.argv
out = args[0] if args else "sourcemap.json"
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
project = json.load(open(os.path.join(root, "default.project.json")))
SERVICES = {"ReplicatedStorage", "ServerScriptService", "StarterPlayer", "StarterPlayerScripts", "Workspace", "Lighting",
            "ReplicatedFirst", "StarterGui", "ServerStorage", "SoundService"}


def script_class(filename):
    if filename.endswith(".server.luau"):
        return "Script", filename[: -len(".server.luau")]
    if filename.endswith(".client.luau"):
        return "LocalScript", filename[: -len(".client.luau")]
    if filename.endswith(".luau"):
        return "ModuleScript", filename[: -len(".luau")]
    return None, None


def rel(path):
    return os.path.relpath(path, root).replace(os.sep, "/")


def from_dir(path, name):
    """A $path directory becomes a Folder (or the class of its init.* file)."""
    node = {"name": name, "className": "Folder", "filePaths": [], "children": []}
    entries = sorted(os.listdir(path))
    for init in ("init.luau", "init.server.luau", "init.client.luau"):
        if init in entries:
            cls, _ = script_class(init)
            node["className"] = cls
            node["filePaths"] = [rel(os.path.join(path, init))]
    for entry in entries:
        full = os.path.join(path, entry)
        if entry.startswith("init.") or entry == ".gitkeep":
            continue
        if os.path.isdir(full):
            node["children"].append(from_dir(full, entry))
        else:
            cls, base = script_class(entry)
            if cls and not base.endswith(".spec"):
                node["children"].append({"name": base, "className": cls, "filePaths": [rel(full)]})
    return node


def build(name, spec):
    node = {"name": name, "className": spec.get("$className") or (name if name in SERVICES else "Folder"), "filePaths": [], "children": []}
    if "$path" in spec:
        path = spec["$path"]
        if use_stubs and path == "ServerPackages":
            path = "analysis/stubs/ServerPackages"
        sub = from_dir(os.path.join(root, path), name)
        if not spec.get("$className") and node["className"] == "Folder":
            node = sub
        else:
            node["children"] = sub["children"]
            node["filePaths"] = sub["filePaths"]
    for key, child in spec.items():
        if not key.startswith("$"):
            node["children"].append(build(key, child))
    return node


tree = build(project["name"], project["tree"])
tree["className"] = "DataModel"
with open(os.path.join(root, out) if not os.path.isabs(out) else out, "w") as f:
    json.dump(tree, f, indent=1)
print("wrote", out)
