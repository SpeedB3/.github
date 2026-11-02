import os

import pytest

from selftest import add


def test_add() -> None:
    assert add(2, 3) == 5


def test_env_from_caller() -> None:
    assert os.environ.get("SELFTEST_MARKER") == "set-by-caller"


@pytest.mark.skipif("TEST_DATABASE_URL" not in os.environ, reason="no PostgreSQL in this run")
def test_database_url_points_at_created_db() -> None:
    assert os.environ["TEST_DATABASE_URL"].endswith("/selftest_db")
