from flask import Flask
import requests
import os

app = Flask(__name__)

@app.route("/")
def home():
    try:
        # The web server calls the API!
        response = requests.get("http://api_server:8080/info")
        api_data = response.text
    except Exception as e:
        api_data = f"Failed to reach API: {e}"

    server_name = os.environ.get("HOSTNAME", "Unknown Server")
    
    return f"""
    <h1>Hello from {server_name}!</h1>
    <p>I called the API and it said:</p>
    <blockquote style='background: #eee; padding: 10px;'>{api_data}</blockquote>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
