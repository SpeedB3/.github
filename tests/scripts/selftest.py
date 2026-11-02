"""Fixture for the scripts.yml self-test; also its self-test script (exits 1 on failure)."""

import sys


def main() -> int:
    return 0 if sum([2, 3]) == 5 else 1


if __name__ == "__main__":
    sys.exit(main())
