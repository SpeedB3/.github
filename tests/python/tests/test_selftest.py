import os

from selftest import add


def test_add() -> None:
    assert add(2, 3) == 5


def test_env_from_caller() -> None:
    assert os.environ.get("SELFTEST_MARKER") == "set-by-caller"
