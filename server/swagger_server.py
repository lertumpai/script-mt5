import os
from fastapi import FastAPI
from fastapi.responses import HTMLResponse


OPENAPI_URL = os.getenv("OPENAPI_URL", "http://127.0.0.1:8000/openapi.json")

app = FastAPI(title="Swagger UI Server", docs_url=None, redoc_url=None)


SWAGGER_HTML = f"""
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Swagger UI</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css" />
  </head>
  <body>
    <div id="swagger-ui"></div>
    <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js" crossorigin></script>
    <script>
      window.ui = SwaggerUIBundle({
        url: {OPENAPI_URL!r},
        dom_id: '#swagger-ui',
        presets: [SwaggerUIBundle.presets.apis],
        layout: 'BaseLayout'
      })
    </script>
  </body>
  </html>
"""


@app.get("/", response_class=HTMLResponse)
def swagger_index() -> str:
    return SWAGGER_HTML


