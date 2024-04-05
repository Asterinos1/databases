--FUNCTION PART

CREATE OR REPLACE FUNCTION add_person_entries(num_entries integer) RETURNS void AS
$$
DECLARE
    i integer := 0;
    max_amka bigint;
    p_amka character varying;
    p_name character varying;
    p_father_name character varying;
    p_surname character varying;
    p_email character varying;
    p_city_id integer;
    p_sys_data timestamp;
BEGIN
    -- Get the maximum "amka" value and convert it to bigint
    SELECT COALESCE(MAX(CAST(amka AS bigint)), 0) INTO max_amka FROM "Person";
    
    WHILE i < num_entries LOOP
        max_amka := max_amka + 1; -- Increment the amka value
        p_amka := max_amka::varchar; -- Convert back to character varying
        p_name := 'Junk Name ' || i;
        p_father_name := 'Junk Father Name ' || i;
        p_surname := 'Junk Surname ' || i;
        p_email := 'junkemail' || i || '@example.com';
        p_city_id := floor(random() * 10) + 1; -- Generate a random city id between 1 and 10
        p_sys_data := now(); -- Set the current timestamp
        
        -- Insert a new entry with generated values
        INSERT INTO "Person" (amka, name, father_name, surname, email, city_id, sys_data)
        VALUES (p_amka, p_name, p_father_name, p_surname, p_email, p_city_id, p_sys_data);
        
        i := i + 1;
    END LOOP;
    
    RAISE NOTICE 'Added % entries to Person table.', num_entries;
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Error occurred while adding entries: %', SQLERRM;
		
END;
$$
LANGUAGE plpgsql;

select add_person_entries(100000);

SELECT COUNT(*) AS entry_count FROM "Person";

CREATE OR REPLACE FUNCTION add_program_entries(num_entries integer) RETURNS void AS
$$
DECLARE
    i integer := 0;
    max_program_id integer;
BEGIN
    -- Get the maximum "ProgramID" value and increment it
    SELECT COALESCE(MAX("ProgramID"), 0) + 1 INTO max_program_id FROM "Program";
    
    WHILE i < num_entries LOOP
		max_program_id := max_program_id +1;
        -- Generate a new program id
        INSERT INTO "Program" ("ProgramID", "Duration", "MinCourses", "MinCredits", "Obligatory", "CommitteeNum", "DiplomaType", "NumOfParticipants", "Year", sys_data)
        VALUES (max_program_id + i, 1, 1, 1, TRUE, 1, NULL, 1, '2023', now());
        
        i := i + 1;
    END LOOP;
    
    RAISE NOTICE 'Added % entries to Program table.', num_entries;
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Error occurred while adding entries: %', SQLERRM;
END;
$$
LANGUAGE plpgsql;

select add_program_entries(1000000);

SELECT COUNT(*) AS entry_count FROM "Program";



CREATE OR REPLACE FUNCTION add_student_joins_entries(num_entries integer) RETURNS void AS
$$
DECLARE
    i integer := 0;
    max_amka bigint;
    max_am bigint;
    p_am character(10);
    p_amka character varying;
    p_entry_date date;
    p_sys_data timestamp;
    p_program_id integer := 200;
