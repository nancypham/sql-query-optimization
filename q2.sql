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

-- 2. List the names of students with id in the range of v2 (id) to v3 (inclusive).
EXPLAIN -- ANALYZE
SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3;

-- Doesn't actually speed it up that much
ALTER TABLE Student
ADD INDEX idx_id (id);

SHOW INDEX FROM Student FROM springboardopt;

/*
1. What was the bottleneck? Full table scan
2. How did you identify it? EXPLAIN ANALYZE
3. What method you chose to resolve the bottleneck? Added index on Student id but relatively minimal optimization
*/

/*
FROM:
-> Filter: (student.id between <cache>((@v2)) and <cache>((@v3))) (cost=5.44 rows=44) (actual time=0.024..0.262 rows=278 loops=1)
   -> Table scan on Student (cost=5.44 rows=400) (actual time=0.021..0.216 rows=400 loops=1)
   
TO:
-> Filter: (student.id between <cache>((@v2)) and <cache>((@v3))) (cost=41.00 rows=278) (actual time=0.018..0.265 rows=278 loops=1)
   -> Table scan on Student (cost=41.00 rows=400) (actual time=0.016..0.216 rows=400 loops=1)
-> 
*/