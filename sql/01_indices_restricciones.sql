-- trabajo 2 - indices y restricciones (esquema hr)
-- conexion: hr / XEPDB1

set serveroutput on
set sqlformat ansiconsole

-- 1. indices

SELECT table_name, index_name, index_type, uniqueness
FROM   user_indexes
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER  BY table_name, index_name;

-- columnas de cada indice
SELECT table_name, index_name, column_position, column_name
FROM   user_ind_columns
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER  BY table_name, index_name, column_position;

-- 2. restricciones
-- P primaria, U unica, R foranea, C check (y not null)

SELECT table_name, constraint_name, constraint_type, status, index_name
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER  BY table_name, constraint_type, constraint_name;


ALTER TABLE departments DISABLE CONSTRAINT dept_id_pk;

-- desactivar todas: foraneas primero, primarias al final

BEGIN
  FOR c IN (SELECT table_name, constraint_name, constraint_type
            FROM   user_constraints
            WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
            AND    status = 'ENABLED'
            ORDER  BY DECODE(constraint_type,'R',1,'C',2,'U',3,'P',4)) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE ' || c.table_name ||
                      ' DISABLE CONSTRAINT ' || c.constraint_name ||
                      CASE WHEN c.constraint_type IN ('P','U') THEN ' CASCADE' END;
    DBMS_OUTPUT.PUT_LINE('Desactivada: ' || c.table_name || '.' || c.constraint_name);
  END LOOP;
END;
/

-- ver como quedaron (con job_history)
SELECT table_name, constraint_name, constraint_type, status
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS','JOB_HISTORY')
ORDER  BY table_name, constraint_type, constraint_name;

-- los indices de PK y UK ya no deberian estar
SELECT table_name, index_name, uniqueness
FROM   user_indexes
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER  BY table_name, index_name;

SELECT index_name, uniqueness FROM user_indexes
WHERE index_name IN ('DEPT_ID_PK','EMP_EMP_ID_PK');

SELECT constraint_name, status, deferrable, index_name FROM user_constraints
WHERE constraint_name IN ('DEPT_ID_PK','EMP_EMP_ID_PK');

-- 3. inserts que rompen las reglas

-- id repetido
INSERT INTO employees (employee_id, first_name, last_name, email, hire_date, job_id, salary, department_id)
VALUES (100, 'Prueba', 'PRUEBA_PK', 'PRUEBA_PK', SYSDATE, 'IT_PROG', 5000, 60);

-- departamento que no existe
INSERT INTO employees (employee_id, first_name, last_name, email, hire_date, job_id, salary, department_id)
VALUES (9002, 'Prueba', 'PRUEBA_FK', 'PRUEBA_FK', SYSDATE, 'IT_PROG', 5000, 999);

-- salario negativo
INSERT INTO employees (employee_id, first_name, last_name, email, hire_date, job_id, salary, department_id)
VALUES (9003, 'Prueba', 'PRUEBA_SAL', 'PRUEBA_SAL', SYSDATE, 'IT_PROG', -500, 60);

-- apellido null
INSERT INTO employees (employee_id, first_name, last_name, email, hire_date, job_id, salary, department_id)
VALUES (9004, 'Prueba', NULL, 'PRUEBA_NN', SYSDATE, 'IT_PROG', 5000, 60);

-- email repetido
INSERT INTO employees (employee_id, first_name, last_name, email, hire_date, job_id, salary, department_id)
VALUES (9005, 'Prueba', 'PRUEBA_UK', 'SKING', SYSDATE, 'IT_PROG', 5000, 60);

-- departments
-- id repetido
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (10, 'PRUEBA_PK', NULL, 1700);

-- location que no existe
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (9002, 'PRUEBA_FKLOC', NULL, 9999);

-- manager que no existe
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (9003, 'PRUEBA_FKMGR', 9999, 1700);

-- nombre null
INSERT INTO departments (department_id, department_name, manager_id, location_id)
VALUES (9004, NULL, NULL, 1700);

COMMIT;

-- comprobar que entraron
SELECT employee_id, last_name, email, salary, department_id
FROM   employees
WHERE  employee_id >= 9000 OR last_name = 'PRUEBA_PK'
ORDER  BY employee_id;

SELECT department_id, department_name, manager_id, location_id
FROM   departments
WHERE  department_id >= 9000 OR department_name = 'PRUEBA_PK'
ORDER  BY department_id;

SELECT employee_id, COUNT(*) AS veces
FROM   employees
WHERE  employee_id = 100
GROUP  BY employee_id;

-- 4. volver a activar

-- asi directo falla (ORA-02437), los datos malos siguen ahi
ALTER TABLE departments ENABLE CONSTRAINT dept_loc_fk;

-- otra opcion seria novalidate, pero deja pasar lo que ya esta mal
-- ALTER TABLE departments ENABLE NOVALIDATE CONSTRAINT dept_id_pk;

-- borro las filas de prueba
DELETE FROM employees   WHERE employee_id >= 9000 OR last_name = 'PRUEBA_PK';
DELETE FROM departments WHERE department_id >= 9000 OR department_name = 'PRUEBA_PK';
COMMIT;

-- activar todo otra vez, ahora en orden inverso (foraneas al final)
-- incluye job_history por el cascade de antes
BEGIN
  FOR c IN (SELECT table_name, constraint_name
            FROM   user_constraints
            WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS','JOB_HISTORY')
            AND    status = 'DISABLED'
            ORDER  BY DECODE(constraint_type,'C',1,'P',2,'U',3,'R',4)) LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE ' || c.table_name ||
                      ' ENABLE CONSTRAINT ' || c.constraint_name;
    DBMS_OUTPUT.PUT_LINE('Activada: ' || c.table_name || '.' || c.constraint_name);
  END LOOP;
END;
/

-- no deberia salir nada
SELECT table_name, constraint_name, constraint_type, status
FROM   user_constraints
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS','JOB_HISTORY')
AND    status <> 'ENABLED';

SELECT table_name, index_name, uniqueness
FROM   user_indexes
WHERE  table_name IN ('EMPLOYEES','DEPARTMENTS')
ORDER  BY table_name, index_name;
