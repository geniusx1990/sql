drop table if exists task_log;
drop table if exists task_status;
drop table if exists project_team;
drop table if exists team_role;
drop table if exists team_member;
drop table if exists task;
drop table if exists project;

create table project(
	project_id serial primary key,
	project_name text not null unique);

insert into project(project_name) values
('P1'), ('P2'), ('P3');

create table task(
	task_id serial primary key,
	task_name text not null,
	project_id int not null,
	foreign key (project_id) references project(project_id));

insert into task(task_name, project_id) values
('T1P1', 1), ('T2P1', 1), ('T3P1', 1), 
('T1P2', 2), ('T2P2', 2), 
('T1P3', 3), ('T2P3', 3), ('T3P3', 3), ('T4P3', 3);

create table team_member(
	member_id serial primary key,
	name text not null);

insert into team_member(name) values
('TM1'), ('TM2'), ('TM3'), ('TM4'), ('TM5');

create table team_role(
	role_id serial primary key,
	role_name text not null unique);

insert into team_role(role_name) values
('Dev'), ('Test'), ('Manager');

create table project_team(
	project_id int,
	member_id int,
	role_id int,
	constraint pk_project_team primary key (project_id, member_id, role_id),
	foreign key (project_id) references project(project_id),
	foreign key (member_id) references team_member(member_id),
	foreign key (role_id) references team_role(role_id));

insert into project_team(project_id, member_id, role_id) values 
(1, 1, 1), (1, 2, 1), (1, 3, 3), (1, 4, 2),
(2, 2, 1), (2, 5, 2), (2, 1, 3),
(3, 3, 3), (3, 2, 1), (3, 1, 2);

create table task_status(
	status_id serial primary key,
	status_name text not null unique);
	
insert into task_status(status_name) values
('ToDo'), ('InProgress'), ('InTest'), ('Done');

create table task_log(
	task_log_id serial primary key,
	task_id int not null,
	member_id int not null,
	status_id int not null,
	assign_date date,
	foreign key (task_id) references task(task_id),
	foreign key (member_id) references team_member(member_id),
	foreign key (status_id) references task_status(status_id)
);

insert into task_log(task_id, member_id, status_id, assign_date) values
(1, 2, 2, '2024-01-02'),
(2, 2, 1, '2024-01-04'),
(3, 3, 4, '2023-12-23'),
(4, 5, 3, '2024-12-23'),
(5, 1, 2, '2024-01-08'),
(6, 3, 4, '2024-01-02'),
(7, 2, 2, '2024-02-02'),
(8, 1, 2, '2024-01-12'),
(9, 3, 2, '2024-01-25');



--1 

CREATE TABLE task_status_history (
    status_history_id SERIAL PRIMARY KEY,
    task_id INT NOT NULL,
    status_id INT NOT NULL,
    status_date DATE NOT NULL,
    FOREIGN KEY (task_id) REFERENCES task(task_id),
    FOREIGN KEY (status_id) REFERENCES task_status(status_id)
);

-- Создаем новую таблицу для истории назначений задач
CREATE TABLE task_assignment_history (
    assignment_history_id SERIAL PRIMARY KEY,
    task_id INT NOT NULL,
    member_id INT NOT NULL,
    assignment_date DATE NOT NULL,
    FOREIGN KEY (task_id) REFERENCES task(task_id),
    FOREIGN KEY (member_id) REFERENCES team_member(member_id)
);

-- Миграция данных из старой таблицы task_log в новые таблицы
INSERT INTO task_status_history (task_id, status_id, status_date)
SELECT task_id, status_id, assign_date
FROM task_log;

INSERT INTO task_assignment_history (task_id, member_id, assignment_date)
SELECT task_id, member_id, assign_date
FROM task_log;


/* 2. Create a View that facilitates the retrieval of all tasks associated with 
a particular project. The View should include information on the current status 
of each task, as well as the name of the individual to whom the task is assigned. */
-- Создаем представление для получения всех задач, связанных с конкретным проектом,
-- с информацией о текущем статусе задачи и имени назначенного ответственного лица
CREATE VIEW project_tasks_view AS
SELECT
    p.project_name,
    t.task_name,
    ts.status_name AS current_status,
    tm.name AS assigned_member
FROM
    project p
    JOIN task t ON p.project_id = t.project_id
    LEFT JOIN (
        SELECT
            th.task_id,
            th.status_id,
            th.status_date,
            ROW_NUMBER() OVER (PARTITION BY th.task_id ORDER BY th.status_date DESC) as rn
        FROM
            task_status_history th
    ) latest_status ON t.task_id = latest_status.task_id AND latest_status.rn = 1
    LEFT JOIN task_status ts ON latest_status.status_id = ts.status_id
    LEFT JOIN (
        SELECT
            ah.task_id,
            ah.member_id,
            ah.assignment_date,
            ROW_NUMBER() OVER (PARTITION BY ah.task_id ORDER BY ah.assignment_date DESC) as rn
        FROM
            task_assignment_history ah
    ) latest_assignment ON t.task_id = latest_assignment.task_id AND latest_assignment.rn = 1
    LEFT JOIN team_member tm ON latest_assignment.member_id = tm.member_id;

-- Запрос на получение всех задач для конкретного проекта, например, проекта "P1"
SELECT * FROM project_tasks_view WHERE project_name = 'P1';


