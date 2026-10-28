#!/usr/bin/env python3
"""Minimal Open Cloud client for CI (stdlib only). Endpoints/limits per creator-docs openapi.json (2026-10-24).
Usage:
  rbx.py test    PLACE_FILE TASK_FILE          # Saved version -> TEST place, run Luau task, fail on error
  rbx.py publish PLACE_FILE                     # Published version -> PROD place
  rbx.py restart [BLEED_MINUTES]                # restart outdated servers (1-60 min bleed-off)
  rbx.py config  CONFIG_JSON [Immediate|GradualRollout]   # overwrite InExperienceConfig draft + publish
Env: ROBLOX_API_KEY, UNIVERSE_ID, PLACE_ID
"""
import json, os, sys, time, urllib.request, urllib.error

API = "https://apis.roblox.com"
KEY = os.environ["ROBLOX_API_KEY"]
U = os.environ["UNIVERSE_ID"]
P = os.environ.get("PLACE_ID", "")


def call(method, url, body=None, ctype="application/json", tries=6):
    data = body if isinstance(body, (bytes, type(None))) else json.dumps(body).encode()
    for i in range(tries):
        req = urllib.request.Request(url, data=data, method=method,
                                     headers={"x-api-key": KEY, "Content-Type": ctype, "Accept": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                raw = r.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="replace")
            if e.code in (429, 500, 502, 503, 504) and i < tries - 1:
                wait = int(e.headers.get("retry-after") or 0) or min(60, 2 ** (i + 1))
                print(f"{method} {url} -> {e.code}, retry in {wait}s", file=sys.stderr)
                time.sleep(wait)
                continue
            sys.exit(f"{method} {url} -> HTTP {e.code}: {msg}")


def upload(place_file, version_type):
    ctype = "application/xml" if place_file.endswith(".rbxlx") else "application/octet-stream"
    with open(place_file, "rb") as f:
        res = call("POST", f"{API}/universes/v1/{U}/places/{P}/versions?versionType={version_type}", f.read(), ctype)
    print(f"{version_type} place version {res['versionNumber']}")
    return res["versionNumber"]


def run_task(version, script_file, timeout_s=300):
    with open(script_file, encoding="utf-8") as f:
        script = f.read()
    task = call("POST", f"{API}/cloud/v2/universes/{U}/places/{P}/versions/{version}/luau-execution-session-tasks",
                {"script": script, "timeout": f"{timeout_s}s"})
    path = task["path"]
    while task.get("state") not in ("COMPLETE", "FAILED", "CANCELLED"):
        time.sleep(3)                                   # GET task limit is generous; create is 5/min
        task = call("GET", f"{API}/cloud/v2/{path}")
    logs = call("GET", f"{API}/cloud/v2/{path}/logs?maxPageSize=10000")
    for page in logs.get("luauExecutionSessionTaskLogs", []):
        for line in page.get("messages", []):
            print(line)
    if task["state"] != "COMPLETE":
        sys.exit(f"Luau task {task['state']}: {json.dumps(task.get('error'))}")
    print("Task output:", json.dumps(task.get("output", {}).get("results")))


def restart(bleed_minutes=0):
    body = {}                                           # default: only servers on outdated versions
    if bleed_minutes:
        body = {"bleedOffServers": True, "bleedOffDurationMinutes": int(bleed_minutes)}
    call("POST", f"{API}/cloud/v2/universes/{U}:restartServers", body)
    print("restart requested", body)


def push_config(config_file, strategy="Immediate"):
    base = f"{API}/creator-configs-public-api/v1/configs/universes/{U}/repositories/InExperienceConfig"
    with open(config_file, encoding="utf-8") as f:
        entries = json.load(f)
    draft = call("PUT", f"{base}/draft:overwrite", {"entries": entries})
    res = call("POST", f"{base}/publish", {"draftHash": draft["draftHash"],
                                           "message": os.environ.get("GITHUB_SHA", "manual"),
                                           "deploymentStrategy": strategy})
    print("config published", res)


if __name__ == "__main__":
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "test":
        run_task(upload(args[0], "Saved"), args[1])
    elif cmd == "publish":
        upload(args[0], "Published")
    elif cmd == "restart":
        restart(*args)
    elif cmd == "config":
        push_config(*args)
    else:
        sys.exit(__doc__)
