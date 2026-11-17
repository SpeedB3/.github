"""Fixture for the scripts.yml self-test; also its self-test script, which checks that listed
self-tests run under the requested python-version and exits 1 otherwise."""

import sys


def main() -> int:
    if sys.version_info[:2] != (3, 13):
        print(
            f"expected Python 3.13 (ci.yml scripts job python-version), got {sys.version.split()[0]}",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
