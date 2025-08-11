import json
import os
import sys
from iqoptionapi.stable_api import IQ_Option

email = os.environ.get("IQ_EMAIL", "")
password = os.environ.get("IQ_PASSWORD", "")

if not email or not password:
    print(json.dumps({"ok": False, "error": "missing_credentials"}))
    sys.exit(2)

client = IQ_Option(email, password)
client.connect()

if not client.check_connect():
    print(json.dumps({"ok": False, "error": "login_failed"}))
    sys.exit(1)

data = {"ok": True}

try:
    data["balance"] = float(client.get_balance())
    data["account_type"] = client.get_balance_mode()
except Exception as e:
    data["balance_error"] = str(e)

try:
    data["positions"] = {
        "digital": client.get_positions("digital-option") or [],
        "binary": client.get_positions("binary-option") or [],
    }
except Exception as e:
    data["positions_error"] = str(e)

print(json.dumps(data))

