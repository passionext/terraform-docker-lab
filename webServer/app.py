from flask import Flask, render_template
import psycopg2
from psycopg2.extras import RealDictCursor
from itertools import groupby
from operator import itemgetter
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)

# Initialize the exporter
metrics = PrometheusMetrics(app)

# Direct Database Connection Function
def get_db_connection():
    return psycopg2.connect(
        host="postgres_db",
        database="app_db",
        user="admin",
        password="secretpassword"
    )

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/relics")
def relics():
    try:
        # 1. Connect directly to Postgres
        conn = get_db_connection()
        # RealDictCursor automatically formats SQL rows into Python dictionaries
        cur = conn.cursor(cursor_factory=RealDictCursor) 
        cur.execute("SELECT level_name, game_version, sapphire_time, gold_time, platinum_time FROM relic_times;")
        relic_data = cur.fetchall()
        cur.close()
        conn.close()

        # Convert to a standard list of dictionaries
        relic_data = [dict(row) for row in relic_data]

        # 2. Sort the data by game version
        relic_data.sort(key=itemgetter('game_version'))
        
        # 3. Group the data into a dictionary: {'Crash 1': [...], 'Crash 2': [...]}
        grouped_relics = {}
        for key, group in groupby(relic_data, key=itemgetter('game_version')):
            grouped_relics[key] = list(group)
            
    except Exception as e:
        print(f"Database error: {e}") # This will show up in `docker logs web_server_0` if it fails
        grouped_relics = {} 
    
    # Send the grouped data to the HTML
    return render_template("relics.html", grouped_relics=grouped_relics)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
