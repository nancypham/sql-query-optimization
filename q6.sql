USE springboardopt;

-- -------------------------------------
SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';

-- 6. List the names of students who have taken all courses offered by department v8 (deptId).
# Original query
EXPLAIN -- ANALYZE
SELECT name FROM Student,
	(SELECT studId
	FROM Transcript
		WHERE crsCode IN
		(SELECT crsCode FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))
		GROUP BY studId
		HAVING COUNT(*) = 
			(SELECT COUNT(*) FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))) as alias
WHERE id = alias.studId;

# New query
EXPLAIN -- ANALYZE
WITH cte1 AS
	(SELECT crsCode
		FROM Course
			JOIN Teaching USING(crsCode)
		WHERE deptId = @v8)

SELECT name FROM Student,
	(SELECT studId
	FROM Transcript
		JOIN cte1 USING(crsCode)
	GROUP BY studId
	HAVING COUNT(*) = (SELECT COUNT(*) FROM cte1)) as alias
WHERE id = alias.studId;

# Indexes added
CREATE INDEX idx_id ON Student (id);
CREATE INDEX idx_crsCode ON Transcript (crsCode);
CREATE INDEX idx_crsCode ON Course (crsCode);
CREATE INDEX idx_crsCode ON Teaching (crsCode);

/*
1. What was the bottleneck? Alias query's WHERE clause, similar subqueries 'SELECT .. FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching)', full table scan on Student
2. How did you identify it? EXPLAIN and EXPLAIN ANALYZE
3. What method you chose to resolve the bottleneck? 1) Create CTE for similar subqueries, 2) Add indexes
*/

