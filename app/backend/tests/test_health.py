from unittest.mock import Mock

from main import health_check


def test_health_check_returns_ok():
    database_session = Mock()

    response = health_check(db=database_session)

    assert response == {"status": "ok"}
    database_session.execute.assert_called_once()