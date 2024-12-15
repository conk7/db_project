-- ADD DATA

CALL add_genre('ActioN'::varchar, 'The action film is a film genre that predominantly features chase sequences, fights, shootouts, explosions, and stunt work.'::text);
CALL add_studio('Wit Studio'::varchar, 'Japanese animation studio founded on June 1, 2012, by producers at Production I.G as a subsidiary of IG Port. It is headquartered in Musashino, Tokyo, with Production I.G producer George Wada as president and Tetsuya Nakatake, also a producer at Production I.G, as a director of the studio. The studio gained notability for producing Attack on Titan (the first three seasons), Great Pretender, Ranking of Kings, Spy × Family, My Deer Friend Nokotan, and the first seasons of The Ancient Magus Bride and Vinland Saga.'::text);
CALL add_anime(
  'Attack on Titan'::TEXT, 
  'Wit Studio'::varchar, 
  'On his first day of junior high, Eren Yeager comes face-to-face with a titan—and has his lunch stolen! From that day on, he holds a grudge against titans for taking his favorite food from him, a cheeseburger, vowing to eliminate their kind once and for all. Along with his adoptive sister Mikasa Ackerman and their friend Armin Arlert, the trio traverse the halls of Titan Junior High, encountering familiar faces and participating in various extracurricular activities as part of the Wall Cleanup Club. A parody of the immensely popular parent series, Shingeki! Kyojin Chuugakkou places beloved characters as junior high school students, fighting to protect their lunches from gluttonous titans.'::text, 
  '2013-04-07'::date, 
  'Action'::varchar, 
  'TV'::anime_type,
  'Finished'::anime_status,
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
SELECT * FROM get_genre_data(1::int, 0::int, 'name'::text, 'asc'::text, 'act'::text);
SELECT * FROM get_studio_data(1::int, 0::int, 'name'::text, 'asc'::text, 'wit'::text);
SELECT * FROM get_anime_data(1::int, 0::int, 'name'::text, 'asc'::text);
SELECT * FROM get_anime_name_locale_data(1::int, 0::int, 'romaji_name'::text, 'asc'::text, 'shingeki'::text);
SELECT * FROM get_character_data(1::int, 0::int, 'name'::text, 'asc'::text, 'Test_Char_Name'::text);



-- DELETE DATA

CALL clear_table('character'::text);
CALL clear_all_tables();
CALL delete_by_pk('anime'::text, 'id'::text, 1::int);
CALL delete_character_by_description('some_desc'::text);


--https://ru-images-s.kinorium.com/movie/1080/678289.jpg?1682675888
--https://fast-anime.ru/storage/uploads/products/28111/2021/08/04/rRgIFWdD9jDrSRkup8t9TJF7go68wpq2ZfsAzFWT.jpeg
--https://fast-anime.ru/storage/uploads/products/28110/2021/08/04/XMN1ccQH9m0q4eg4W25lyvUEjMCF2g5Xo7K1iECS.jpeg
--https://cdn.ananasposter.ru/image/cache/catalog/poster/mult/90/3835-1000x830.jpg