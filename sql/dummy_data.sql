BEGIN;

INSERT INTO genre VALUES ('Action', '123');
INSERT INTO studio VALUES ('Wit Studio', '123');

INSERT INTO anime (name, studio, synopsis, image_url, premiere_date, finale_date, num_episodes, score, genre, type)
VALUES (
  'Attack on Titan', 
  'Wit Studio', 
  'Humans fight titans', 
  'http://example.com/aot.jpg', 
  '2013-04-07', 
  NULL, 
  25, 
  8.9, 
  'Action', 
  'TV'
);

COMMIT;


CALL add_genre('ActioN'::varchar, 'some_desc'::text);
CALL add_studio('Wit Studio'::varchar, 'some_desc'::text);
CALL add_anime(
  'Attack on Titan'::TEXT, 
  'Wit Studio'::varchar, 
  'Humans fight titans'::text, 
  '2013-04-07'::date, 
  'Action'::varchar, 
  'TV'::anime_type,
  'http://example.com/aot.jpg'::TEXT, 
  '2013-04-08'::date,
  25::int, 
  8.9::float
);
CALL add_anime_name_locale(1::int, '進撃の巨人'::TEXT, 'Shingeki no Kyojin'::TEXT);
CALL add_character('Test_char_name'::TEXT, 1::int, 'some_desc'::text); 

CALL delete_by_pk('anime'::text, 'id'::text, 1::int);

call update_by_pk('anime'::text, 'id'::text, 1::int, '{"name": "Attack on Titan", "score": "8.9"}'::JSONB);