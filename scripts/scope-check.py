#!/usr/bin/env python3
"""omarsenal-scope: check targets against the active target's scope.

Usage:
  omarsenal-scope check <target>...        exit 0 if every target is in scope
  omarsenal-scope args <tool> <args>...    pull targets out of a command line, then check

This is a safety net, not a guarantee. It catches typos and stray targets for the
tools it knows (nmap, masscan). It cannot see targets hidden in scripts or configs.
"""
import ipaddress
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "omarsenal"
DEFAULT_TARGETS = Path.home() / "omarsenal-targets"

# Options whose next argument is a value, not a target.
VALUE_OPTS = {
    "nmap": {
        "-p", "-oN", "-oX", "-oG", "-oA", "-oS", "-e", "-S", "-D", "-g", "-iR",
        "--script", "--script-args", "--script-args-file", "--exclude", "--excludefile",
        "--top-ports", "--port-ratio", "--source-port", "--data-length", "--data",
        "--data-string", "--ttl", "--max-retries", "--host-timeout", "--scan-delay",
        "--max-scan-delay", "--min-rate", "--max-rate", "--min-parallelism",
        "--max-parallelism", "--min-hostgroup", "--max-hostgroup", "--dns-servers",
        "--stylesheet", "--datadir", "--servicedb", "--versiondb", "--version-intensity",
        "--spoof-mac", "--proxies", "--resume", "-PS", "-PA", "-PU", "-PY", "-PO",
    },
    "masscan": {
        "-p", "--ports", "--rate", "--max-rate", "-oX", "-oG", "-oJ", "-oL", "-oB",
        "--excludefile", "--exclude", "--adapter", "--adapter-ip", "--adapter-port",
        "--adapter-mac", "--router-mac", "--source-ip", "--source-port", "-c", "--conf",
        "--banners-file", "--resume", "--shard", "--seed", "--ttl", "--wait", "--retries",
    },
}
LIST_OPTS = {"-iL"}  # option whose value is a file of targets

HOSTNAME_RE = re.compile(r"^(?=.{1,253}$)([a-z0-9-]{1,63}\.)+[a-z]{2,63}$", re.I)


def fail(msg, code=2):
    print(f"omarsenal-scope: {msg}", file=sys.stderr)
    sys.exit(code)


def target_dir():
    try:
        name = (STATE / "target").read_text().strip()
    except FileNotFoundError:
        fail("no active target. Run: omarsenal-target use <name>")
    base = Path(os.environ.get("OMARSENAL_TARGETS", DEFAULT_TARGETS))
    d = base / name
    if not d.is_dir():
        fail(f"active target folder missing: {d}")
    return name, d


def read_entries(path):
    if not path.exists():
        return []
    out = []
    for line in path.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            out.append(line.lower())
    return out


def normalize(token):
    """Turn a URL, host:port or bare value into a host or network string."""
    t = token.strip().lower()
    if "://" in t:
        t = urlparse(t).hostname or ""
    elif t.count(":") == 1 and not t.startswith("["):
        t = t.split(":", 1)[0]
    return t.strip("[]")


def as_network(value):
    try:
        return ipaddress.ip_network(value, strict=False)
    except ValueError:
        return None


def ip_range(value):
    """Expand 10.0.0.1-50 style ranges to (first, last)."""
    m = re.match(r"^(\d+\.\d+\.\d+\.)(\d+)-(\d+)$", value)
    if not m:
        return None
    return ipaddress.ip_address(m[1] + m[2]), ipaddress.ip_address(m[1] + m[3])


def matches(target, entry):
    tnet = as_network(target)
    enet = as_network(entry)
    if tnet and enet:
        return tnet.version == enet.version and tnet.subnet_of(enet)
    if tnet or enet:
        return False
    if entry.startswith("*."):
        return target.endswith(entry[1:])
    return target == entry


def in_list(target, entries):
    """True if the whole target (host, network or range) sits inside the entries."""
    rng = ip_range(target)
    if rng:
        first, last = rng
        nets = ipaddress.summarize_address_range(first, last)
        return all(any(matches(str(n), e) for e in entries) for n in nets)
    return any(matches(target, e) for e in entries)


def overlaps(target, entries):
    """True if any part of the target touches an entry. Used for out-of-scope."""
    rng = ip_range(target)
    nets = list(ipaddress.summarize_address_range(*rng)) if rng else []
    tnet = as_network(target)
    if tnet:
        nets = [tnet]
    if not nets:
        return in_list(target, entries)
    for e in entries:
        enet = as_network(e)
        if enet and any(n.version == enet.version and n.overlaps(enet) for n in nets):
            return True
    return False


def check(targets):
    name, d = target_dir()
    auth = (d / "authorization.md").read_text() if (d / "authorization.md").exists() else ""
    if not re.search(r"^Status:\s*APPROVED", auth, re.M):
        fail(f"{name}: authorization.md is not APPROVED. Nothing may be scanned.", 1)
    scope = read_entries(d / "scope.txt")
    oos = read_entries(d / "out-of-scope.txt")
    if not scope:
        fail(f"{name}: scope.txt is empty", 1)

    bad = []
    for raw in targets:
        t = normalize(raw)
        if not t:
            continue
        if overlaps(t, oos) or not in_list(t, scope):
            bad.append(raw)
    if bad:
        print(f"omarsenal-scope: OUT OF SCOPE for {name}: {' '.join(bad)}", file=sys.stderr)
        sys.exit(1)


def looks_like_target(tok):
    t = normalize(tok)
    return bool(as_network(t) or ip_range(t) or HOSTNAME_RE.match(t)) and not Path(tok).exists()


def extract(tool, args):
    value_opts = VALUE_OPTS.get(tool, set())
    targets, skip = [], False
    it = iter(range(len(args)))
    for i in it:
        a = args[i]
        if skip:
            skip = False
            continue
        if a in LIST_OPTS and i + 1 < len(args):
            p = Path(args[i + 1])
            if p.exists():
                targets += [l.strip() for l in p.read_text().split() if l.strip()]
            skip = True
            continue
        if a in value_opts:
            skip = True
            continue
        if a.startswith("-"):
            continue
        for part in a.split(","):
            if looks_like_target(part):
                targets.append(part)
    return targets


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(2)
    cmd = sys.argv[1]
    if cmd == "check":
        check(sys.argv[2:])
    elif cmd == "args":
        tool, rest = sys.argv[2], sys.argv[3:]
        targets = extract(tool, rest)
        if targets:
            check(targets)
    else:
        print(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
