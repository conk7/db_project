BEGIN;

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

CREATE OR REPLACE FUNCTION format_synopsis()
RETURNS TRIGGER AS $$
BEGIN
    NEW.synopsis := TRIM(' ' FROM NEW.synopsis);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
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

CREATE OR REPLACE TRIGGER format_anime_synopsis_trigger
BEFORE INSERT OR UPDATE ON anime
FOR EACH ROW
EXECUTE FUNCTION format_synopsis();

CREATE OR REPLACE TRIGGER format_character_name_trigger
BEFORE INSERT OR UPDATE ON character
FOR EACH ROW
EXECUTE FUNCTION format_and_capitalize_name();

CREATE OR REPLACE TRIGGER set_updated_at_trigger
BEFORE INSERT OR UPDATE ON anime
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

COMMIT;