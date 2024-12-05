-- ADD DATA

CALL add_genre('ActioN'::varchar, 'The action film is a film genre that predominantly features chase sequences, fights, shootouts, explosions, and stunt work.'::text);
CALL add_studio('Wit Studio'::varchar, 'Japanese animation studio founded on June 1, 2012, by producers at Production I.G as a subsidiary of IG Port. It is headquartered in Musashino, Tokyo, with Production I.G producer George Wada as president and Tetsuya Nakatake, also a producer at Production I.G, as a director of the studio. The studio gained notability for producing Attack on Titan (the first three seasons), Great Pretender, Ranking of Kings, Spy × Family, My Deer Friend Nokotan, and the first seasons of The Ancient Magus Bride and Vinland Saga.'::text);
CALL add_anime(
  'Attack on Titan'::TEXT, 
  'Wit Studio'::varchar, 
  'Humans fight titans'::text, 
  '2013-04-07'::date, 
  'Action'::varchar, 
  'TV'::anime_type,
  'http://example.com/aot.jpg'::TEXT, 
  '2013-08-07'::date,
  25::int, 
  8.9::float
);
CALL add_anime_name_locale(1::int, '進撃の巨人'::TEXT, 'Shingeki no Kyojin'::TEXT);
CALL add_character('Test_char_name'::TEXT, 1::int, 'some_desc'::text); 



-- WORK WITH DATA

CALL update_by_pk('anime'::text, 'id'::text, 1::int, '{"name": "Attack on Titan", "score": "8.9"}'::JSONB);
SELECT * FROM search_anime_by_english_name('titan'::text);
SELECT * FROM get_all_tables_data();



-- DELETE DATA

CALL clear_table('character'::text);
CALL clear_all_tables();
CALL delete_by_pk('anime'::text, 'id'::text, 1::int);
CALL delete_character_by_description('some_desc'::text);