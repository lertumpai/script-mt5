from pathlib import Path
import json
from fastapi.testclient import TestClient
from app import app


def main() -> None:
    client = TestClient(app)
    schema = client.get("/openapi.json").json()
    out = Path(__file__).parent / "openapi.json"
    out.write_text(json.dumps(schema, indent=2))
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()


