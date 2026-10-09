-- SCRIPT 02: PROCEDIMIENTOS ALMACENADOS (Transacciones Seguras)
-- Objetivo: Automatizar la inserción de datos con manejo de errores (TRY/CATCH).

USE DengueCapacidadSanitaria;
GO

-- 1. Procedimiento para la carga e ingesta masiva de establecimientos de salud (IPRESS) desde staging
CREATE OR ALTER PROCEDURE sp_CargaEstablecimientos
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Catálogos: solo se insertan valores nuevos que aún no existan
        INSERT INTO Institucion (nombre)
        SELECT DISTINCT LTRIM(RTRIM(institucion))
        FROM Staging_Establecimientos s
        WHERE institucion IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM Institucion i WHERE i.nombre = LTRIM(RTRIM(s.institucion)));

        INSERT INTO Categoria (nombre)
        SELECT DISTINCT LTRIM(RTRIM(categoria))
        FROM Staging_Establecimientos s
        WHERE categoria IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM Categoria c WHERE c.nombre = LTRIM(RTRIM(s.categoria)));

        -- 'clasificacion' puede traer varios valores separados por coma (ej. "MEDICINA FISICA,REHABILITACION")
        INSERT INTO Clasificacion (nombre)
        SELECT DISTINCT LTRIM(RTRIM(v.value))
        FROM Staging_Establecimientos s
        CROSS APPLY STRING_SPLIT(s.clasificacion, ',') v
        WHERE v.value IS NOT NULL AND LTRIM(RTRIM(v.value)) <> ''
          AND NOT EXISTS (SELECT 1 FROM Clasificacion c WHERE c.nombre = LTRIM(RTRIM(v.value)));

        -- Ubicación: se agregan los ubigeos de IPRESS que aún no existan
        INSERT INTO Ubicacion (ubigeo, departamento, provincia, distrito)
        SELECT DISTINCT s.ubigeo, s.departamento, s.provincia, s.distrito
        FROM Staging_Establecimientos s
        WHERE s.ubigeo IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM Ubicacion u WHERE u.ubigeo = s.ubigeo);

        SAVE TRANSACTION DespuesDeCatalogos;

        -- Establecimiento: se hace el cast/validación fila por fila con funciones seguras
        INSERT INTO Establecimiento (
            codigo_unico, nombre, direccion, telefono, horario,
            fecha_inicio_actividad, director_medico, camas,
            longitud, latitud, cota, condicion,
            id_institucion, id_categoria, ubigeo
        )
        SELECT
            s.codigo_unico,
            s.nombre_del_establecimiento,
            s.direccion, s.telefono, s.horario,
            TRY_CONVERT(DATE, s.inicio_de_actividad, 103),   -- 103 = formato dd/mm/aaaa
            s.director_medico_y_o_responsable_de_la_atencion_de_salud,
            TRY_CAST(s.camas AS INT),
            TRY_CAST(s.longitud AS DECIMAL(9,6)),
            TRY_CAST(s.latitud  AS DECIMAL(9,6)),
            TRY_CAST(s.cota     AS DECIMAL(10,3)),
            s.condicion,
            i.id_institucion,
            c.id_categoria,
            s.ubigeo
        FROM Staging_Establecimientos s
        JOIN Institucion i ON i.nombre = LTRIM(RTRIM(s.institucion))
        JOIN Categoria   c ON c.nombre = LTRIM(RTRIM(s.categoria))
        WHERE NOT EXISTS (SELECT 1 FROM Establecimiento e WHERE e.codigo_unico = s.codigo_unico);

        -- Establecimiento_Clasificacion: se despliega la lista separada por comas
        INSERT INTO Establecimiento_Clasificacion (codigo_unico, id_clasificacion)
        SELECT DISTINCT s.codigo_unico, cl.id_clasificacion
        FROM Staging_Establecimientos s
        CROSS APPLY STRING_SPLIT(s.clasificacion, ',') v
        JOIN Clasificacion cl ON cl.nombre = LTRIM(RTRIM(v.value))
        WHERE NOT EXISTS (
            SELECT 1 FROM Establecimiento_Clasificacion ec
            WHERE ec.codigo_unico = s.codigo_unico AND ec.id_clasificacion = cl.id_clasificacion
        );

        COMMIT TRANSACTION;
        PRINT 'sp_CargaEstablecimientos: carga completada correctamente.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        INSERT INTO Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'Establecimiento', 
		        LEFT(CONCAT('Error en sp_CargaEstablecimientos: ', ERROR_MESSAGE()), 450));

        THROW;
    END CATCH
