USE DengueCapacidadSanitaria;
GO

-- 1. CREACIÓN DE ROLES
CREATE ROLE Rol_Administrador;
CREATE ROLE Rol_AnalistaDatos;
CREATE ROLE Rol_Auditor;
GO


-- 2. ADMINISTRADOR (Control total sobre la base de datos)
GRANT CONTROL ON DATABASE::DengueCapacidadSanitaria TO Rol_Administrador;
GO


-- 3. ANALISTA DE DATOS (Consulta de información y ejecución de la función)
GRANT SELECT ON OBJECT::dbo.Establecimiento TO Rol_AnalistaDatos;
GRANT SELECT ON OBJECT::dbo.Caso_Dengue TO Rol_AnalistaDatos;
GRANT SELECT ON OBJECT::dbo.Paciente TO Rol_AnalistaDatos;
GRANT SELECT ON OBJECT::dbo.Ubicacion TO Rol_AnalistaDatos;
GRANT SELECT ON OBJECT::dbo.Institucion TO Rol_AnalistaDatos;
GRANT SELECT ON OBJECT::dbo.Categoria TO Rol_AnalistaDatos;
GRANT SELECT ON OBJECT::dbo.Clasificacion TO Rol_AnalistaDatos;
GRANT SELECT ON OBJECT::dbo.Diagnostico TO Rol_AnalistaDatos;
GRANT EXECUTE ON OBJECT::dbo.fn_GrupoEtario_MINSA TO Rol_AnalistaDatos;
--Restricción de acceso a datos personales (Ley N.º 29733)
DENY SELECT ON OBJECT::dbo.Establecimiento (director_medico) TO Rol_AnalistaDatos;
GO


-- 4. AUDITOR (Consulta de datos y trazabilidad Sin permisos de modificación)
GRANT SELECT ON OBJECT::dbo.Historial_Auditoria TO Rol_Auditor;
GRANT SELECT ON OBJECT::dbo.Establecimiento TO Rol_Auditor;
GRANT SELECT ON OBJECT::dbo.Caso_Dengue TO Rol_Auditor;
--Restricción de acceso a datos personales (Ley N.º 29733)
DENY SELECT ON OBJECT::dbo.Establecimiento (director_medico) TO Rol_Auditor;
GO