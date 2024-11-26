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

COMMIT;