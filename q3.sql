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

-- 3. List the names of students who have taken course v4 (crsCode).
EXPLAIN -- ANALYZE
SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4);

SELECT s.name 
FROM Student as S INNER JOIN
Transcript as T ON t.studID = s.id
WHERE crsCode = @v4;

ALTER TABLE Student
ADD INDEX idx_id (id);

ALTER TABLE Transcript
ADD INDEX idx_crsCode (crsCode);

/*
1. What was the bottleneck? Inner hash join to compare the Student id with the subquery id scans all 400 rows
2. How did you identify it? EXPLAIN ANALYZE
3. What method you chose to resolve the bottleneck? Rewrite to have join instead of subquery and Add indices on 1) id column for Student and 2) crsCode for Transcript
*/

/*
FROM:
-> Inner hash join (student.id = `<subquery2>`.studId) (cost=411.29 rows=400) (actual time=0.341..0.565 rows=2 loops=1)
   -> Table scan on Student (cost=5.04 rows=400) (actual time=0.010..0.202 rows=400 loops=1)
	  -> Hash
		 -> Table scan on <subquery2> (cost=0.05 rows=10) (actual time=0.001..0.001 rows=2 loops=1)
   
TO:
-> Nested loop inner join (cost=1.10 rows=2) (actual time=0.050..0.056 rows=2 loops=1)
   -> Filter: (`<subquery2>`.studId is not null) (cost=0.40 rows=2) (actual time=0.037..0.038 rows=2 loops=1)
	  -> Table scan on <subquery2> (cost=0.40 rows=2) (actual time=0.001..0.001 rows=2 loops=1)
		 -> Materialize with deduplication (cost=0.70 rows=2) (actual time=0.036..0.037 rows=2 loops=1)
-> 
*/