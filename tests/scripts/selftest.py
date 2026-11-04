"""Fixture for the scripts.yml self-test; also its self-test script, which checks that listed
self-tests run under the requested python-version and exits 1 otherwise."""

import sys


def main() -> int:
    if sys.version_info[:2] != (3, 12):
        print(
            f"expected Python 3.12 (scripts.yml python-version default), got {sys.version.split()[0]}",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
