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

-- 4. List the names of students who have taken a course taught by professor v5 (name).
EXPLAIN ANALYZE
SELECT name FROM Student,
	(SELECT studId FROM Transcript,
		(SELECT crsCode, semester FROM Professor
			JOIN Teaching
			WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1
	WHERE Transcript.crsCode = alias1.crsCode AND Transcript.semester = alias1.semester) as alias2
WHERE Student.id = alias2.studId;

CREATE INDEX idx_profId ON Teaching (profId);
CREATE INDEX idx_semester ON Transcript (semester);
CREATE INDEX idx_name ON Professor (name);
CREATE INDEX idx_id ON Student (id);

/*
1. What was the bottleneck? Inner hash joins all have high cost and execution time of 2+
2. How did you identify it? EXPLAIN ANALYZE
3. What method you chose to resolve the bottleneck? Add 4 indexes on columns used for inner hash joins
*/

/*
FROM:
-> Inner hash join (student.id = transcript.studId) (cost=1313.72 rows=160) (actual time=2.398..2.398 rows=0 loops=1)
   -> Table scan on Student (cost=0.03 rows=400) (never executed)
   -> Hash
	  -> Inner hash join (professor.id = teaching.profId) (cost=1144.90 rows=4) (actual time=2.385..2.385 rows=0 loops=1)
         -> Filter: (professor.`name` = <cache>((@v5))) (cost=0.95 rows=4) (never executed)
            -> Table scan on Professor (cost=0.95 rows=400) (never executed)
		 -> Hash
            -> Filter: ((teaching.semester = transcript.semester) and (teacher.crsCode = transcript.crsCode)) (cost.1010.70 rows=100) (actual time=2.190..2.190 rows=0 loops=1)
			   -> Inner hash join (<hash>(teaching.semester)=<hash>(transcript.semester)), (<hash>(teaching.crsCode)=<hash>(transcript.crsCode)) (cost=1010.70 rows=100) (actual time=2.189..2.189 rows=0 loops=1)
                  -> Table scan on Teaching (cost=0.01 rows=100) (actual time=1.088..1.145 rows=100 loops=1)
                  -> Hash
                     -> Table scan on Transcript (cost=10.25 rows=100) (actual time=0.871..0.932 rows=100 loops=1)

TO:
-> Nested loop inner join (cost=1.07 rows=0) (actual time=0.053..0.053 rows=0 loops=1)
   -> Nested loop inner join (cost=1.06 rows=0) (actual time=0.052..0.052 rows=0 loops=1)
      -> Nested loop inner join (cost=0.70 rows=1) (actual time=0.041..0.046 rows=1 loops=1)
         -> Filter: (professor.id is not null) (cost=0.35 rows=1) (actual time=0.032..0.033 rows=1 loops=1)
            -> Index lookup on Professor using idx_name (name=(@v5)) (cost=0.35 rows=1) (actual time=0.031..0.032 rows=1 loops=1)
		 -> Filter: (teaching.semester is not null) (cost=0.35 rows=1) (actual time=0.008..0.011 rows=1 loops=1)
            -> Index lookup on Teaching using idx_profId (profId=professor.id) (cost=0.35 rows=1) (actual time=0.008..0.011 rows=1 loops=1)
         -> Filter: ((transcript.crsCode = teacher.crsCode) and (transcript.studId is not null)) (cost=0.26 rows=0) (actual time=0.006..0.006 rows=0 loops=1)
            -> Index lookup on Transcript using idx_semester (semester=teaching.semester) (cost=0.26 rows=1) (actual time=0.006..0.006 rows=0 loops=1)
            -> Index lookup on Student using idx_id (id=transcript.studId) (cost=2.25 rows=1) (never executed)
*/