BEGIN
    -- Get the maximum "amka" value and convert it to bigint
    SELECT COALESCE(MAX(CAST(amka AS bigint)), 0) + 1 INTO max_amka FROM "Student";
    
    -- Get the maximum "amka" value and convert it to bigint
    SELECT COALESCE(MAX(CAST(am AS bigint)), 0) + 1 INTO max_am FROM "Student";
    
    WHILE i < num_entries LOOP
        max_amka := max_amka + 1; -- Increment the amka value
        max_am := max_am + 1;
        p_am := max_am::character(10);
        p_amka := max_amka::varchar;
        p_entry_date := current_date; -- Set the current date as the entry_date
        p_sys_data := now(); -- Set the current timestamp
        
        -- Insert a new entry with generated values into the "Student" table
        INSERT INTO "Student" (amka, am, entry_date, sys_data)
        VALUES (p_amka, p_am, p_entry_date, p_sys_data);
        
        -- Insert the student into the "Joins" table with the fixed "ProgramID"
        INSERT INTO "Joins" ("StudentAMKA", "ProgramID", sys_data)
        VALUES (p_amka, p_program_id, 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD');
        
        i := i + 1;
    END LOOP;
    
    RAISE NOTICE 'Added % entries to Student and Joins tables.', num_entries;
EXCEPTION
    WHEN others THEN
        RAISE EXCEPTION 'Error occurred while adding entries: %', SQLERRM;
END;
$$
LANGUAGE plpgsql;

SELECT COUNT(*) FROM "Student";
SELECT COUNT(*) FROM "Joins";

select add_student_joins_entries(500000);



--INDEXES PART
--BY DEFAULT THESE ARE B-Tress.
CREATE INDEX idx_cities_id ON "Cities" (id);
CREATE INDEX idx_cities_population ON "Cities" (population);
CREATE INDEX idx_person_amka ON "Person" (amka);
CREATE INDEX idx_student_amka ON "Student" (amka);
CREATE INDEX idx_student_entry_date ON "Student" (entry_date);
CREATE INDEX idx_joins_studentamka ON "Joins" ("StudentAMKA");
CREATE INDEX idx_program_programid ON "Program" ("ProgramID");
CREATE INDEX idx_program_duration ON "Program" ("Duration");
--

DROP INDEX IF EXISTS idx_cities_id;
DROP INDEX IF EXISTS idx_person_amka;
DROP INDEX IF EXISTS idx_student_amka;
DROP INDEX IF EXISTS idx_student_entry_date;
DROP INDEX IF EXISTS idx_joins_studentamka;
DROP INDEX IF EXISTS idx_program_programid;
DROP INDEX IF EXISTS idx_program_duration;
DROP INDEX IF EXISTS idx_cities_population;
--

---hash indexes
CREATE INDEX idx_person_amadka ON "Person" USING hash (amka);
CREATE INDEX idx_student_amka ON "Student" USING hash (amka);
CREATE INDEX idx_program_duration ON "Program" USING hash ("Duration");
CREATE INDEX idx_program_programid ON "Program" USING hash ("ProgramID");

-- Remove Hash Indexes
DROP INDEX IF EXISTS idx_person_amka;
DROP INDEX IF EXISTS idx_student_amka;
DROP INDEX IF EXISTS idx_program_duration;
DROP INDEX IF EXISTS idx_program_programid;

--Clusters
CLUSTER "Student" USING idx_student_entry_date;
CLUSTER "Program" USING idx_program_duration;

-- Remove clusters
CLUSTER "Student" RESET;
CLUSTER "Program" RESET;




EXPLAIN ANALYZE
--MAIN QUERY USED

SELECT c.name,
  CASE WHEN c.population > 50000 THEN COALESCE(total_students, 0) ELSE 0 END AS total_students
FROM "Cities" c
LEFT JOIN (
    SELECT p.city_id, COUNT(DISTINCT s.amka) AS total_students
    FROM "Person" p
    JOIN "Student" s ON p.amka = s.amka
    JOIN (
        SELECT "StudentAMKA"
        FROM "Joins" js
        JOIN "Program" pgr ON pgr."ProgramID" = js."ProgramID"
        WHERE js."StudentAMKA" IN (
            SELECT amka
            FROM "Student"
            WHERE "entry_date" BETWEEN '2040-09-01' AND '2050-09-30'
        ) AND pgr."Duration" = 5
        GROUP BY "StudentAMKA"
        HAVING COUNT(js."ProgramID") >= 2
    ) j ON s.amka = j."StudentAMKA"
    GROUP BY p.city_id
) counts ON c.id = counts.city_id
ORDER BY total_students DESC;


--rearranged version 
SELECT c.name,
  CASE WHEN c.population > 50000 THEN COALESCE(total_students, 0) ELSE 0 END AS total_students
FROM "Cities" c
LEFT JOIN (
    SELECT p.city_id, COUNT(DISTINCT s.amka) AS total_students
    FROM "Person" p
    JOIN (
        SELECT "StudentAMKA"
        FROM "Joins" js
        JOIN "Program" pgr ON pgr."ProgramID" = js."ProgramID"
        WHERE js."StudentAMKA" IN (
            SELECT amka
            FROM "Student"
            WHERE "entry_date" BETWEEN '2040-09-01' AND '2050-09-30'
        ) AND pgr."Duration" = 5
        GROUP BY "StudentAMKA"
        HAVING COUNT(js."ProgramID") >= 2
    ) j ON p.amka = j."StudentAMKA"
    JOIN "Student" s ON p.amka = s.amka
    GROUP BY p.city_id
) counts ON c.id = counts.city_id
ORDER BY total_students DESC;