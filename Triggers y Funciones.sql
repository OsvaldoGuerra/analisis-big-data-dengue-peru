USE DengueCapacidadSanitaria;
GO


--1. Trigger 1: Auditoría DML (sobre Establecimiento)
CREATE OR ALTER TRIGGER trg_Establecimiento_Auditoria
ON Establecimiento
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT: solo hay filas en 'inserted'
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Historial_Auditoria (accion_realizada, tabla_afectada, id_registro, detalle)
        SELECT 'INSERT', 'Establecimiento', codigo_unico,
               CONCAT('Nuevo establecimiento: ', nombre)
        FROM inserted;
    END

    -- DELETE: solo hay filas en 'deleted'
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO Historial_Auditoria (accion_realizada, tabla_afectada, id_registro, detalle)
        SELECT 'DELETE', 'Establecimiento', codigo_unico,
               CONCAT('Establecimiento eliminado: ', nombre)
        FROM deleted;
    END

    -- UPDATE: hay filas tanto en 'inserted' como en 'deleted'
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Historial_Auditoria (accion_realizada, tabla_afectada, id_registro, detalle)
        SELECT 'UPDATE', 'Establecimiento', i.codigo_unico,
               CONCAT('Camas: ', ISNULL(CONVERT(VARCHAR,d.camas),'NULL'), ' -> ', ISNULL(CONVERT(VARCHAR,i.camas),'NULL'),
                      ' | Condición: ', ISNULL(d.condicion,'NULL'), ' -> ', ISNULL(i.condicion,'NULL'))
        FROM inserted i
        JOIN deleted d ON i.codigo_unico = d.codigo_unico;
    END
END;
GO


--2. Trigger 2: Integridad (sobre Establecimiento)
CREATE OR ALTER TRIGGER trg_Integridad_Establecimiento
ON Establecimiento
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar si están intentando borrar una IPRESS activa
    IF EXISTS (SELECT 1 FROM deleted WHERE condicion = 'EN FUNCIONAMIENTO')
    BEGIN
        -- Registramos la infracción en el log antes de abortar
        INSERT INTO Historial_Auditoria (accion_realizada, tabla_afectada, id_registro, detalle)
        SELECT 'DELETE', 'Establecimiento', codigo_unico,
               'Bloqueado por Integridad: Intento de eliminar IPRESS en funcionamiento'
        FROM deleted 
        WHERE condicion = 'EN FUNCIONAMIENTO';

        RAISERROR('Violación de integridad: No se puede eliminar un establecimiento que está EN FUNCIONAMIENTO.', 16, 1);
        RETURN;
    END

    -- Si el establecimiento no estaba activo (ej. INOPERATIVO), permitimos el borrado
    DELETE FROM Establecimiento
    WHERE codigo_unico IN (SELECT codigo_unico FROM deleted);
END;
GO


-- 3. Función Escalar para clasificar pacientes por grupo etario
CREATE OR ALTER FUNCTION fn_GrupoEtario_MINSA
(@edad DECIMAL(6,3)) RETURNS VARCHAR(25)
AS
BEGIN
    DECLARE @grupo VARCHAR(25);

    IF @edad IS NULL 
        SET @grupo = 'Desconocido';
    ELSE IF @edad < 12 
        SET @grupo = 'Niños (0-11)';
    ELSE IF @edad < 18 
        SET @grupo = 'Adolescentes (12-17)';
    ELSE IF @edad < 60 
        SET @grupo = 'Adultos (18-59)';
    ELSE 
        SET @grupo = 'Adultos Mayores (60+)';

    RETURN @grupo;
END;
GO