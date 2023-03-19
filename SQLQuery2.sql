-- Check data has been sucessufully imported 
SELECT * FROM dbo.literacy;
SELECT * FROM dbo.area_pop;

-- calculate total number of rows in our dataset , Dataset_name : india_census
SELECT COUNT(*) FROM india_census..literacy;
SELECT COUNT(*) FROM india_census..area_pop;

-- DATASET : Generating data for UTTARAHAND and UTTARPRADESH
SELECT * FROM india_census..literacy WHERE state IN ('uttarakhand','uttar pradesh');

-- Calculate total popultaion of india using area_population dataset 
SELECT sum(population) AS total_india_population FROM dbo.area_pop;

-- Average growth of india 
SELECT AVG(growth) as india_avg FROM india_census..literacy;

-- Average growth as per state 
SELECT state,AVG(growth) as average_growth FROM india_census..literacy GROUP BY state;

-- Average sex ratio per state IN descending order of sex ratio
SELECT state, round(AVG(sex_ratio),0) as average_sex_ratio FROM india_census..literacy GROUP BY state ORDER BY average_sex_ratio DESC;

-- Select state with literacy rate greater than 90 , order by avg literacy 
SELECT state, ROUND(avg(literacy),0) as average_literacy FROM india_census..literacy 
GROUP BY state HAVING ROUND(avg(literacy),0)>90
order by average_literacy DESC;

-- TOP 3 states with highest average growth rate 
SELECT TOP 3 state, ROUND(AVG(growth),0) avg_growth FROM india_census..literacy 
GROUP BY state 
ORDER BY avg_growth DESC;
-- same thing can be done using limit 
SELECT state, ROUND(AVG(growth),0) avg_growth FROM india_census..literacy 
GROUP BY state ORDER BY avg_growth DESC limit 3;

--Bottom 3 states with lowest sex ratio 
SELECT TOP 3 state, ROUND(AVG(sex_ratio),0) avg_SR FROM india_census..literacy 
GROUP BY state
ORDER by avg_SR;


-- Top 3 and bottom 3 state (literacy)
-- Create temporary table with top 3 state and literacy rate 
DROP table if exists #top_state;
CREATE table #top_state
( state nvarchar(50),
topstate float)

insert into #top_state 
SELECT top 3 state, ROUND(AVG(literacy),0) avg_literacy FROM india_census..literacy 
GROUP BY state 
ORDER BY avg_literacy DESC;

SELECT * FROM #top_state ORDER BY topstate DESC;

 -- Create temporary table with bottom 3 state and literacy rate 
DROP table if exists #bottom_state;
CREATE table #bottom_state
( state nvarchar(50),
bottomstate float)

insert into #bottom_state 
SELECT top 3 state, ROUND(AVG(literacy),0) avg_literacy FROM india_census..literacy 
GROUP BY state 
ORDER BY avg_literacy;

SELECT * FROM #bottom_state ORDER BY bottomstate ASC;

-- combine both results with UNION 
SELECT * FROM #bottom_state
UNION 
SELECT * FROM #top_state;

--Display state name starting with letter A 
SELECT distinct state FROM india_census..literacy WHERE lower(state) LIKE 'a%';

--Display state name starting with letter A or B
SELECT distinct state FROM india_census..literacy WHERE lower(state) LIKE 'a%' OR lower(state) LIKE 'b%';

-- Display state name starting with letter A and end with H
SELECT distinct state FROM india_census..literacy WHERE lower(state) LIKE 'a%' AND lower(state) LIKE '%H';




-- CALCULATE total number of males and females [DISTRICT WISE]
SELECT l.district,l.state, l.sex_ratio,a.population 
FROM india_census..literacy l inner join india_census..area_pop a ON l.district = a.district;

/* females / males = sex_ratio
population = females + males 
females =  population - males 
(population-males)= sex_ratio * males 

males = population/(sex_ratio+1)
females = population - population/(sex_ratio+1)
*/
SELECT c.district,c.state,ROUND(c.population/(c.sex_ratio+1),0) AS Males_count, ROUND((c.population * c.sex_ratio)/(c.sex_ratio+1),0) as Female_count 
FROM 
(SELECT a.district,a.state, a.sex_ratio/1000 as sex_ratio,b.population 
FROM india_census..literacy a inner join india_census..area_pop b 
ON a.district = b.district) c


