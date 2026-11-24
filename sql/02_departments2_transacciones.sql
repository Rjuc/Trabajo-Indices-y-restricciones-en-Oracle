-- trabajo 2 - departments2 y transacciones
-- conexion: hr / XEPDB1
-- no se lanza todo junto, hay que cerrar sesion a mano entre B y D

set serveroutput on

-- si hay que repetir desde cero:
-- DROP TABLE departments2 PURGE;


CREATE TABLE departments2 AS SELECT * FROM departments;

SELECT COUNT(*) AS filas FROM departments2;

-- ver que se copio
SELECT constraint_name, constraint_type FROM user_constraints WHERE table_name = 'DEPARTMENTS2';
SELECT index_name FROM user_indexes WHERE table_name = 'DEPARTMENTS2';

-- B. tres inserts, sin commit
INSERT INTO departments2 VALUES (280, 'Analitica', NULL, 1700);
INSERT INTO departments2 VALUES (290, 'Soporte TI', NULL, 1700);
INSERT INTO departments2 VALUES (300, 'Calidad', NULL, 1700);

SELECT COUNT(*) AS filas FROM departments2;

-- C. cerrar sesion a mano
-- clic derecho en la conexion hr > desconectar
-- primera vez: deshacer. segunda vez (repetir B): confirmar

-- D. reconectar y mirar
SELECT COUNT(*) AS filas FROM departments2;
SELECT * FROM departments2 WHERE department_id >= 280;

-- E. bloque anonimo
-- el commit va antes porque set transaction tiene que ser lo primero
COMMIT;

DECLARE
  v_id VARCHAR2(100);
BEGIN
  SET TRANSACTION NAME 'trans_departments2';
  DBMS_OUTPUT.PUT_LINE('INICIO de la transaccion: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));

  INSERT INTO departments2 VALUES (310, 'Inteligencia de negocio', NULL, 1700);
  UPDATE departments2 SET department_name = 'Analitica de datos' WHERE department_id = 280;

  v_id := DBMS_TRANSACTION.LOCAL_TRANSACTION_ID;
  DBMS_OUTPUT.PUT_LINE('Transaccion activa, id: ' || NVL(v_id, '(ninguna)'));

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('FIN de la transaccion (COMMIT): ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
  DBMS_OUTPUT.PUT_LINE('Id tras el commit: ' || NVL(DBMS_TRANSACTION.LOCAL_TRANSACTION_ID, '(ninguna)'));
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM || ' -> se ha hecho ROLLBACK');
END;
/

SELECT * FROM departments2 WHERE department_id >= 280 ORDER BY department_id;

-- F. deshacer con rollback
SELECT COUNT(*) AS antes FROM departments2;

DELETE FROM departments2 WHERE department_id IN (280, 290);
SELECT COUNT(*) AS tras_delete FROM departments2;

ROLLBACK;
SELECT COUNT(*) AS tras_rollback FROM departments2;

-- G. savepoint
INSERT INTO departments2 VALUES (320, 'Prueba A', NULL, 1700);
SAVEPOINT punto1;
INSERT INTO departments2 VALUES (330, 'Prueba B', NULL, 1700);

SELECT department_id, department_name FROM departments2 WHERE department_id IN (320, 330);

ROLLBACK TO SAVEPOINT punto1;
SELECT department_id, department_name FROM departments2 WHERE department_id IN (320, 330);

ROLLBACK;
SELECT department_id, department_name FROM departments2 WHERE department_id IN (320, 330);
