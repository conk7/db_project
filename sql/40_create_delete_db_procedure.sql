BEGIN;

CREATE OR REPLACE PROCEDURE create_db()
LANGUAGE plpgsql AS $$
BEGIN
    CREATE TYPE anime_type AS ENUM (
    'TV', 
    'Movie',
    'OVA',
    'ONA',
    'Other'
    );



    -- SCHEMAS

    CREATE TABLE IF NOT EXISTS genre (
        name VARCHAR(100) PRIMARY KEY CHECK(LENGTH(name) > 0),
        description TEXT
    );

    CREATE TABLE IF NOT EXISTS studio (
        name VARCHAR(100) PRIMARY KEY CHECK(LENGTH(name) > 0),
        description TEXT
    );

    CREATE TABLE IF NOT EXISTS anime (
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

    CREATE TABLE IF NOT EXISTS anime_name_locale (
        anime_id INT REFERENCES anime(id) ON DELETE CASCADE PRIMARY KEY,
        romaji_name VARCHAR(200),
        english_name VARCHAR(200)
    );

    CREATE TABLE IF NOT EXISTS character (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL CHECK(LENGTH(name) > 0),
        anime_id INT REFERENCES anime(id) ON DELETE CASCADE,
        description TEXT
    );



    -- INDICES

    CREATE INDEX IF NOT EXISTS idx_anime_name ON anime(name);
    CREATE INDEX IF NOT EXISTS idx_locale_romaji_name ON anime_name_locale(romaji_name);
    CREATE INDEX IF NOT EXISTS idx_locale_english_name ON anime_name_locale(english_name);
    CREATE INDEX IF NOT EXISTS idx_character_name ON character(name);



    -- FUNCTIONS

    CREATE OR REPLACE FUNCTION format_and_capitalize_name()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.name := INITCAP(TRIM(' ' FROM NEW.name));
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION format_name()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.name := TRIM(' ' FROM NEW.name);
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION format_description()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.description := TRIM(' ' FROM NEW.description);
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION update_airing_period_days()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.airing_period_days := NEW.finale_date - NEW.premiere_date;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;



    CREATE OR REPLACE TRIGGER format_genre_name_trigger
    BEFORE INSERT OR UPDATE ON genre
    FOR EACH ROW
    EXECUTE FUNCTION format_and_capitalize_name();

    CREATE OR REPLACE TRIGGER format_studio_name_trigger
    BEFORE INSERT OR UPDATE ON studio
    FOR EACH ROW
    EXECUTE FUNCTION format_name();

    CREATE OR REPLACE TRIGGER format_anime_name_trigger
    BEFORE INSERT OR UPDATE ON anime
    FOR EACH ROW
    EXECUTE FUNCTION format_name();

    CREATE OR REPLACE TRIGGER format_anime_description_trigger
    BEFORE INSERT OR UPDATE ON anime
    FOR EACH ROW
    EXECUTE FUNCTION format_description();

    CREATE OR REPLACE TRIGGER format_character_name_trigger
    BEFORE INSERT OR UPDATE ON character
    FOR EACH ROW
    EXECUTE FUNCTION format_and_capitalize_name();

    CREATE OR REPLACE TRIGGER set_airing_period_days_trigger
    BEFORE INSERT OR UPDATE ON anime
    FOR EACH ROW
    EXECUTE FUNCTION update_airing_period_days();



    -- CLEAR TABLES

    CREATE OR REPLACE PROCEDURE clear_table(table_name_arg TEXT)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_name = table_name_arg
        ) THEN
            EXECUTE format('TRUNCATE %I CASCADE', table_name_arg);
            RAISE NOTICE 'Table "%" has been cleared', table_name_arg;
        ELSE
            RAISE NOTICE 'Table "%" does not exist', table_name_arg;
        END IF;
    END;
    $$;

    CREATE OR REPLACE PROCEDURE clear_all_tables()
    LANGUAGE plpgsql
    AS $$
    BEGIN
        TRUNCATE genre CASCADE;
        TRUNCATE studio CASCADE;
        TRUNCATE anime CASCADE;
        TRUNCATE anime_name_locale CASCADE;
        TRUNCATE character CASCADE;

        RAISE NOTICE 'All tables have been cleared';
    END;
    $$;



    -- SEARCH

    CREATE OR REPLACE PROCEDURE search_anime_by_english_name(english_name_arg TEXT)
    LANGUAGE plpgsql
    AS $$
    DECLARE rec record;
    BEGIN
        IF english_name_arg IS NULL OR LENGTH(english_name_arg) = 0 THEN
            RAISE EXCEPTION 'Search term cannot be null or empty';
        END IF;

        PERFORM *
        FROM anime a
        JOIN anime_name_locale anl ON a.id = anl.anime_id
        WHERE anl.english_name ILIKE '%' || english_name_arg || '%';

        IF NOT FOUND THEN
            RAISE NOTICE 'No anime found with English name containing "%"', english_name_arg;
            RETURN;
        END IF;

        FOR rec IN 
            SELECT 
                a.id,
                COALESCE(anl.romaji_name, 'N/A') AS romaji_name, 
                COALESCE(anl.english_name, 'N/A') AS english_name, 
                a.name AS original_name, 
                a.studio, 
                a.synopsis, 
                a.image_url, 
                a.premiere_date, 
                a.finale_date, 
                a.airing_period_days, 
                a.num_episodes, 
                a.score, 
                a.genre, 
                a.type
            FROM anime a
            JOIN anime_name_locale anl ON a.id = anl.anime_id
            WHERE anl.english_name ILIKE '%' || english_name_arg || '%'
        LOOP
            RAISE NOTICE 'ID: %, Romaji Name: %, English Name: %, Original Name: %, Studio: %, Synopsis: %, Image URL: %, Premiere Date: %, Finale Date: %, Airing Period Days: %, Episodes: %, Score: %, Genre: %, Type: %',
                        rec.id, rec.romaji_name, rec.english_name, rec.original_name, rec.studio, rec.synopsis, rec.image_url, 
                        rec.premiere_date, rec.finale_date, rec.airing_period_days, rec.num_episodes, rec.score, rec.genre, rec.type;
        END LOOP;
    END;
    $$;



    -- ADD NEW DATA

    CREATE OR REPLACE PROCEDURE add_genre(
        genre_name VARCHAR,
        genre_description TEXT DEFAULT NULL
    )
    LANGUAGE plpgsql AS $$
    BEGIN
        IF genre_name IS NULL OR LENGTH(genre_name) = 0 THEN
            RAISE EXCEPTION 'Genre name cannot be null or empty';
        END IF;
        
        INSERT INTO genre (name, description)
        VALUES (genre_name, genre_description)
        ON CONFLICT (name) DO NOTHING;
    END;
    $$;

    CREATE OR REPLACE PROCEDURE add_studio(
        studio_name VARCHAR,
        studio_description TEXT DEFAULT NULL
    )
    LANGUAGE plpgsql AS $$
    BEGIN
        IF studio_name IS NULL OR LENGTH(studio_name) = 0 THEN
            RAISE EXCEPTION 'Studio name cannot be null or empty';
        END IF;
        
        INSERT INTO studio (name, description)
        VALUES (studio_name, studio_description)
        ON CONFLICT (name) DO NOTHING;
    END;
    $$;

    CREATE OR REPLACE PROCEDURE add_anime(
        anime_name VARCHAR,
        anime_studio VARCHAR,
        anime_synopsis TEXT,
        anime_premiere_date DATE,
        anime_genre VARCHAR,
        anime_type anime_type,
        anime_image_url VARCHAR DEFAULT NULL,
        anime_finale_date DATE DEFAULT NULL,
        anime_num_episodes INT DEFAULT 0,
        anime_score FLOAT DEFAULT NULL
    )
    LANGUAGE plpgsql AS $$
    BEGIN
        IF anime_name IS NULL OR LENGTH(anime_name) = 0 THEN
            RAISE EXCEPTION 'Anime name cannot be null or empty';
        END IF;
        
        IF anime_synopsis IS NULL OR LENGTH(anime_synopsis) = 0 THEN
            RAISE EXCEPTION 'Synopsis cannot be null or empty';
        END IF;
        
        IF anime_image_url IS NULL OR LENGTH(anime_image_url) = 0 THEN
            RAISE EXCEPTION 'Image URL cannot be null or empty';
        END IF;
        
        IF anime_premiere_date IS NULL THEN
            RAISE EXCEPTION 'Premiere date cannot be null';
        END IF;

        IF anime_score IS NULL THEN
            RAISE EXCEPTION 'Score cannot be null';
        END IF;
        
        INSERT INTO anime (
            name,
            studio,
            synopsis,
            image_url,
            premiere_date,
            finale_date,
            num_episodes,
            score,
            genre,
            type
        ) VALUES (
            anime_name,
            anime_studio,
            anime_synopsis,
            anime_image_url,
            anime_premiere_date,
            anime_finale_date,
            anime_num_episodes,
            anime_score,
            anime_genre,
            anime_type
        );
    END;
    $$;

    CREATE OR REPLACE PROCEDURE add_anime_name_locale(
        anime_id_arg INT,
        romaji_name_arg VARCHAR(200) DEFAULT NULL,
        english_name_arg VARCHAR(200) DEFAULT NULL
    )
    LANGUAGE plpgsql AS $$
    BEGIN
        IF anime_id_arg IS NULL THEN
            RAISE EXCEPTION 'Anime ID cannot be null';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM anime WHERE id = anime_id_arg) THEN
            RAISE EXCEPTION 'Anime ID % does not exist in the anime table', anime_id_arg;
        END IF;
        
        INSERT INTO anime_name_locale (anime_id, romaji_name, english_name)
        VALUES (anime_id_arg, romaji_name_arg, english_name_arg)
        ON CONFLICT (anime_id) DO NOTHING;
    END;
    $$;

    CREATE OR REPLACE PROCEDURE add_character(
        character_name VARCHAR,
        anime_id_arg INT,
        character_description TEXT DEFAULT NULL
    )
    LANGUAGE plpgsql AS $$
    BEGIN
        IF character_name IS NULL OR LENGTH(character_name) = 0 THEN
            RAISE EXCEPTION 'Character name cannot be null or empty';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM anime WHERE id = anime_id_arg) THEN
            RAISE EXCEPTION 'Anime ID % does not exist in the anime table', anime_id_arg;
        END IF;

        INSERT INTO character (name, anime_id, description)
        VALUES (character_name, anime_id_arg, character_description);
    END;
    $$;


    -- DELETE VALUES

    CREATE OR REPLACE PROCEDURE delete_character_by_description(
        target_description TEXT
    )
    LANGUAGE plpgsql AS $$
    BEGIN
        IF target_description IS NULL OR LENGTH(target_description) = 0 THEN
            RAISE EXCEPTION 'Description cannot be null or empty';
        END IF;

        IF NOT EXISTS (SELECT 1 FROM character WHERE description = target_description) THEN
            RAISE NOTICE 'No character found with the provided description: %', target_description;
            RETURN;
        END IF;

        DELETE FROM character
        WHERE description = target_description;

        -- DELETE FROM character
        -- WHERE description LIKE '%' || target_description || '%';

        RAISE NOTICE 'Characters with description "%", have been deleted', target_description;
    END;
    $$;

    CREATE OR REPLACE PROCEDURE delete_by_pk(
        table_name TEXT,
        pk_column_name TEXT,
        pk_value ANYELEMENT
    )
    LANGUAGE plpgsql AS $$
    BEGIN
        IF table_name IS NULL OR LENGTH(table_name) = 0 THEN
            RAISE EXCEPTION 'Table name cannot be null or empty';
        END IF;
        
        IF pk_column_name IS NULL OR LENGTH(pk_column_name) = 0 THEN
            RAISE EXCEPTION 'Primary key column name cannot be null or empty';
        END IF;

        EXECUTE format(
            'DELETE FROM %I WHERE %I = $1',
            table_name, pk_column_name
        ) USING pk_value;

        RAISE NOTICE 'Row with % = % has been deleted from table %', pk_column_name, pk_value, table_name;
    END;
    $$;



    -- GET ALL TABLES DATA

    CREATE OR REPLACE FUNCTION get_all_tables_data()
    RETURNS TABLE(table_name TEXT, row_data JSONB) AS $$
    DECLARE
        tbl RECORD;
        sql TEXT;
    BEGIN
        FOR tbl IN
            SELECT t.table_schema || '.' || t.table_name AS full_table_name
            FROM information_schema.tables t
            WHERE t.table_schema NOT IN ('information_schema', 'pg_catalog')
            AND t.table_type = 'BASE TABLE'
        LOOP
            sql := FORMAT(
                'SELECT ''%s'' AS table_name, row_to_json(t)::JSONB AS row_data FROM %s t',
                tbl.full_table_name, tbl.full_table_name
            );
            RETURN QUERY EXECUTE sql;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_db()
LANGUAGE plpgsql AS $$
BEGIN
    DROP TYPE IF EXISTS anime_type CASCADE;

    DROP TABLE IF EXISTS genre CASCADE;
    DROP TABLE IF EXISTS studio CASCADE;
    DROP TABLE IF EXISTS anime CASCADE;
    DROP TABLE IF EXISTS anime_name_locale CASCADE;
    DROP TABLE IF EXISTS character CASCADE;


    DROP PROCEDURE IF EXISTS clear_table;
    DROP PROCEDURE IF EXISTS clear_all_tables;
    DROP PROCEDURE IF EXISTS search_anime_by_english_name;
    DROP PROCEDURE IF EXISTS add_genre;
    DROP PROCEDURE IF EXISTS add_studio;
    DROP PROCEDURE IF EXISTS add_anime;
    DROP PROCEDURE IF EXISTS add_anime_name_locale;
    DROP PROCEDURE IF EXISTS add_character;
    DROP PROCEDURE IF EXISTS delete_character_by_description;
    DROP PROCEDURE IF EXISTS delete_by_pk;
END;
$$;

COMMIT;