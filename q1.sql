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

-- 1. List the name of the student with id equal to v1 (id).
EXPLAIN -- ANALYZE
SELECT name FROM Student WHERE id = @v1;

# Index added
ALTER TABLE Student
ADD INDEX idx_id (id);

/*
1. What was the bottleneck? Filtering by student.id
2. How did you identify it? EXPLAIN ANALYZE
3. What method you chose to resolve the bottleneck? Adding index on Student table for id column
*/

/* 
FROM:
-> Filter: (student.id = <cache>((@v1))) (cost=41.00 rows=40) (actual time=0.078..0.286 rows=1 loops=1)
   -> Table scan on Student (cost=41.00 rows=400) (actual time=0.022..0.247 rows=400 loops=1)
   
TO:
-> Index lookup on Student using idx_id (id=(@v1)) (cost=0.35 rows=1) (actual time=0.023..0.026 rows=1 loops=1)
*/