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
  name VARCHAR(100) NOT NULL CHECK(LENGTH(name) > 0),
  studio VARCHAR(100) REFERENCES studio(name) ON DELETE CASCADE,
  synopsis TEXT NOT NULL CHECK(LENGTH(synopsis) > 0),
  image_url VARCHAR(1000) CHECK(LENGTH(image_url) > 0),
  premiere_date DATE NOT NULL,
  finale_date DATE,
  airing_period_days INT,
  num_episodes INT CHECK(num_episodes >= 0),
  score FLOAT,
  genre VARCHAR(100) REFERENCES genre(name) ON DELETE CASCADE,
  type anime_type NOT NULL
);

CREATE TABLE anime_name_locale (
  anime_id INT REFERENCES anime(id) ON DELETE CASCADE PRIMARY KEY,
  romaji_name VARCHAR(200),
  english_name VARCHAR(200)
);

CREATE TABLE character (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL CHECK(LENGTH(name) > 0),
  anime_id INT REFERENCES anime(id) ON DELETE CASCADE,
  description TEXT
);



-- INDICES

CREATE INDEX idx_anime_name ON anime(name);
CREATE INDEX idx_locale_romaji_name ON anime_name_locale(romaji_name);
CREATE INDEX idx_locale_english_name ON anime_name_locale(english_name);
CREATE INDEX idx_character_name ON character(name);

COMMIT;