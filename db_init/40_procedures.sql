BEGIN;

-- CLEAR TABLES

CREATE OR REPLACE PROCEDURE clear_table(table_name_arg TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = table_name_arg
    ) THEN
        RAISE EXCEPTION 'Table "%" does not exist', table_name_arg;
    END IF;

    EXECUTE format('TRUNCATE %I CASCADE', table_name_arg);
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
END;
$$;



-- SEARCH

CREATE OR REPLACE FUNCTION search_anime_by_english_name(english_name_arg TEXT)
RETURNS TABLE (
    id INT,
    anime_name TEXT,
    anime_studio VARCHAR,
    anime_synopsis TEXT,
    anime_image_url TEXT,
    anime_premiere_date DATE,
    anime_finale_date DATE,
    anime_num_episodes INT,
    anime_score NUMERIC(4, 2),
    anime_genre VARCHAR,
    anime_type anime_type,
    anime_status anime_status,
    anime_updated_at TIMESTAMP
)
LANGUAGE plpgsql AS $$
BEGIN
    IF english_name_arg IS NULL THEN
        RAISE EXCEPTION 'Search term cannot be null';
    END IF;

    RETURN QUERY
    SELECT *
    FROM anime
    WHERE LOWER(name) ILIKE '%' || LOWER(english_name_arg) || '%';
END;
$$;



-- INSERT DATA

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
    anime_name TEXT,
    anime_studio VARCHAR,
    anime_synopsis TEXT,
    anime_premiere_date DATE,
    anime_genre VARCHAR,
    anime_type anime_type,
    anime_status anime_status,
    anime_image_url TEXT,
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
        type,
		status
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
        anime_type,
        anime_status
    );
END;
$$;

CREATE OR REPLACE PROCEDURE add_anime_name_locale(
    anime_id_arg INT,
    japanese_name_arg TEXT DEFAULT NULL,
    romaji_name_arg TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    IF anime_id_arg IS NULL THEN
        RAISE EXCEPTION 'Anime ID cannot be null';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM anime WHERE id = anime_id_arg) THEN
        RAISE EXCEPTION 'Anime ID % does not exist in the anime table', anime_id_arg;
    END IF;
    
    INSERT INTO anime_name_locale (anime_id, japanese_name, romaji_name)
    VALUES (anime_id_arg, japanese_name_arg, romaji_name_arg)
    ON CONFLICT (anime_id) DO NOTHING;
END;
$$;

CREATE OR REPLACE PROCEDURE add_character(
    character_name TEXT,
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



-- UPDATE DATA

CREATE OR REPLACE PROCEDURE update_by_pk(
    table_name_arg TEXT,
    pk_column TEXT,
    pk_value TEXT,  
    updates JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    pk_exists BOOLEAN;
    is_primary_key BOOLEAN;
    update_query TEXT;
    update_columns TEXT;
    key TEXT;
    value TEXT;
    pk_type TEXT;
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = table_name_arg
          AND table_type = 'BASE TABLE'
    ) THEN 
        RAISE EXCEPTION 'Table "%" does not exist', table_name_arg;
    END IF;
    
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = table_name_arg 
          AND column_name = pk_column
    ) THEN 
        RAISE EXCEPTION 'Column "%" does not exist', pk_column;
    END IF;

    SELECT data_type INTO pk_type
    FROM information_schema.columns
    WHERE table_name = table_name_arg
      AND column_name = pk_column;

    CASE pk_type
        WHEN 'integer' THEN
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1::int)', table_name_arg, pk_column)
                INTO pk_exists
                USING pk_value::int;
        WHEN 'bigint' THEN
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1::bigint)', table_name_arg, pk_column)
                INTO pk_exists
                USING pk_value::bigint;
        WHEN 'varchar' THEN
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1::varchar)', table_name_arg, pk_column)
                INTO pk_exists
                USING pk_value::varchar;
        ELSE
            RAISE EXCEPTION 'Unsupported primary key type: %', pk_type;
    END CASE;

    IF NOT pk_exists THEN
        RAISE EXCEPTION 'No such pk value "%" was found', pk_value;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_name = kcu.table_name
        WHERE tc.table_name = table_name_arg
          AND tc.constraint_type = 'PRIMARY KEY'
          AND kcu.column_name = pk_column
    ) INTO is_primary_key;

    IF NOT is_primary_key THEN
        RAISE EXCEPTION 'Column "%" is not a primary key in table "%"', pk_column, table_name_arg;
    END IF;

    update_columns := '';
    FOR key, value IN
        SELECT * FROM jsonb_each_text(updates)
    LOOP
        IF update_columns != '' THEN
            update_columns := update_columns || ', ';
        END IF;
        update_columns := update_columns || format('%I = %L', key, value);
    END LOOP;

    EXECUTE format(
        'UPDATE %I SET %s WHERE %I = $1::%s',
        table_name_arg,
        update_columns,
        pk_column,
        pk_type
    ) USING pk_value;
