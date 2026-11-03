# pyright: basic
import json
import sys
import urllib.error
import urllib.request

URL = "http://localhost:8765"


def call(action, **params):
    body = json.dumps({"action": action, "version": 6, "params": params}).encode()
    try:
        with urllib.request.urlopen(urllib.request.Request(URL, body)) as resp:
            r = json.load(resp)
    except urllib.error.URLError as e:
        sys.exit(f"AnkiConnect unreachable at {URL} (is Anki open?): {e}")
    if r["error"]:
        sys.exit(f"{action}: {r['error']}")
    return r["result"]


def main():
    with open(sys.argv[1]) as f:
        raw = json.load(f)
    notes = [
        {
            "deckName": n["deck"],
            "modelName": n["model"],
            "fields": n["fields"],
            "tags": n.get("tags", []),
        }
        for n in raw
    ]
    decks = set(call("deckNames"))
    missing = {n["deckName"] for n in notes} - decks
    if missing:
        sys.exit(f"unknown deck(s) {sorted(missing)}; existing: {sorted(decks)}")
    can = call("canAddNotes", notes=notes)
    to_add = [n for n, ok in zip(notes, can, strict=True) if ok]
    ids = call("addNotes", notes=to_add) if to_add else []
    added = sum(1 for i in ids if i)
    print(f"added {added}, skipped {len(notes) - len(to_add)} duplicate(s)")
    for n, ok in zip(notes, can, strict=True):
        if not ok:
            print("  skipped:", next(iter(n["fields"].values())))


if __name__ == "__main__":
    main()