END;
GO



-- 2. Procedimiento para la carga e ingesta masiva de casos de Dengue desde staging
CREATE OR ALTER PROCEDURE sp_CargaCasosDengue
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Ubicación: se agregan los ubigeos que solo existen en Dengue (los 16 distritos sin ningún IPRESS registrado)
        INSERT INTO Ubicacion (ubigeo, departamento, provincia, distrito)
        SELECT DISTINCT s.ubigeo, s.departamento, s.provincia, s.distrito
        FROM Staging_Dengue s
        WHERE s.ubigeo IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM Ubicacion u WHERE u.ubigeo = s.ubigeo);

        -- Diagnóstico: por si hubiera una combinación enfermedad/CIE-10 nueva
        INSERT INTO Diagnostico (tipo_diagnostico, codigo_cie10)
        SELECT DISTINCT s.enfermedad, s.diagnostic
        FROM Staging_Dengue s
        WHERE s.enfermedad IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM Diagnostico d WHERE d.tipo_diagnostico = s.enfermedad);

        SAVE TRANSACTION DespuesDeCatalogosDengue;

        -- Paciente: una fila nueva por cada caso (sin buscar coincidencias), usando MERGE + OUTPUT para 
        -- capturar el id_paciente generado y poder enlazarlo con su fila de origen en el siguiente paso.
        IF OBJECT_ID('tempdb..#MapaPaciente') IS NOT NULL DROP TABLE #MapaPaciente;
        CREATE TABLE #MapaPaciente (staging_id INT, id_paciente INT);

        MERGE Paciente AS destino
        USING (
            SELECT staging_id,
                   TRY_CAST(edad AS DECIMAL(6,3)) AS edad,
                   ISNULL(tipo_edad, 'A')          AS tipo_edad,
                   sexo
            FROM Staging_Dengue
        ) AS origen
        ON 1 = 0                              --nunca hay coincidencia: siempre inserta
        WHEN NOT MATCHED THEN
            INSERT (edad, tipo_edad, sexo)
            VALUES (origen.edad, origen.tipo_edad, origen.sexo)
        OUTPUT origen.staging_id, inserted.id_paciente
        INTO #MapaPaciente (staging_id, id_paciente);

        -- Caso_Dengue: se arma usando el mapa recién generado
        INSERT INTO Caso_Dengue (
            ano, semana, localidad, localcod, diresa,
            id_paciente, tipo_diagnostico, ubigeo
        )
        SELECT
            TRY_CAST(s.ano AS INT),
            TRY_CAST(s.semana AS INT),
            s.localidad, s.localcod, s.diresa,
            m.id_paciente,
            s.enfermedad,
            s.ubigeo
        FROM Staging_Dengue s
        JOIN #MapaPaciente m ON m.staging_id = s.staging_id;

        COMMIT TRANSACTION;
        PRINT 'sp_CargaCasosDengue: carga completada correctamente.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        INSERT INTO Historial_Auditoria (accion_realizada, tabla_afectada, detalle)
        VALUES ('INSERT', 'Caso_Dengue',
                LEFT(CONCAT('Error en sp_CargaCasosDengue: ', ERROR_MESSAGE()), 450));

        THROW;
    END CATCH
END;
GO