END;
$$;



-- DELETE DATA

CREATE OR REPLACE PROCEDURE delete_character_by_description(
    target_description TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    IF target_description IS NULL OR LENGTH(target_description) = 0 THEN
        RAISE EXCEPTION 'Description cannot be null or empty';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM character WHERE description = target_description) THEN
        RETURN;
    END IF;

    DELETE FROM character
    WHERE description = target_description;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_by_pk(
    table_name_arg TEXT,
    pk_column TEXT,
    pk_value TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    pk_exists BOOLEAN;
    is_primary_key BOOLEAN;
    pk_type TEXT;
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_name = table_name_arg
          AND table_type = 'BASE TABLE'
    ) THEN 
        RAISE EXCEPTION 'Table "%" does not exist', table_name_arg;
    END IF;
    
    IF NOT EXISTS (
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = table_name_arg 
          AND column_name = pk_column
    ) THEN 
        RAISE EXCEPTION 'Column "%" does not exist', pk_column;
    END IF;

    SELECT data_type INTO pk_type
    FROM information_schema.columns
    WHERE table_name = table_name_arg
      AND column_name = pk_column;

    CASE pk_type
        WHEN 'integer' THEN
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1::int)', table_name_arg, pk_column)
                INTO pk_exists
                USING pk_value::int;
        WHEN 'bigint' THEN
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1::bigint)', table_name_arg, pk_column)
                INTO pk_exists
                USING pk_value::bigint;
        WHEN 'varchar' THEN
            EXECUTE format('SELECT EXISTS (SELECT 1 FROM %I WHERE %I = $1::varchar)', table_name_arg, pk_column)
                INTO pk_exists
                USING pk_value::varchar;
        ELSE
            RAISE EXCEPTION 'Unsupported primary key type: %', pk_type;
    END CASE;

    IF NOT pk_exists THEN
        RAISE EXCEPTION 'No such pk value "%" was found', pk_value;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_name = kcu.table_name
        WHERE tc.table_name = table_name_arg
          AND tc.constraint_type = 'PRIMARY KEY'
          AND kcu.column_name = pk_column
    ) INTO is_primary_key;

    IF NOT is_primary_key THEN
        RAISE EXCEPTION 'Column "%" is not a primary key in table "%"', pk_column, table_name_arg;
    END IF;

    EXECUTE format(
        'DELETE FROM %I WHERE %I = $1::%s',
        table_name_arg,
        pk_column,
        pk_type
    ) USING pk_value;
END;
$$;



-- GET DATA

