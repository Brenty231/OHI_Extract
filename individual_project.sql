CREATE DATABASE OHI;
USE OHI;
DROP TABLE IF EXISTS Goal;
DROP TABLE IF EXISTS Subgoal;
DROP TABLE IF EXISTS Region;
DROP TABLE IF EXISTS Ocean_Health;
DROP TABLE IF EXISTS ocean_health_src;
DROP TABLE IF EXISTS goal_src;
DROP TABLE IF EXISTS region_src;
DROP TABLE IF EXISTS subgoal_src;
DROP TABLE IF EXISTS India_Measurement;
			
/* Use table data import wizard to upload source tables */

UPDATE ocean_health_src
SET value=NULL
WHERE value='NA';

DELETE FROM ocean_health_src
WHERE dimension NOT IN('future', 'pressures', 'resilience', 'score', 'status', 'trend');

CREATE TABLE Goal (
    goal_id VARCHAR(5) PRIMARY KEY,
    goal_description VARCHAR(50)
);

CREATE TABLE Subgoal (
    subgoal_id VARCHAR(5) PRIMARY KEY,
    goal_id VARCHAR(5),
    FOREIGN KEY (goal_id) REFERENCES Goal(goal_id)
);

CREATE TABLE Region (
    region_id TINYINT UNSIGNED PRIMARY KEY,
    region_name VARCHAR(100)
);

CREATE TABLE Ocean_Health (
    year INTEGER,
    goal_id VARCHAR(5),
    dimension VARCHAR(25) CHECK(dimension IN ('future', 'pressures', 'resilience', 'score', 'status', 'trend')),
    region_id TINYINT UNSIGNED,
    value DECIMAL(10,2),
    PRIMARY KEY(year, goal_id, dimension, region_id),
    FOREIGN KEY (goal_id) REFERENCES Goal(goal_id),
    FOREIGN KEY (region_id) REFERENCES Region(region_id)
    
);

INSERT INTO Goal
SELECT * FROM goal_src;

INSERT INTO Subgoal
SELECT * FROM subgoal_src;

INSERT INTO Region
SELECT * FROM region_src;

INSERT INTO Ocean_Health
SELECT * FROM ocean_health_src;	

/*3*/

SELECT year, goal_description, dimension, value, region_name 
FROM Ocean_Health
INNER JOIN Region
ON Ocean_Health.region_id=Region.region_id
INNER JOIN Goal
ON Ocean_Health.goal_id=Goal.goal_id
WHERE region_name='Cocos Islands' AND goal_description='Coastal Protection' AND year=2021;
/* The future dimension value is different than the current status dimension
because the pressures, resilience, and trend dimensions come together
to forecast a future status score based on the current status. 
Then the current/future status scores are averaged to form an overall goal score. */


/*4*/

SELECT DISTINCT year, value
FROM Ocean_Health
WHERE dimension='score'
AND goal_id='index'
AND (value=(SELECT MAX(value) FROM Ocean_Health WHERE dimension='score' AND goal_id='index') 
    OR value=(SELECT MIN(value) FROM Ocean_Health WHERE dimension='score' AND goal_id='index'))
ORDER BY year ASC, value DESC;

/*5*/

CREATE TABLE South_America(
							Country VARCHAR(100));
INSERT INTO South_America VALUES ('Argentina'), ('Bolivia'), ('Brazil'), 
('Chile'), ('Colombia'),  ('Ecuador'), 
('Guyana'), ('Paraguay'), ('Peru'), ('Suriname'), ('Uruguay'), ('Venezuela');

SELECT Country
FROM South_America
WHERE Country NOT IN (SELECT region_name
					  FROM Region)
                      ORDER BY Country ASC;
                      
DROP TABLE IF EXISTS South_America;                      

/*6*/

SELECT year, Ocean_Health.goal_id, goal_description, dimension, Ocean_Health.region_id, region_name, value
FROM Ocean_Health INNER JOIN Goal ON Ocean_Health.goal_id = Goal.goal_id
INNER JOIN Region ON Ocean_Health.region_id = Region.region_id
WHERE goal_description = 'Biodiversity' AND dimension = 'score' AND value IN (SELECT 
																			 MAX(value) FROM Ocean_Health
                                                                             WHERE goal_id = 'BD' AND dimension = 'score'
                                                                             GROUP BY year);
/*7*/

CREATE TABLE Fishing AS SELECT
year, Ocean_Health.goal_id, goal_description, dimension, Ocean_Health.region_id,region_name, value
FROM Ocean_Health
INNER JOIN Goal ON Ocean_Health.goal_id=Goal.goal_id
INNER JOIN Region ON Ocean_Health.region_id=Region.region_id
WHERE goal_description LIKE '%fish%' AND dimension='status' AND year=2021;

ALTER TABLE Fishing
ADD fishing_status VARCHAR(5);

UPDATE Fishing 
SET fishing_status='VISIT'
WHERE value>=90;

UPDATE Fishing 
SET fishing_status='AVOID'
WHERE value<=10;

SELECT * FROM Fishing
WHERE fishing_status='VISIT' OR fishing_status='AVOID'
ORDER BY value DESC, region_id ASC;

DROP TABLE IF EXISTS Fishing;

/*8*/

SELECT goal_id, goal_description
FROM Goal
WHERE goal_id NOT IN(SELECT subgoal_id FROM Subgoal);

/*9*/

SELECT sg.subgoal_id, g.goal_description AS subgoal_description, sg.goal_id, gg.goal_description
FROM subgoal sg JOIN Goal g ON sg.subgoal_id=g.goal_id 
JOIN Goal gg ON sg.goal_id=gg.goal_id
ORDER BY goal_description, subgoal_description;

/*10*/

CREATE TABLE India_Measurement(
								 region_id TINYINT UNSIGNED,
                                 region_name VARCHAR(100),
                                 goal_id VARCHAR(5),
                                 goal_description VARCHAR(50),
                                 dimension VARCHAR(25) CHECK(dimension IN ('future', 'pressures', 'resilience', 'score', 'status', 'trend')),
                                 value_2012 DECIMAL(10,2),
                                 value_2015 DECIMAL(10,2),
                                 value_2018 DECIMAL(10,2),
                                 value_2021 DECIMAL(10,2));


INSERT INTO India_Measurement
SELECT Ocean_Health.region_id, region_name, Ocean_Health.goal_id, goal_description, dimension,
SUM(CASE WHEN year=2012 THEN value ELSE 0 END) AS value_2012,
SUM(CASE WHEN year=2015 THEN value ELSE 0 END) AS value_2015,
SUM(CASE WHEN year=2018 THEN value ELSE 0 END) AS value_2018,
SUM(CASE WHEN year=2021 THEN value ELSE 0 END) AS value_2021
FROM Ocean_Health 
INNER JOIN Goal ON Ocean_Health.goal_id=Goal.goal_id
INNER JOIN Region ON Ocean_Health.region_id=Region.region_id
WHERE region_name='India' AND(dimension='status' OR dimension='trend')
GROUP BY Ocean_Health.region_id, region_name, Ocean_Health.goal_id, goal_description, dimension;

SELECT * FROM India_Measurement;