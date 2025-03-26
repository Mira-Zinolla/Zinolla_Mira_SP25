--1. All animation movies released between 2017 and 2019 with rate more than 1, alphabetical


SELECT f.title, f.release_year, f.rental_rate, c.name
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON c.category_id = fc.category_id
WHERE c.name = 'Animation' AND release_year BETWEEN 2017 AND 2019 AND rental_rate>1
ORDER BY title ASC;

-- CTE 

WITH AnimationFilms AS (
SELECT f.film_id, f.title, f.release_year, f.rental_rate
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name = 'Animation'
)
SELECT title, release_year, rental_rate, 'Animation' AS category_name
FROM AnimationFilms
WHERE release_year BETWEEN 2017 AND 2019
AND rental_rate > 1
ORDER BY title;

-- COMMENTS;
--CTE was choosen for its readibility and to avoid repetitions, it also pre-filters only Animation before using release_year and rental_rant


-- The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)

SELECT 
    CONCAT(a.address, ', ', COALESCE(a.address2, '')) AS address, 
    SUM(p.amount) AS revenue
FROM public.payment p
INNER JOIN public.rental r ON p.rental_id = r.rental_id
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.store s ON i.store_id = s.store_id
INNER JOIN public.address a ON s.address_id = a.address_id
WHERE p.payment_date > '2017-03-31'
GROUP BY s.store_id, a.address, a.address2
ORDER BY revenue DESC;



--COMMENTS;
-- CTE here was used to separate revenue calculation logic from the final result presentation. To handle NULL values Coalesce was used.



-- Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)



SELECT 
    f.release_year,
    COUNT(*) FILTER (WHERE UPPER(c.name) = 'DRAMA') AS number_of_drama_movies,
    COUNT(*) FILTER (WHERE UPPER(c.name) = 'TRAVEL') AS number_of_travel_movies,
    COUNT(*) FILTER (WHERE UPPER(c.name) = 'DOCUMENTARY') AS number_of_documentary_movies
FROM public.film f
JOIN public.film_category fc ON f.film_id = fc.film_id
JOIN public.category c ON fc.category_id = c.category_id
WHERE UPPER(c.name) IN ('DRAMA', 'TRAVEL', 'DOCUMENTARY')
GROUP BY f.release_year
ORDER BY f.release_year DESC;



-- SUBQUERY

SELECT a.first_name, a.last_name, 
       (SELECT COUNT(fa.film_id) 
       FROM public.film_actor fa 
     JOIN public.film f ON fa.film_id = f.film_id
    WHERE fa.actor_id = a.actor_id AND f.release_year > 2015) AS number_of_movies
FROM public.actor a
ORDER BY number_of_movies DESC
LIMIT 5;

-- Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)

--CASE

SELECT 
    f.release_year,
    COUNT(CASE WHEN c.name = 'Drama' THEN f.film_id END) AS number_of_drama_movies,
    COUNT(CASE WHEN c.name = 'Travel' THEN f.film_id END) AS number_of_travel_movies,
    COUNT(CASE WHEN c.name = 'Documentary' THEN f.film_id END) AS number_of_documentary_movies
FROM public.film f
JOIN public.film_category fc ON f.film_id = fc.film_id
JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- FILTER
SELECT 
    f.release_year,
    COUNT(*) FILTER (WHERE c.name = 'Drama') AS number_of_drama_movies,
    COUNT(*) FILTER (WHERE c.name = 'Travel') AS number_of_travel_movies,
    COUNT(*) FILTER (WHERE c.name = 'Documentary') AS number_of_documentary_movies
FROM public.film f
JOIN public.film_category fc ON f.film_id = fc.film_id
JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- COMMENTS;
--by applying FILTER directly to COUNT(*) CASE can be avoided. And it also makes it more concise

--CTE 

WITH categorized_films AS (
    SELECT 
        f.release_year,
        c.name AS category
  FROM public.film f
  INNER JOIN public.film_category fc ON f.film_id = fc.film_id
  INNER JOIN public.category c ON fc.category_id = c.category_id
  WHERE c.name IN ('Drama', 'Travel', 'Documentary')
)
SELECT 
    release_year,
    COUNT(*) FILTER (WHERE category = 'Drama') AS number_of_drama_movies,
    COUNT(*) FILTER (WHERE category = 'Travel') AS number_of_travel_movies,
    COUNT(*) FILTER (WHERE category = 'Documentary') AS number_of_documentary_movies
FROM categorized_films
GROUP BY release_year
ORDER BY release_year DESC;

-- 2. Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 

SELECT 
    s.staff_id, 
    s.first_name, 
    s.last_name, 
    st.store_id,  
    SUM(p.amount) AS total_revenue
FROM public.payment p
INNER JOIN public.staff s ON p.staff_id = s.staff_id
INNER JOIN public.store st ON s.store_id = st.store_id  
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017  
GROUP BY s.staff_id, s.first_name, s.last_name, st.store_id
ORDER BY total_revenue DESC
LIMIT 3;








-- Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system


SELECT 
    f.title, 
    COUNT(r.rental_id) AS rental_count, 
    f.rating,
    CASE 
        WHEN f.rating = 'G' THEN 'All Ages'
        WHEN f.rating = 'PG' THEN '10+'
        WHEN f.rating = 'PG-13' THEN '13+'
        WHEN f.rating = 'R' THEN '17+'
        WHEN f.rating = 'NC-17' THEN 'Adults Only (18+)'
        ELSE 'Unknown'
    END AS expected_audience
FROM public.rental r
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
INNER JOIN public.film f ON i.film_id = f.film_id
GROUP BY f.film_id, f.title, f.rating
ORDER BY rental_count DESC
LIMIT 5;





-- 3. Which actors/actresses didn't act for a longer period of time than the others? 
-- V1: gap between the latest release_year and current year per each actor;
SELECT 
    a.actor_id, 
    a.first_name, 
    a.last_name, 
    MAX(f.release_year) AS last_movie_year, 
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS years_since_last_movie
FROM public.actor a
JOIN public.film_actor fa ON a.actor_id = fa.actor_id
JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY years_since_last_movie DESC; 


-- V2: gaps between sequential films per each actor;
--since window functions are not allowed, had to find a different approach. But Iwould also use here LEAD.
SELECT 
    a.actor_id, 
    a.first_name, 
    a.last_name, 
    MAX(f2.release_year - f1.release_year) AS max_gap
FROM public.actor a
JOIN public.film_actor fa1 ON a.actor_id = fa1.actor_id
JOIN public.film f1 ON fa1.film_id = f1.film_id
JOIN public.film_actor fa2 ON a.actor_id = fa2.actor_id
JOIN public.film f2 ON fa2.film_id = f2.film_id
WHERE f2.release_year > f1.release_year  -- Ensure f2 is always after f1
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY max_gap DESC;