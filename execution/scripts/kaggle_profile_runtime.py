from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import timedelta
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Kaggle profile runtime helper.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    snapshot = subparsers.add_parser("snapshot", help="Capture auth and notebook quota state for one config dir.")
    snapshot.add_argument("--config-dir", required=True)

    whoami = subparsers.add_parser("whoami", help="Resolve the authenticated Kaggle username for one config dir.")
    whoami.add_argument("--config-dir", required=True)

    return parser.parse_args()


def patch_quota_timedelta_parser() -> None:
    from kagglesdk.kaggle_object import TimeDeltaSerializer

    def patched_from_dict_value(value: str) -> timedelta:
        text = str(value).strip()
        if not text.endswith("s"):
            raise ValueError(f"Unsupported timedelta value: {value!r}")

        text = text[:-1]
        sign = -1 if text.startswith("-") else 1
        if sign < 0:
            text = text[1:]

        if "." in text:
            seconds_raw, nanos_raw = text.split(".", 1)
        else:
            seconds_raw, nanos_raw = text, "0"

        seconds = int(seconds_raw or "0")
        nanos_digits = "".join(ch for ch in nanos_raw if ch.isdigit())
        if len(nanos_digits) > 9:
            nanos_digits = nanos_digits[:9]
        nanos = int(nanos_digits.ljust(9, "0")) if nanos_digits else 0

        total_seconds = sign * seconds
        total_microseconds = sign * (nanos // 1000)
        return timedelta(seconds=total_seconds, microseconds=total_microseconds)

    TimeDeltaSerializer._from_dict_value = staticmethod(patched_from_dict_value)


def init_kaggle_api(config_dir: str):
    os.environ["KAGGLE_CONFIG_DIR"] = config_dir
    patch_quota_timedelta_parser()

    from kaggle import KaggleApi

    api = KaggleApi()
    api.authenticate()
    return api


def quota_to_dict(quota) -> dict[str, object] | None:
    if quota is None:
        return None

    used_hours = quota.time_used.total_seconds() / 3600
    total_hours = quota.total_time_allowed.total_seconds() / 3600
    remaining_hours = max(0.0, total_hours - used_hours)
    return {
        "used_hours": round(used_hours, 2),
        "remaining_hours": round(remaining_hours, 2),
        "total_hours": round(total_hours, 2),
    }


def capture_snapshot(config_dir: str) -> dict[str, object]:
    result: dict[str, object] = {
        "config_dir": str(Path(config_dir).resolve()),
        "auth_ok": False,
    }

    try:
        api = init_kaggle_api(config_dir)
        result["auth_ok"] = True
        result["observed_username"] = api.get_config_value(api.CONFIG_NAME_USER)
    except Exception as exc:  # pragma: no cover - exercised in live validation only
        result["error"] = f"auth_failed: {exc}"
        return result

    try:
        quota = api.quota_view()
        result["notebook_quota"] = {
            "status": "ok",
            "refresh_at": quota.quota_refresh_time.isoformat() if quota.quota_refresh_time else None,
            "gpu": quota_to_dict(quota.gpu_quota),
            "tpu": quota_to_dict(quota.tpu_quota),
        }
    except Exception as exc:  # pragma: no cover - exercised in live validation only
        result["notebook_quota"] = {
            "status": "error",
            "error": str(exc),
        }

    return result


def main() -> int:
    args = parse_args()
    if args.command == "snapshot":
        payload = capture_snapshot(args.config_dir)
    elif args.command == "whoami":
        api = init_kaggle_api(args.config_dir)
        payload = {
            "config_dir": str(Path(args.config_dir).resolve()),
            "auth_ok": True,
            "observed_username": api.get_config_value(api.CONFIG_NAME_USER),
        }
    else:
        raise ValueError(args.command)

    print(json.dumps(payload, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
