import pandas as pd
import os

# Define the paths to your 3 CSV files
files = {
    "Crash 1": "Crash_Bandicoot.csv",
    "Crash 2": "Crash_Bandicoot_2.csv",
    "Crash 3": "Crash_Bandicoot_3.csv"
}

all_data = []

for game, filename in files.items():
    # Load each file (adjust columns based on your specific CSV structure)
    df = pd.read_csv(filename)
    # Logic: Filter rows that contain level names and their 3 relic times
    # This loop cleans the data into: level, game, sapphire, gold, platinum
    for index, row in df.iterrows():
        # Add logic to append to all_data list
        pass

# Create the final SQL script
with open("init.sql", "w") as f:
    f.write("CREATE TABLE relic_times (level_name VARCHAR(100) PRIMARY KEY, game_version VARCHAR(20), sapphire_time VARCHAR(10), gold_time VARCHAR(10), platinum_time VARCHAR(10));\n")
    for entry in all_data:
        f.write(f"INSERT INTO relic_times VALUES ('{entry[0]}', '{entry[1]}', '{entry[2]}', '{entry[3]}', '{entry[4]}');\n")