/*
FROM:
-> Nested loop inner join (actual time=5.233..5.233 rows=0 loops=1)
   -> Filter: (student.id is not null) (cost=41.00 rows=400) (actual time=0.022..0.268 rows=400 loops=1)
	  -> Table scan on Student (cost=41.00 rows=400) (actual time=0.021..0.224 rows=400 loops=1)
   -> Index lookup on alias using <auto_key0> (studId=student.id) (actual time=0.000..0.000 rows=0 loops=400)
	  -> Materialize (actual time=0.012..0.012 rows=0 loops=400)
		 -> Filter: (count(0) = (select #5)) (actual time=4.734..4.734 rows=0 loops=1)
			-> Table scan on <temporary> (actual time=0.000..0.002 rows=19 loops=1)
			   -> Aggregage using temporary table (actual time=4.728..4.731 rows=19 loops=1)
				  -> Nested loop inner join (cost=1020.25 rows=10000) (actual time=0.522..0.680 rows=19 loops=1)
				     -> Filter: (transcript.crsCode is not null) (cost=10.25 rows=100) (actual time=0.005..0.101 rows=100 loops=1)
						-> Table scan on Transcript (cost=10.25 rows=100) (actual time=0.005..0.087 rows=100 loops=1)
					 -> Single-row index lookup on <subquery3> using <auto_distinct_key> (crsCode=transcript.crsCode) (actual time=0.001..0.001 rows=0 loops=100)
						-> Materialize with deduplication (cost=110.52 rows=100) (actual time=0.006..0.006 rows=0 loops=100)
						   -> Filter: (course.crsCode is not null) (cost=110.52 rows=100) (actual time=0.150..0.238 rows=19 loops=1)
							  -> Filter: (teaching.crsCode = course.crsCode) (cost=110.52 rows=100) (actual time=0.149..0.235 rows=19 loops=1)
								 -> Inner hash join (<hash>(teaching.crsCode)=<hash>(course.crsCode)) (cost=110.52 rows=100) (actual time=0.149..0.229 rows=19 loops=1)
									-> Table scan on Teaching (cost=0.13 rows=100) (actual time=0.004..0.060 rows=100 loops=1)
									-> Hash
									   -> Filter: (course.deptId = <cache>((@v8))) (cost=10.25 rows=10) (actual time=0.014..0.096 rows=19 loops=1)
										  -> Table scan on Course (cost=10.25 rows=100) (actual time=0.005..0.074 rows=100 loops=1)
			-> Select #5 (subquery in condition; uncacheable)
			   -> Aggregate: count(0) (actual time=0.207..0.207 rows=1 loops=19)
				  -> Nested loop inner join (cost=111.25 rows=1000) (actual time=0.113..0.205 rows=19 loops=19)
					 -> Filter: ((course.deptId = <cache>((@v8))) and (course.crsCode is not null)) (cost=10.25 rows=10) (actual time=0.003..0.075 rows=19 loops=19)
						-> Table scan on Course (cost=10.25 rows=100) (actual time=0.002..0.057 rows=100 loops=19)
					 -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=course.crsCode) (actual time=0.000..0.001 rows=1 loops=361)
						-> Materialize with deduplication (cost=10.25 rows=100) (actual time=0.006..0.007 rows=1 loops=361)
						   -> Filter: (teaching.crsCode is not null) (cost=10.25 rows=100) (actual time=0.002..0.067 rows=100 loops=19)
							  -> Table scan on Teaching (cost=10.25 rows=100) (actual time=0.001..0.055 rows=100 loops=19)
		 -> Select #5 (subquery in projection; uncacheable)
			-> Aggregate: count(0) (actual time=0.207..0.207 rows=1 loops=19)
				  -> Nested loop inner join (cost=111.25 rows=1000) (actual time=0.113..0.205 rows=19 loops=19)
					 -> Filter: ((course.deptId = <cache>((@v8))) and (course.crsCode is not null)) (cost=10.25 rows=10) (actual time=0.003..0.075 rows=19 loops=19)
						-> Table scan on Course (cost=10.25 rows=100) (actual time=0.002..0.057 rows=100 loops=19)
					 -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=course.crsCode) (actual time=0.000..0.001 rows=1 loops=361)
						-> Materialize with deduplication (cost=10.25 rows=100) (actual time=0.006..0.007 rows=1 loops=361)
						   -> Filter: (teaching.crsCode is not null) (cost=10.25 rows=100) (actual time=0.002..0.067 rows=100 loops=19)
							  -> Table scan on Teaching (cost=10.25 rows=100) (actual time=0.001..0.055 rows=100 loops=19)

TO:
-> Nested loop inner join (actual time=0.340..0.340 rows=0 loops=1)
   -> Filter: (alias.studId is not null) (actual time=0.339..0.339 rows=0 loops=1)
	  -> Table scan on alias (cost=4.64 rows=19) (actual time=0.001..0.001 rows=0 loops=1)
		 -> Materialize (actual time=0.339..0.339 rows=0 loops=1)
			-> Filter: (count(0) = (select #4)) (actual time=0.331..0.331 rows=0 loops=1)
			   -> Table scan on <temporary> (actual time=0.000..0.002 rows=19 loops=1)
				  -> Aggregage using temporary table (actual time=0.325..0.328 rows=19 loops=1)
					 -> Nested loop inner join (cost=11.49 rows=20) (actual time=0.121..0.186 rows=19 loops=1)
						-> Filter: (cte1.crsCode is not null) (cost=4.64 rows=19) (actual time=0.114..0.120 rows=19 loops=1)
						   -> Table scan on cte1 (cost=4.64 rows=19) (actual time=0.001..0.003 rows=19 loops=1)
							  -> Materialize CTE cte1 if needed (cost=9.38 rows=20) (actual time=0.113..0.117 rows=19 loops=1)
								 -> Nested loop inner join (cost=9.38 rows=20) (actual time=0.029..0.103 rows=19 loops=1)
									-> Filter: (course.crsCode is not null) (cost=2.65 rows=19) (actual time=0.021..0.049 rows=19 loops=1)
									   -> Index lookup on Course using idx_deptId (deptId=(@v8)) (cost=2.65 rows=19) (actual time=0.020..0.046 rows=19 loops=1)
									-> Index lookup on Teaching using idx_crsCode (crsCode=course.crsCode) (cost=0.26 rows=1) (actual time=0.002..0.002 rows=1 loops=19)
						-> Index lookup on Transcript using idx_crsCode (crsCode=cte1.crsCode) (cost=0.26 rows=1) (actual time=0.002..0.003 rows=1 loops=19)
			   -> Select #4 (subquery in condition; uncacheable)                        
				  -> Aggregage: count(0) (actual time=0.005..0.005 rows=1 loops=19)
					 -> Table scan on cte1 (cost=4.64 rows=19) (actual time=0.000..0.002 rows=19 loops=19)
						-> Materialize CTE cte1 if needed (query plan printed elsewhere) (cost=9.38 rows=20) (actual time=0.000..0.004 rows=19 loops=19)
			-> Select #4 (subquery in condition; uncacheable)
			   -> Aggregage: count(0) (actual time=0.005..0.005 rows=1 loops=19)
				  -> Table scan on cte1 (cost=4.64 rows=19) (actual time=0.000..0.002 rows=19 loops=19)
					 -> Materialize CTE cte1 if needed (query plan printed elsewhere) (cost=9.38 rows=20) (actual time=0.000..0.004 rows=19 loops=19)
   -> Index lookup on Student using idx_id (id=alias.studId) (cost=0.26 rows=1) (never executed)
*/