CREATE OR REPLACE FUNCTION get_genre_data(
    p_limit INT,
    p_offset INT DEFAULT 0,
    p_sort_column TEXT DEFAULT 'name',
    p_sort_direction TEXT DEFAULT 'ASC',
    p_search_term TEXT DEFAULT NULL
) 
RETURNS TABLE (
    name VARCHAR,
    description TEXT
) AS $$
BEGIN
    IF LOWER(p_sort_direction) NOT IN ('asc', 'desc') THEN
        RAISE EXCEPTION 'Invalid sort direction. Use ASC or DESC';
    END IF;
    
    RETURN QUERY EXECUTE format(
        'SELECT *
         FROM genre
         WHERE ($3 IS NULL OR name ILIKE $3 OR description ILIKE $3)
         ORDER BY %I %s
         LIMIT $1 OFFSET $2',
         p_sort_column, p_sort_direction
    ) USING p_limit, p_offset, CASE WHEN p_search_term IS NOT NULL THEN '%' || p_search_term || '%' ELSE NULL END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_studio_data(
    p_limit INT,
    p_offset INT DEFAULT 0,
    p_sort_column TEXT DEFAULT 'name',
    p_sort_direction TEXT DEFAULT 'ASC',
    p_search_term TEXT DEFAULT NULL
) 
RETURNS TABLE (
    name VARCHAR,
    description TEXT
) AS $$
BEGIN
    IF LOWER(p_sort_direction) NOT IN ('asc', 'desc') THEN
        RAISE EXCEPTION 'Invalid sort direction. Use ASC or DESC';
    END IF;

    RETURN QUERY EXECUTE format(
        'SELECT *
         FROM studio
         WHERE ($3 IS NULL OR name ILIKE $3 OR description ILIKE $3)
         ORDER BY %I %s
         LIMIT $1 OFFSET $2',
         p_sort_column, p_sort_direction
    ) USING p_limit, p_offset, CASE WHEN p_search_term IS NOT NULL THEN '%' || p_search_term || '%' ELSE NULL END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_anime_data(
    p_limit INT,
    p_offset INT DEFAULT 0,
    p_sort_column TEXT DEFAULT 'id',
    p_sort_direction TEXT DEFAULT 'ASC'
) 
RETURNS TABLE (
    id INT,
    name TEXT,
    studio VARCHAR,
    synopsis TEXT,
    image_url TEXT,
    premiere_date DATE,
    finale_date DATE,
    num_episodes INT,
    score NUMERIC(4, 2),
    genre VARCHAR,
    type anime_type,
    status anime_status,
    updated_at TIMESTAMP
) AS $$
BEGIN
    IF LOWER(p_sort_direction) NOT IN ('asc', 'desc') THEN
        RAISE EXCEPTION 'Invalid sort direction. Use ASC or DESC';
    END IF;
    
    RETURN QUERY EXECUTE format(
        'SELECT *
         FROM anime
         ORDER BY %I %s
         LIMIT $1 OFFSET $2',
         p_sort_column, p_sort_direction
    ) USING p_limit, p_offset;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_anime_name_locale_data(
    p_limit INT,
    p_offset INT DEFAULT 0,
    p_sort_column TEXT DEFAULT 'anime_id',
    p_sort_direction TEXT DEFAULT 'ASC',
    p_search_term TEXT DEFAULT NULL
) 
RETURNS TABLE (
    anime_id INT,
    japanese_name TEXT,
    romaji_name TEXT
) AS $$
BEGIN
    IF LOWER(p_sort_direction) NOT IN ('asc', 'desc') THEN
        RAISE EXCEPTION 'Invalid sort direction. Use ASC or DESC';
    END IF;

    RETURN QUERY EXECUTE format(
        'SELECT *
         FROM anime_name_locale
         WHERE ($3 IS NULL OR japanese_name ILIKE $3 OR romaji_name ILIKE $3)
         ORDER BY %I %s
         LIMIT $1 OFFSET $2',
         p_sort_column, p_sort_direction
    ) USING p_limit, p_offset, CASE WHEN p_search_term IS NOT NULL THEN '%' || p_search_term || '%' ELSE NULL END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_character_data(
    p_limit INT,
    p_offset INT DEFAULT 0,
    p_sort_column TEXT DEFAULT 'id',
    p_sort_direction TEXT DEFAULT 'ASC',
    p_search_term TEXT DEFAULT NULL
) 
RETURNS TABLE (
    id INT,
    name TEXT,
    anime_id INT,
    description TEXT
) AS $$
BEGIN
    IF LOWER(p_sort_direction) NOT IN ('asc', 'desc') THEN
        RAISE EXCEPTION 'Invalid sort direction. Use ASC or DESC';
    END IF;

    RETURN QUERY EXECUTE format(
        'SELECT *
         FROM character
         WHERE ($3 IS NULL OR name ILIKE $3 OR description ILIKE $3)
         ORDER BY %I %s
         LIMIT $1 OFFSET $2',
         p_sort_column, p_sort_direction
    ) USING p_limit, p_offset, CASE WHEN p_search_term IS NOT NULL THEN '%' || p_search_term || '%' ELSE NULL END;
END;
$$ LANGUAGE plpgsql;

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

COMMIT;