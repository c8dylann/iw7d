"""List string literals from ZoneTool .gscbin dumps.

IW7 scriptfiles keep their string stack zlib-compressed. This finds every zlib stream in each
.gscbin under the given directories, inflates it, and prints the printable strings that match
the filter, with the script they came from.

Usage: python -I script_strings.py <filter regex> <dump dir> [<dump dir> ...]
"""

import re
import sys
import zlib
from pathlib import Path


def inflate_all(data: bytes):
    pos = 0
    while True:
        pos = data.find(b"\x78", pos)
        if pos < 0 or pos + 1 >= len(data):
            return
        if data[pos + 1] in (0x01, 0x5E, 0x9C, 0xDA):
            d = zlib.decompressobj()
            try:
                out = d.decompress(data[pos:])
                if out:
                    yield out
            except zlib.error:
                pass
        pos += 1


def main():
    pattern = re.compile(sys.argv[1].encode())
    hits = {}
    for root in sys.argv[2:]:
        for f in Path(root).rglob("*.gscbin"):
            for chunk in inflate_all(f.read_bytes()):
                for s in re.findall(rb"[\x20-\x7e]{3,}", chunk):
                    if pattern.search(s):
                        hits.setdefault(s.decode("ascii"), set()).add(str(f.relative_to(root)))
    for s in sorted(hits):
        print(f"{s:60s}  {', '.join(sorted(hits[s])[:3])}")


if __name__ == "__main__":
    main()
