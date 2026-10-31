from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest


EMPLOYEE_ID = "employee_huythong"


def create_shift(client, admin, **changes):
    now = datetime.now(UTC)

    payload = {
        "userId": EMPLOYEE_ID,
        "name": "Ca CI",
        "start": (now - timedelta(minutes=5)).isoformat(),
        "end": (now + timedelta(hours=2)).isoformat(),
        **changes,
    }

    response = client.post(
        "/api/shifts",
        headers=admin,
        json=payload,
    )

    assert response.status_code == 201, response.text

    return response.json()


@pytest.fixture
def prepared(client, admin):
    response = client.put(
        "/api/settings/gps",
        headers=admin,
        json={
            "latitude": 10.0,
            "longitude": 106.0,
            "radiusMeters": 200.0,
        },
    )

    assert response.status_code == 200, response.text

    response = client.put(
        "/api/faces/" + EMPLOYEE_ID,
        headers=admin,
        json={
            "model": "human-3.3.6-faceres",
            "preprocessing": "equalized-v1",
            "samples": [[0.1] * 1024],
            "photos": [],
            "registeredAt": datetime.now(UTC).isoformat(),
        },
    )

    assert response.status_code == 200, response.text

    return create_shift(client, admin)


def action(shift_id, **gps_changes):
    return {
        "shiftId": shift_id,
        "requestId": uuid4().hex,
        "faceVerified": True,
        "gps": {
            "latitude": 10.0,
            "longitude": 106.0,
            "accuracy": 10.0,
            "capturedAt": datetime.now(UTC).isoformat(),
            **gps_changes,
        },
    }


def test_login_logout_revokes_token(client, employee):
    assert client.get(
        "/api/auth/me",
        headers=employee,
    ).status_code == 200

    assert client.post(
        "/api/auth/logout",
        headers=employee,
    ).status_code == 204

    assert client.get(
        "/api/auth/me",
        headers=employee,
    ).status_code == 401

    assert client.get("/api/attendance").status_code == 401


def test_employee_cannot_access_other_people(client, employee):
    assert client.get(
        "/api/users/employees",
        headers=employee,
    ).status_code == 403

    assert client.get(
        "/api/shifts?userId=employee_other",
        headers=employee,
    ).status_code == 403

    assert client.get(
        "/api/attendance?userId=employee_other",
        headers=employee,
    ).status_code == 403

    assert client.get(
        "/api/faces/employee_other",
        headers=employee,
    ).status_code == 403

    assert client.delete(
        "/api/users/employees/employee_other",
        headers=employee,
    ).status_code == 403


def test_admin_sees_checkout_and_snapshot_stays_unchanged(
    client,
    admin,
    employee,
    prepared,
):
    shift_id = prepared["id"]

    response = client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(shift_id),
    )

    assert response.status_code == 200, response.text

    first = response.json()

    history = client.get(
        "/api/attendance?userId=" + EMPLOYEE_ID,
        headers=admin,
    )

    assert history.status_code == 200
    assert history.json()["records"][0]["id"] == first["id"]

    response = client.put(
        "/api/shifts/" + shift_id,
        headers=admin,
        json={
            "name": "Ca da doi ten",
            "start": prepared["start"],
            "end": prepared["end"],
        },
    )

    assert response.status_code == 200, response.text

    response = client.post(
        "/api/attendance/check-out",
        headers=employee,
        json=action(shift_id),
    )

    assert response.status_code == 200, response.text

    finished = response.json()

    assert finished["checkOut"] is not None
    assert finished["shiftSnapshot"] == first["shiftSnapshot"]

    assert (
        datetime.fromisoformat(finished["checkOut"])
        >= datetime.fromisoformat(first["checkIn"])
    )

    history = client.get(
        "/api/attendance?userId=" + EMPLOYEE_ID,
        headers=admin,
    )

    assert (
        history.json()["records"][0]["checkOut"]
        == finished["checkOut"]
    )


