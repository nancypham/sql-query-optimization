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

-- 5. List the names of students who have taken a course from department v6 (deptId), but not v7.
EXPLAIN ANALYZE
SELECT * FROM Student, 
	(SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode
	AND studId NOT IN
	(SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) as alias
WHERE Student.id = alias.studId;

# Indexes added
CREATE INDEX idx_id ON Student (id);
CREATE INDEX idx_dept_crs ON Course (deptId, crsCode);
CREATE INDEX idx_crsCode ON Transcript (crsCode);

/*
1. What was the bottleneck? 1) Filtering for whether transcript.studId exists in subquery (subquery in alias table) and 2) Finding where student.id matches transcript.studId
2. How did you identify it? EXPLAIN and EXPLAIN ANALYZE
3. What method you chose to resolve the bottleneck? Add indexes
*/

/*
FROM:
-> Filter: <in_optimize>(transcript.studId,<exists>(select #3) is false) (cost=4112.69 rows=4000) (actual time=0.604..6.451 rows=30 loops=1)
   -> Inner hash join (student.id = transcript.studId) (cost=4112.69 rows=4000) (actual time=0.275..0.577 rows=30 loops=1)
      -> Table scan on Student (cost=0.06 rows=400) (actual time=0.006..0.228 rows=400 loops=1)
	  -> Hash
         -> Filter: (transcript.crsCode = course.crsCode) (cost=110.52 rows=100) (actual time=0.145..0.249 rows=30 loops=1)
			-> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode)) (cost=110.52 rows=100) (actual time=0.144..0.241 rows=30 loops=1)
			   -> Table scan on Transcript (cost=0.13 rows=100) (actual time=0.005..0.074 rows=100 loops=1)
               -> Hash
				  -> Filter: (course.deptId = <cache>((@v6))) (cost=10.25 rows=10) (actual time=0.026..0.113 rows=26 loops=1)
					 -> Table scan on Course (cost=10.25 rows=100) (actual time=0.021..0.082 rows=100 loops=1)
   -> Select #3 (subquery in condition; dependent)
	  -> Limit: 1 row(s) (actual time=0.192..0.192 rows=0 loops=30)
		 -> Filter: <if>(outer_field_is_not_null, <is_not_null_test>(transcript.studId), true) (actual time=0.192..0.192 rows=0 loops=30)
			-> Filter: (<if>(outer_field_is_not_null, ((<cache>(transcript.studId) = transcript.studId) or (transcript.studId is null)), true) and (transcript.crsCode = course.crsCode)) (cost=110.52 rows=100) (actual time=0.191..0.191 rows=0 loops=30)
			   -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode)) (cost=110.52 rows=100) (actual time=0.1409..0.187 rows=34 loops=30)
               -> Table scan on Transcript (cost=0.13 rows=100) (actual time=0.002..0.057 rows=100 loops=30)
               -> Hash
				  -> Filter: (course.deptId = <cache>((@v7))) (cost=10.25 rows=10) (actual time=0.007..0.071 rows=32 loops=30)
					 -> Table scan on Course (cost=10.25 rows=100) (actual time=0.003..0.056 rows=100 loops=30)

TO:
-> Nested loop inner join (cost=23.18 rows=27) (actual time=0.199..0.445 rows=30 loops=1)
   -> Nested loop inner join (cost=13.79 rows=27) (actual time=0.189..0.347 rows=30 loops=1)
	  -> Filter: (course.crsCode is not null) (cost=4.41 rows=26) (actual time=0.015..0.035 rows=26 loops=1)
		 -> Index lookup on Course using idx_dept_crs (deptId=(@v6)) (cost=4.41 rows=26) (actual time=0.015..0.031 rows=26 loops=1)
	  -> Filter: (<in_optimizer>(transcript.studId,transcript.studId in (select #3) is false) and (transcript.studId is not null)) (cost=0.26 rows=1) (actual time=0.010..0.012 rows=1 loops=26)
		 -> Index lookup on Transcript using idx_crsCode (crsCode=course.crsCode) (cost=0.26 rows=1) (actual time=0.003..0.004 rows=1 loops=26)
         -> Select #3 (subquery in condition; run only once)
			-> Filter: ((transcript.studId = `<materialized_subquery>`.studId)) (actual time=0.001..0.001 rows=0 loops=31)
			   -> Limit: 1 row(s) (actual time=0.001..0.001 rows=0. loops=31)
				  -> Materialize with deduplication (cost=16.93 rows=33) (actual time=0.006..0.006 rows=0 loops=31)
					 -> Nested loop inner join (cost=16.93 rows=33) (actual time=0.010..0.138 rows=34 loops=1)
						-> Filter: (course.crsCode is not null)) (cost=5.39 rows=32) (actual time=0.004..0.028 rows=32 loops=1)
						   -> Index lookup on Course using idx_dept_crs (deptId=(@v7)) (cost=5.39 rows=32) (actual time=0.004..0.024 rows=32 loops=1)
						-> Index lookup on Transcript using idx_crsCode (crsCode=course.crsCode) (cost=0.26 rows=1) (actual time=0.002..0.003 rows=1 loops=32)
   -> Index lookup on Student using idx_id (id=transcript.studId) (cost=0.25 rows=1) (actual time=0.003..0.003 rows=1 loops=30)
*/