-- CALCULATE total number of males and females [STATE WISE]
SELECT d.state, sum(d.males) as total_male, sum(d.females) as total_female FROM
(SELECT c.district,c.state,ROUND(c.population/(c.sex_ratio+1),0) AS males, ROUND((c.population * c.sex_ratio)/(c.sex_ratio+1),0) as females
FROM 
(SELECT a.district,a.state, a.sex_ratio/1000 as sex_ratio,b.population 
FROM india_census..literacy a inner join india_census..area_pop b 
ON a.district = b.district)  c ) d
GROUP BY d.state;


-- CALCULATE literate populatioN [DISTRICT WISE ]
SELECT a.district, a.state, b.literacy,a.population 
FROM india_census..area_pop a INNER JOIN india_census..literacy b ON a.district = b.district;

/* Literacy rate is percantage of the population which s literate 
total_literate_people = literacy ratio * popualtion
total_illiterate_peopel = population - (literacy_rate *pop)*/
SELECT c.district,c.state,ROUND((c.lit_rate*c.population),0) AS total_literate_people, round(((1-c.lit_rate)*c.population),0) AS total_illeterate FROM 
(SELECT a.district, a.state, b.literacy/100 AS lit_rate ,a.population 
FROM india_census..area_pop a INNER JOIN india_census..literacy b ON a.district = b.district)c



-- CALCULATE literate population [STATE WISE ]
SELECT d.state,sum(d.total_literate_people) AS lit_people , sum(total_illeterate) as illlit_people FROM 
(SELECT c.state,ROUND((c.lit_rate*c.population),0) AS total_literate_people, round(((1-c.lit_rate)*c.population),0) AS total_illeterate FROM 
(SELECT a.district, a.state, b.literacy/100 AS lit_rate ,a.population 
FROM india_census..area_pop a INNER JOIN india_census..literacy b ON a.district = b.district) c ) d
GROUP BY d.state;



-- CALCULATE Population from previous census 
/* 
prev_census + growth * prev_census = current total population 
prev_census _pop = population / (1+growth)*/

--   [DISTRICT WISE]
SELECT c.district,c.growth , c.population , ROUND(c.population/(1+c.growth),0) as previous_census_population 
FROM 
(SELECT a.district,a.growth ,b.population FROM india_census..literacy a INNER JOIN india_census..area_pop b ON a.district=b.district) c

--   [STATE WISE ] 
SELECT d.state,sum(previous_census_population) as prev_total_pop , sum(d.population) AS current_popualtion FROM
(
SELECT c.state,c.district,c.growth , c.population , ROUND(c.population/(1+c.growth),0) as previous_census_population 
FROM 
(SELECT a.state,a.district,a.growth ,b.population FROM india_census..literacy a INNER JOIN india_census..area_pop b ON a.district=b.district) c)d
 GROUP BY d.state;

 -- CALCULATE POPULATION V/S AREA [for prev year and current year ]
 --How  Area per population has reduced from previous year to this year ?
 SELECT p.total_area/p.prev_pop as prevoius_pop_per_area, p.total_area/p.curr_pop as current_pop_per_area FROM 
 (SELECT q.*,r.total_area FROM (
 SELECT '1' AS keyy,g.* FROM 
 (SELECT SUM(f.prev_total_pop) as prev_pop , sum(f.current_popualtion) as curr_pop FROM
(SELECT d.state,sum(previous_census_population) as prev_total_pop , sum(d.population) AS current_popualtion 
FROM(SELECT c.state,c.district,c.growth , c.population , ROUND(c.population/(1+c.growth),0) as previous_census_population 
FROM (SELECT a.state,a.district,a.growth ,b.population FROM india_census..literacy a INNER JOIN india_census..area_pop b ON a.district=b.district) c)d
GROUP BY d.state)f)g ) q inner join (
SELECT '1' AS keyy,m.* FROM 
(SELECT SUM(area_Km2) as total_area  FROM india_census..area_pop)m) r ON q.keyy = r.keyy)p


-- TOP 3 districts from each state with highest literacy rate 
--using window function 
SELECT a.* from (
SELECT district, state , literacy , rank() over(partition by state order by literacy desc)as rnk FROM india_census..literacy) a
where rnk in (1,2,3) order by state;

