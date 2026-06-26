from flask import Flask, render_template
import requests

app = Flask(__name__)

# This is the internal Docker DNS name for your API. 
# The browser never sees this URL.
INTERNAL_API_URL = "http://api_server:5000"

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/relics")
def relics():
    try:
        # 1. The Flask server securely asks the API for the data
        response = requests.get(f"{INTERNAL_API_URL}/relics")
        relic_data = response.json()
    except Exception as e:
        relic_data = [] # Fallback if API is unreachable
    
    # 2. Flask injects the data into the HTML and sends a finished webpage to the user
    return render_template("relics.html", relics=relic_data)

if __name__ == "__main__":
    # Runs on port 80 to match what the Load Balancer NGINX config expects
    app.run(host="0.0.0.0", port=80)
