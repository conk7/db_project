BEGIN;

CREATE ROLE basic_role;


GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO basic_role;


GRANT SELECT ON genre TO basic_role;
GRANT SELECT ON studio TO basic_role;
GRANT SELECT ON anime TO basic_role;
GRANT SELECT ON anime_name_locale TO basic_role;
GRANT SELECT ON character TO basic_role;

GRANT INSERT ON genre TO basic_role;
GRANT INSERT ON studio TO basic_role;
GRANT INSERT ON anime TO basic_role;
GRANT INSERT ON anime_name_locale TO basic_role;
GRANT INSERT ON character TO basic_role;

GRANT TRUNCATE ON genre TO basic_role;
GRANT TRUNCATE ON studio TO basic_role;
GRANT TRUNCATE ON anime TO basic_role;
GRANT TRUNCATE ON anime_name_locale TO basic_role;
GRANT TRUNCATE ON character TO basic_role;

GRANT UPDATE ON genre TO basic_role;
GRANT UPDATE ON studio TO basic_role;
GRANT UPDATE ON anime TO basic_role;
GRANT UPDATE ON anime_name_locale TO basic_role;
GRANT UPDATE ON character TO basic_role;

GRANT DELETE ON genre TO basic_role;
GRANT DELETE ON studio TO basic_role;
GRANT DELETE ON anime TO basic_role;
GRANT DELETE ON anime_name_locale TO basic_role;
GRANT DELETE ON character TO basic_role;


GRANT EXECUTE ON PROCEDURE clear_table TO basic_role;
GRANT EXECUTE ON PROCEDURE clear_all_tables TO basic_role;

GRANT EXECUTE ON FUNCTION search_anime_by_english_name TO basic_role;

GRANT EXECUTE ON PROCEDURE add_genre TO basic_role;
GRANT EXECUTE ON PROCEDURE add_studio TO basic_role;
GRANT EXECUTE ON PROCEDURE add_anime TO basic_role;
GRANT EXECUTE ON PROCEDURE add_anime_name_locale TO basic_role;
GRANT EXECUTE ON PROCEDURE add_character TO basic_role;

GRANT EXECUTE ON PROCEDURE update_by_pk TO basic_role;

GRANT EXECUTE ON PROCEDURE delete_character_by_description TO basic_role;
GRANT EXECUTE ON PROCEDURE delete_by_pk TO basic_role;

GRANT EXECUTE ON FUNCTION get_genre_data TO basic_role;
GRANT EXECUTE ON FUNCTION get_studio_data TO basic_role;
GRANT EXECUTE ON FUNCTION get_anime_data TO basic_role;
GRANT EXECUTE ON FUNCTION get_anime_name_locale_data TO basic_role;
GRANT EXECUTE ON FUNCTION get_character_data TO basic_role;
GRANT EXECUTE ON FUNCTION get_all_tables_data TO basic_role;


COMMIT;