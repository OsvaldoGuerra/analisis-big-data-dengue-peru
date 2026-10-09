USE DengueCapacidadSanitaria_DW;
GO

CREATE OR ALTER PROCEDURE sp_CargaDataWarehouse
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @filas INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Dim_Tiempo (ano, semana)
        SELECT DISTINCT c.ano, c.semana
        FROM DengueCapacidadSanitaria.dbo.Caso_Dengue c
        WHERE NOT EXISTS (SELECT 1 FROM Dim_Tiempo t WHERE t.ano = c.ano AND t.semana = c.semana);
        SET @filas = @@ROWCOUNT;
        INSERT INTO DengueCapacidadSanitaria.dbo.Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'Dim_Tiempo', CONCAT('ETL DW: ', @filas, ' filas nuevas'));

        INSERT INTO Dim_Ubicacion (ubigeo, departamento, provincia, distrito, tiene_ipress)
        SELECT u.ubigeo, u.departamento, u.provincia, u.distrito,
               CASE WHEN EXISTS (SELECT 1 FROM DengueCapacidadSanitaria.dbo.Establecimiento e WHERE e.ubigeo = u.ubigeo)
                    THEN 1 ELSE 0 END
        FROM DengueCapacidadSanitaria.dbo.Ubicacion u
        WHERE NOT EXISTS (SELECT 1 FROM Dim_Ubicacion d WHERE d.ubigeo = u.ubigeo);
        SET @filas = @@ROWCOUNT;
        INSERT INTO DengueCapacidadSanitaria.dbo.Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'Dim_Ubicacion', CONCAT('ETL DW: ', @filas, ' filas nuevas'));

        INSERT INTO Dim_Diagnostico (tipo_diagnostico, codigo_cie10)
        SELECT d.tipo_diagnostico, d.codigo_cie10
        FROM DengueCapacidadSanitaria.dbo.Diagnostico d
        WHERE NOT EXISTS (SELECT 1 FROM Dim_Diagnostico x WHERE x.tipo_diagnostico = d.tipo_diagnostico);
        SET @filas = @@ROWCOUNT;
        INSERT INTO DengueCapacidadSanitaria.dbo.Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'Dim_Diagnostico', CONCAT('ETL DW: ', @filas, ' filas nuevas'));

        INSERT INTO Dim_Establecimiento (codigo_unico, nombre, institucion, categoria, tipo, es_capacidad, id_ubicacion)
        SELECT
            e.codigo_unico, e.nombre, i.nombre, c.nombre, e.tipo,
            CASE WHEN e.tipo = 'ESTABLECIMIENTO DE SALUD CON INTERNAMIENTO'
                      OR c.nombre IN ('I-3','I-4','II-1','II-2','II-E','III-1','III-2','III-E')
                 THEN 1 ELSE 0 END,
            du.id_ubicacion
        FROM DengueCapacidadSanitaria.dbo.Establecimiento e
        JOIN DengueCapacidadSanitaria.dbo.Institucion i ON i.id_institucion = e.id_institucion
        JOIN DengueCapacidadSanitaria.dbo.Categoria   c ON c.id_categoria = e.id_categoria
        JOIN Dim_Ubicacion du ON du.ubigeo = e.ubigeo
        WHERE NOT EXISTS (SELECT 1 FROM Dim_Establecimiento x WHERE x.codigo_unico = e.codigo_unico);
        SET @filas = @@ROWCOUNT;
        INSERT INTO DengueCapacidadSanitaria.dbo.Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'Dim_Establecimiento', CONCAT('ETL DW: ', @filas, ' filas nuevas'));

        INSERT INTO Fact_Infraestructura (id_establecimiento, id_ubicacion, camas, total_establecimientos)
        SELECT de.id_establecimiento, de.id_ubicacion, e.camas, 1
        FROM DengueCapacidadSanitaria.dbo.Establecimiento e
        JOIN Dim_Establecimiento de ON de.codigo_unico = e.codigo_unico
        WHERE NOT EXISTS (SELECT 1 FROM Fact_Infraestructura f WHERE f.id_establecimiento = de.id_establecimiento);
        SET @filas = @@ROWCOUNT;
        INSERT INTO DengueCapacidadSanitaria.dbo.Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'Fact_Infraestructura', CONCAT('ETL DW: ', @filas, ' filas nuevas'));

        INSERT INTO Fact_Casos_Dengue (
            id_tiempo, id_ubicacion, id_diagnostico, edad, sexo, id_caso_origen, total_casos, n_ocurrencias_en_celda
        )
        SELECT
            dt.id_tiempo, du.id_ubicacion, dd.id_diagnostico,
            p.edad, p.sexo, c.id_caso, 1,
            COUNT(*) OVER (PARTITION BY c.ano, c.semana, c.ubigeo, c.localidad)
        FROM DengueCapacidadSanitaria.dbo.Caso_Dengue c
        JOIN DengueCapacidadSanitaria.dbo.Paciente    p  ON p.id_paciente = c.id_paciente
        JOIN Dim_Tiempo      dt ON dt.ano = c.ano AND dt.semana = c.semana
        JOIN Dim_Ubicacion   du ON du.ubigeo = c.ubigeo
        JOIN Dim_Diagnostico dd ON dd.tipo_diagnostico = c.tipo_diagnostico
        WHERE NOT EXISTS (SELECT 1 FROM Fact_Casos_Dengue f WHERE f.id_caso_origen = c.id_caso);
        SET @filas = @@ROWCOUNT;
        INSERT INTO DengueCapacidadSanitaria.dbo.Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'Fact_Casos_Dengue', CONCAT('ETL DW: ', @filas, ' filas nuevas'));

        COMMIT TRANSACTION;
        PRINT 'sp_CargaDataWarehouse: ETL completado correctamente.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        INSERT INTO DengueCapacidadSanitaria.dbo.Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'DataWarehouse',
                LEFT(CONCAT('Error en sp_CargaDataWarehouse: ', ERROR_MESSAGE()), 450));

        THROW;
    END CATCH
END;
GO