-- 3. Write a query that returns the name of projects along with the corresponding team roster, including the role of each team member.
SELECT 
    p.project_name,
    tm.name AS team_member,
    tr.role_name AS role
FROM
    project p
JOIN project_team pt ON p.project_id = pt.project_id
JOIN team_member tm ON pt.member_id = tm.member_id
JOIN team_role tr ON pt.role_id = tr.role_id
ORDER BY 
    p.project_name, tm.name;

/* 4. Develop a stored procedure to assign a task to a specific team member. 
The procedure should take as input parameters the task's ID and the team member's ID. 
It must validate that the particular team member is indeed part of the project 
team associated with the task. If the validation fails, the procedure should raise 
an exception. */

CREATE OR REPLACE PROCEDURE AssignTaskToMember(
    p_task_id INT,
    p_member_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_project_id INT;
    v_member_exists BOOLEAN;
BEGIN
    -- Check if the team member is part of the project team for the given task
    SELECT 
        EXISTS (
            SELECT 1
            FROM project_team pt
            WHERE pt.project_id = t.project_id
              AND pt.member_id = p_member_id
        )
    INTO 
        v_member_exists
    FROM task t
    WHERE t.task_id = p_task_id;

    -- If the team member is not part of the project team, raise an exception
    IF NOT v_member_exists THEN
        RAISE EXCEPTION 'The team member is not part of the project team.';
    ELSE
        -- If the team member is part of the project team, assign the task
        INSERT INTO task_assignment_history (task_id, member_id, assignment_date)
        VALUES (p_task_id, p_member_id, CURRENT_DATE);
    END IF;
END;
$$;


/* 5. Write a query that retrieves the history of a task. 
This should include the statuses the task has transitioned through, 
when these statuses were updated, along with who the task was assigned to 
and when that assignment took place. */
SELECT
    tl.task_id,
    t.task_name,
    ts.status_name,
    tl.assign_date AS status_updated_date,
    tm.name AS assigned_to,
    tl.assign_date AS assignment_date
FROM
    task_log tl
JOIN task t ON tl.task_id = t.task_id
JOIN task_status ts ON tl.status_id = ts.status_id
JOIN team_member tm ON tl.member_id = tm.member_id
ORDER BY
    tl.task_id, tl.assign_date;

/* 6. Write commands to add a new task for a project "P3" with "ToDo" status 
and assign the task to a manager.
 */

 -- Step 1: Retrieve the project_id for project "P3"
SELECT project_id
FROM project
WHERE project_name = 'P3';

-- Step 2: Retrieve the status_id for "ToDo" status
SELECT status_id
FROM task_status
WHERE status_name = 'ToDo';

-- Step 3: Retrieve the member_id for the manager
-- Assuming the manager role_id is 3 (adjust if necessary based on your schema)
SELECT tm.member_id
FROM project_team pt
JOIN team_member tm ON pt.member_id = tm.member_id
WHERE pt.project_id = (SELECT project_id FROM project WHERE project_name = 'P3')
  AND pt.role_id = 3;

-- Step 4: Insert the new task into the task table
INSERT INTO task (task_name, project_id)
VALUES ('XXX', 
        (SELECT project_id FROM project WHERE project_name = 'P3'));

-- Step 5: Assign the task to the manager in task_log table with status "ToDo"
INSERT INTO task_log (task_id, member_id, status_id, assign_date)
VALUES (
    (SELECT currval('task_task_id_seq')),  -- Retrieves the last inserted task_id
    (SELECT pt.member_id  -- Explicitly specify the table alias
     FROM project_team pt
     JOIN team_member tm ON pt.member_id = tm.member_id
     WHERE pt.project_id = (SELECT project_id FROM project WHERE project_name = 'P3')
       AND pt.role_id = 3),  -- Assuming role_id 3 is for Manager (adjust as per your schema)
    (SELECT status_id FROM task_status WHERE status_name = 'ToDo'),
    CURRENT_DATE
);

--check 
SELECT tl.task_id, ts.status_name, tm.name AS assigned_to, tl.assign_date
FROM task_log tl
JOIN task_status ts ON tl.status_id = ts.status_id
JOIN team_member tm ON tl.member_id = tm.member_id
WHERE tl.task_id = (SELECT task_id FROM task WHERE task_name = 'XXX'); -- Замените на фактическое имя новой задачи



/* 7. A role assignment error has occurred for the project "P2". 
Developers have been assigned as testers, testers as developers. 
Your task is to fix this mistake. 
Write the necessary SQL commands to update the data, changing the roles from "Dev" 
to "Test" and likewise from "Test" to "Dev" for the "P2" project team members. */

UPDATE project_team
SET role_id = CASE 
                WHEN role_id = 1 THEN 2  -- Change Dev (role_id = 1) to Test (role_id = 2)
                WHEN role_id = 2 THEN 1  -- Change Test (role_id = 2) to Dev (role_id = 1)
              END
WHERE project_id = (SELECT project_id FROM project WHERE project_name = 'P2')
  AND role_id IN (1, 2); -- Only update Dev (1) and Test (2) roles

-- Verify the updated roles for project "P2"
SELECT pt.project_id, pr.project_name, tm.name AS member_name, tr.role_name
FROM project_team pt
JOIN project pr ON pt.project_id = pr.project_id
JOIN team_member tm ON pt.member_id = tm.member_id
JOIN team_role tr ON pt.role_id = tr.role_id
WHERE pr.project_name = 'P2'
ORDER BY pt.project_id, tm.name;
