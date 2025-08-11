import os
import sys
import traceback
from dotenv import load_dotenv
import uvicorn


def main() -> None:
    # Load .env if present
    load_dotenv()

    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    log_level = os.getenv("LOG_LEVEL", "info")

    # Import FastAPI app
    from app import app

    print(f"Starting API server on {host}:{port} (log_level={log_level})", flush=True)
    try:
        uvicorn.run(app, host=host, port=port, log_level=log_level)
    except Exception:
        print("FATAL: server crash:\n" + traceback.format_exc(), file=sys.stderr, flush=True)
        raise


if __name__ == "__main__":
    main()


