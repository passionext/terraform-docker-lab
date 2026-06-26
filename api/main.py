from fastapi import FastAPI
from prometheus_client import make_asgi_app, Counter

app = FastAPI()

# Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

REQUEST_COUNT = Counter('api_requests_total', 'Total API requests')

RELIC_TIMES = [
    {"level": "N. Sanity Beach", "sapphire": "1:05.00", "gold": "0:45.00", "platinum": "0:30.00"},
    {"level": "Jungle Rollers", "sapphire": "1:15.00", "gold": "0:55.00", "platinum": "0:40.00"},
    {"level": "The Great Gate", "sapphire": "1:20.00", "gold": "1:00.00", "platinum": "0:45.00"},
    {"level": "Boulders", "sapphire": "1:10.00", "gold": "0:50.00", "platinum": "0:41.00"},
    {"level": "Upstream", "sapphire": "1:25.00", "gold": "1:05.00", "platinum": "0:50.00"}
]

@app.get("/")
def read_root():
    REQUEST_COUNT.inc()
    return {"status": "Internal API is running secretly!"}

@app.get("/relics")
def get_relic_times():
    REQUEST_COUNT.inc()
    return RELIC_TIMES
