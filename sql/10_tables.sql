BEGIN;

CREATE TYPE anime_type AS ENUM (
'TV', 
'Movie',
'OVA',
'ONA',
'Other'
);



-- SCHEMAS

CREATE TABLE genre (
  name VARCHAR(100) PRIMARY KEY CHECK(LENGTH(name) > 0),
  description TEXT
);

CREATE TABLE studio (
  name VARCHAR(100) PRIMARY KEY CHECK(LENGTH(name) > 0),
  description TEXT
);

CREATE TABLE anime (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL CHECK(LENGTH(name) > 0),
  studio VARCHAR(100) REFERENCES studio(name) ON DELETE CASCADE,
  synopsis TEXT NOT NULL CHECK(LENGTH(synopsis) > 0),
  image_url TEXT NOT NULL CHECK(LENGTH(image_url) > 0),
  premiere_date DATE NOT NULL,
  finale_date DATE CHECK(finale_date > premiere_date),
  num_episodes INT CHECK(num_episodes >= 0),
  score NUMERIC(4, 2) CHECK(0 <= score and score <= 10),
  genre VARCHAR(100) REFERENCES genre(name) ON DELETE CASCADE,
  type anime_type NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE anime_name_locale (
  anime_id INT REFERENCES anime(id) ON DELETE CASCADE PRIMARY KEY,
  romaji_name TEXT,
  english_name TEXT
);

CREATE TABLE character (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL CHECK(LENGTH(name) > 0),
  anime_id INT REFERENCES anime(id) ON DELETE CASCADE,
  description TEXT
);



-- INDICES

-- CREATE INDEX idx_anime_name ON anime(name);
-- CREATE INDEX idx_locale_romaji_name ON anime_name_locale(romaji_name);
CREATE INDEX idx_locale_english_name ON anime_name_locale(english_name);
-- CREATE INDEX idx_character_name ON character(name);
CREATE INDEX idx_character_description ON character(description);

COMMIT;