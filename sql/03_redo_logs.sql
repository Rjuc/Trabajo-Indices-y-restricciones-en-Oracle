-- trabajo 2 - redo logs
-- conexion: SYSTEM / servicio XE (no XEPDB1), hr no ve las v$

-- modo de la base de datos
SELECT name, log_mode, open_mode FROM v$database;

SELECT instance_name, archiver FROM v$instance;

-- grupos de redo
SELECT group#, thread#, sequence#, bytes/1024/1024 AS mb, members, archived, status
FROM   v$log
ORDER  BY group#;

-- ficheros de cada grupo
SELECT group#, type, member
FROM   v$logfile
ORDER  BY group#;

-- forzar cambio de grupo y volver a mirar cual es el CURRENT
ALTER SYSTEM SWITCH LOGFILE;

SELECT group#, thread#, sequence#, archived, status
FROM   v$log
ORDER  BY group#;