def test_repeated_request_and_only_one_active_shift(
    client,
    admin,
    employee,
    prepared,
):
    shift_id = prepared["id"]
    payload = action(shift_id)

    first = client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=payload,
    )

    retry = client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=payload,
    )

    assert first.status_code == retry.status_code == 200
    assert first.json() == retry.json()

    assert client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(shift_id),
    ).status_code == 409

    other = create_shift(client, admin)

    assert client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(other["id"]),
    ).status_code == 409

    history = client.get(
        "/api/attendance",
        headers=employee,
    )

    assert len(history.json()["records"]) == 1


@pytest.mark.parametrize(
    "gps,status",
    [
        ({"accuracy": 151.0}, 422),
        ({"accuracy": -1.0}, 422),
        ({"latitude": 91.0}, 422),
        ({"latitude": 11.0}, 409),
    ],
)
def test_invalid_gps_does_not_record_attendance(
    client,
    employee,
    prepared,
    gps,
    status,
):
    response = client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(prepared["id"], **gps),
    )

    assert response.status_code == status, response.text

    history = client.get(
        "/api/attendance",
        headers=employee,
    )

    assert history.json()["records"] == []


def test_missing_face_and_location_block_checkin(
    client,
    admin,
    employee,
    prepared,
):
    shift_id = prepared["id"]

    assert client.delete(
        "/api/settings/gps",
        headers=admin,
    ).status_code == 200

    assert client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(shift_id),
    ).status_code == 409

    assert client.put(
        "/api/settings/gps",
        headers=admin,
        json={
            "latitude": 10.0,
            "longitude": 106.0,
            "radiusMeters": 200.0,
        },
    ).status_code == 200

    assert client.delete(
        "/api/faces/" + EMPLOYEE_ID,
        headers=admin,
    ).status_code == 200

    assert client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(shift_id),
    ).status_code == 409


def test_active_shift_blocks_deletion(
    client,
    admin,
    employee,
    prepared,
):
    shift_id = prepared["id"]

    assert client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(shift_id),
    ).status_code == 200

    assert client.delete(
        "/api/shifts/" + shift_id,
        headers=admin,
    ).status_code == 409

    assert client.delete(
        "/api/attendance/" + shift_id,
        headers=admin,
    ).status_code == 409

    assert client.delete(
        "/api/users/employees/" + EMPLOYEE_ID,
        headers=admin,
    ).status_code == 409


def test_deleted_history_cannot_be_recorded_again(
    client,
    admin,
    employee,
    prepared,
):
    shift_id = prepared["id"]

    assert client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(shift_id),
    ).status_code == 200

    assert client.post(
        "/api/attendance/check-out",
        headers=employee,
        json=action(shift_id),
    ).status_code == 200

    assert client.delete(
        "/api/attendance/" + shift_id,
        headers=admin,
    ).status_code == 204

    history = client.get(
        "/api/attendance",
        headers=employee,
    )

    assert history.json()["records"] == []

    assert client.post(
        "/api/attendance/check-in",
        headers=employee,
        json=action(shift_id),
    ).status_code == 409


def test_employee_creation_password_change_and_delete(
    client,
    admin,
):
    payload = {
        "username": "ci_new",
        "fullName": "New CI",
        "email": "new-ci@example.com",
        "password": "ci-password",
    }

    response = client.post(
        "/api/users/employees",
        headers=admin,
        json=payload,
    )

    assert response.status_code == 201, response.text

    user_id = response.json()["id"]

    assert client.post(
        "/api/users/employees",
        headers=admin,
        json=payload,
    ).status_code == 409

    login = client.post(
        "/api/auth/login",
        json={
            "username": "ci_new",
            "password": "ci-password",
        },
    )

    assert login.status_code == 200, login.text

    old_token = {
        "Authorization": "Bearer " + login.json()["access_token"],
    }

    payload["password"] = "changed-password"

    assert client.put(
        "/api/users/employees/" + user_id,
        headers=admin,
        json=payload,
    ).status_code == 200

    assert client.get(
        "/api/auth/me",
        headers=old_token,
    ).status_code == 401

    assert client.delete(
        "/api/users/employees/" + user_id,
        headers=admin,
    ).status_code == 204

    assert client.post(
        "/api/auth/login",
        json={
            "username": "ci_new",
            "password": "changed-password",
        },
    ).status_code == 401

    assert client.delete(
        "/api/users/employees/admin_aivee",
        headers=admin,
    ).status_code == 403