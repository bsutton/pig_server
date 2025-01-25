CREATE TABLE user (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version INTEGER NOT NULL,
    username TEXT UNIQUE NOT NULL,
    description TEXT NOT NULL,
    password TEXT NOT NULL,
    is_administrator INTEGER NOT NULL CHECK (is_administrator IN (0, 1)),
    security_token TEXT,
    token_expiry_date TEXT,
    token_lives_for INTEGER,
    -- Stored as seconds
    email_address TEXT,
    created_date TEXT NOT NULL,
    modified_date TEXT NOT NULL
);
CREATE TABLE end_point (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version INTEGER NOT NULL,
    end_point_name TEXT UNIQUE NOT NULL,
    end_point_type TEXT NOT NULL,
    -- Stores enum as string
    activation_type TEXT NOT NULL,
    -- Stores enum as string
    pin_no INTEGER UNIQUE NOT NULL,
    drain_line INTEGER NOT NULL CHECK (drain_line IN (0, 1)),
    start_amps INTEGER,
    -- Stored as minor units
    running_amps INTEGER,
    -- Stored as minor units
    startup_interval INTEGER,
    -- Stored in seconds
    created_date TEXT NOT NULL,
    modified_date TEXT NOT NULL
);
CREATE TABLE garden_bed (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT NOT NULL,
    next_watering TEXT,
    -- Nullable, stores ISO-8601 date string
    moisture_content INTEGER NOT NULL,
    valve_id INTEGER NOT NULL,
    -- Foreign key to the end_point table
    master_valve_id INTEGER,
    -- Nullable, foreign key to the end_point table
    created_date TEXT NOT NULL,
    modified_date TEXT NOT NULL,
    FOREIGN KEY (valve_id) REFERENCES end_point (id),
    FOREIGN KEY (master_valve_id) REFERENCES end_point (id)
);
CREATE TABLE garden_feature (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_date TEXT NOT NULL,
    modified_date TEXT NOT NULL
);
CREATE TABLE history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    garden_feature_id INTEGER NOT NULL,
    -- Foreign key to garden_feature
    event_start TEXT NOT NULL,
    -- Event start time (ISO 8601)
    event_duration INTEGER,
    -- Duration in seconds
    created_date TEXT NOT NULL,
    modified_date TEXT NOT NULL,
    FOREIGN KEY (garden_feature_id) REFERENCES garden_feature (id)
);
CREATE TABLE lighting (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    light_switch_id INTEGER NOT NULL,
    -- References the end_point table
    created_date TEXT NOT NULL,
    modified_date TEXT NOT NULL,
    FOREIGN KEY (light_switch_id) REFERENCES end_point (id)
);