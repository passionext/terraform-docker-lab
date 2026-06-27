-- 1. Create the table structure
CREATE TABLE IF NOT EXISTS relic_times (
    level_name VARCHAR(100) PRIMARY KEY,
    game_version VARCHAR(20),
    sapphire_time VARCHAR(10),
    gold_time VARCHAR(10),
    platinum_time VARCHAR(10)
);

-- 2. Import the CSV data
-- The file must be mounted at the path specified below
COPY relic_times(level_name, game_version, sapphire_time, gold_time, platinum_time)
FROM '/docker-entrypoint-initdb.d/all_relics.csv'
DELIMITER ','
CSV HEADER;
