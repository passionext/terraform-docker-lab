from fastapi import FastAPI
from datetime import datetime

app = FastAPI()

@app.get("/info")
async def read_root():
	now = datetime.now()
	return {"Message": f"Congrats! You got access on: {now}"}
