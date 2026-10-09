USE master;
GO

-- 1. Respaldo Completo (FULL)
BACKUP DATABASE DengueCapacidadSanitaria
TO DISK = 'C:\Respaldo BD\DengueCapacidadSanitaria_FULL.bak'
WITH FORMAT, 
     INIT, 
     NAME = 'DengueCapacidadSanitaria-Full Database Backup',
     STATS = 10;
GO

-- 2. Respaldo Diferencial (DIFFERENTIAL)
BACKUP DATABASE DengueCapacidadSanitaria
TO DISK = 'C:\Respaldo BD\DengueCapacidadSanitaria_DIFF.bak'
WITH DIFFERENTIAL, 
     NAME = 'DengueCapacidadSanitaria-Differential Database Backup',
     STATS = 10;
GO