SELECT * FROM spotify_data LIMIT 10;

--1. Which is the longest song released yet?
SELECT 
    song_title,
    ROUND(duration_ms * 0.0000166667, 2) AS duration_min
FROM spotify_data
ORDER BY duration_min DESC
LIMIT 1;

--2. How many songs has Drake sung?
SELECT COUNT(*) AS drake_songs
FROM spotify_data
WHERE artist LIKE '%Drake%';

--3. List those songs with letter ‘Love’ in them.
SELECT song_title
FROM spotify_data
WHERE song_title ILIKE '%Love%';

--4. Select songs which have a number in them.
SELECT song_title, artist
FROM spotify_data
WHERE REGEXP_LIKE(song_title, '.*[0-9].*');

--5. You have a bachelorette weekend, which songs would you play the most?
SELECT song_title
FROM spotify_data
WHERE song_title ILIKE '%Love%';
--OR
SELECT
    song_title,
    artist,
    energy,
    danceability
FROM SPOTIFY_DATA
ORDER BY
    (energy + danceability) DESC
LIMIT 15;

--6. In a dance battle, which 3 songs would you choose for a dance off ?

SELECT 
    song_title,
    artist,
    danceability,
    energy
FROM spotify_data
ORDER BY danceability DESC, energy DESC
LIMIT 3;

--7. Which artist has the max songs released?
SELECT 
    artist,
    COUNT(*) AS total_songs
FROM spotify_data
GROUP BY artist
ORDER BY total_songs DESC
LIMIT 1;

--8. Make a ‘break-up’ song list
SELECT 
    song_title,
    artist,
    MODE,
    energy
FROM spotify_data
ORDER BY MODE, energy ASC
LIMIT 5;
