CREATE DATABASE DengueCapacidadSanitaria;
GO

USE DengueCapacidadSanitaria;
GO


-- 1. CATÁLOGOS SIMPLES (sin dependencias)
CREATE TABLE Institucion (
    id_institucion INT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(60) NOT NULL UNIQUE   -- ej. 'PRIVADO', 'MINSA', 'ESSALUD'
);
GO

CREATE TABLE Categoria (
    id_categoria INT IDENTITY(1,1) PRIMARY KEY,
    nombre       VARCHAR(20) NOT NULL UNIQUE     -- ej. 'I-1', 'II-2', 'Sin Categoría'
);
GO

CREATE TABLE Clasificacion (
    id_clasificacion INT IDENTITY(1,1) PRIMARY KEY,
    nombre           VARCHAR(120) NOT NULL UNIQUE -- ej. 'CENTRO ODONTOLOGICO'
);
GO

CREATE TABLE Diagnostico (
    tipo_diagnostico VARCHAR(50) PRIMARY KEY,      -- ej. 'DENGUE SIN SIGNOS DE ALARMA'
    codigo_cie10     VARCHAR(10) NOT NULL UNIQUE   -- ej. 'A97.0'
);
GO



-- 2. UBICACIÓN (eje central, une ambos datasets)
-- Se llena con la UNIÓN de ubigeos de IPRESS y de Dengue, no solo desde IPRESS (16 ubigeos existen solo en Dengue).

CREATE TABLE Ubicacion (
    ubigeo       CHAR(6) PRIMARY KEY,
    departamento VARCHAR(60) NOT NULL,
    provincia    VARCHAR(60) NOT NULL,
    distrito     VARCHAR(60) NOT NULL
);
GO



-- 3. ESTABLECIMIENTO (entidad central de IPRESS)
CREATE TABLE Establecimiento (
    codigo_unico          CHAR(8) PRIMARY KEY,
    nombre                VARCHAR(150) NOT NULL,
    direccion             VARCHAR(300) NULL,
    telefono              VARCHAR(60)  NULL,
    horario               VARCHAR(100) NULL,
    fecha_inicio_actividad DATE        NULL,       -- 01/01/1900 y no parseables ya en NULL
    director_medico       VARCHAR(150) NULL,        -- dato personal: acceso restringido por rol
    camas                 INT          NULL,        -- 97.0% nulo; NULL ≠ 0
    longitud              DECIMAL(9,6) NULL,
    latitud               DECIMAL(9,6) NULL,
    cota                  DECIMAL(10,3) NULL,
    condicion             VARCHAR(30)  NULL,        -- 'EN FUNCIONAMIENTO', 'INOPERATIVO', etc.

    id_institucion INT     NOT NULL,
    id_categoria   INT     NOT NULL,
    ubigeo         CHAR(6) NOT NULL,

    CONSTRAINT FK_Establecimiento_Institucion FOREIGN KEY (id_institucion) REFERENCES Institucion(id_institucion),
    CONSTRAINT FK_Establecimiento_Categoria   FOREIGN KEY (id_categoria)   REFERENCES Categoria(id_categoria),
    CONSTRAINT FK_Establecimiento_Ubicacion   FOREIGN KEY (ubigeo)         REFERENCES Ubicacion(ubigeo),
    CONSTRAINT CK_Establecimiento_Camas       CHECK (camas IS NULL OR camas >= 0)
);
GO



-- 4. ESTABLECIMIENTO_CLASIFICACION (tabla puente, muchos a muchos)
CREATE TABLE Establecimiento_Clasificacion (
    codigo_unico     CHAR(8) NOT NULL,
    id_clasificacion INT     NOT NULL,

    CONSTRAINT PK_Establecimiento_Clasificacion PRIMARY KEY (codigo_unico, id_clasificacion),
    CONSTRAINT FK_EC_Establecimiento FOREIGN KEY (codigo_unico)     REFERENCES Establecimiento(codigo_unico),
    CONSTRAINT FK_EC_Clasificacion   FOREIGN KEY (id_clasificacion) REFERENCES Clasificacion(id_clasificacion)
);
GO



-- 5. PACIENTE (perfil demográfico anonimizado, 1 fila por caso)
CREATE TABLE Paciente (
    id_paciente INT IDENTITY(1,1) PRIMARY KEY,
    edad        DECIMAL(6,3) NULL,    -- NULL en las 14 filas con edad inválida
    tipo_edad   CHAR(1)      NOT NULL DEFAULT 'A',  -- tras la limpieza, siempre 'A'
    sexo        CHAR(1)      NOT NULL,

    CONSTRAINT CK_Paciente_Sexo      CHECK (sexo IN ('F', 'M')),
    CONSTRAINT CK_Paciente_TipoEdad  CHECK (tipo_edad IN ('A', 'M', 'D')),
    CONSTRAINT CK_Paciente_Edad      CHECK (edad IS NULL OR edad >= 0)
);
GO



-- 6. CASO_DENGUE (entidad central de Dengue)
CREATE TABLE Caso_Dengue (
    id_caso INT IDENTITY(1,1) PRIMARY KEY,
    ano     INT NOT NULL,
    semana  INT NOT NULL,

    -- Se conservan aunque no se usen en el análisis (no se descartan columnas)
    localidad VARCHAR(100) NULL,
    localcod  VARCHAR(20)  NULL,
    diresa    VARCHAR(10)  NULL,

    id_paciente      INT         NOT NULL,
    tipo_diagnostico VARCHAR(50) NOT NULL,
    ubigeo           CHAR(6)     NOT NULL,

    CONSTRAINT FK_Caso_Paciente    FOREIGN KEY (id_paciente)      REFERENCES Paciente(id_paciente),
    CONSTRAINT FK_Caso_Diagnostico FOREIGN KEY (tipo_diagnostico) REFERENCES Diagnostico(tipo_diagnostico),
    CONSTRAINT FK_Caso_Ubicacion   FOREIGN KEY (ubigeo)           REFERENCES Ubicacion(ubigeo),
    CONSTRAINT CK_Caso_Ano         CHECK (ano BETWEEN 2000 AND 2024),
    CONSTRAINT CK_Caso_Semana      CHECK (semana BETWEEN 1 AND 53)
);
GO



-- 7. Tablas puente (staging)
CREATE TABLE Staging_Establecimientos (
    staging_id INT IDENTITY(1,1) PRIMARY KEY,
    institucion NVARCHAR(60), codigo_unico NVARCHAR(20), nombre_del_establecimiento NVARCHAR(200),
    clasificacion NVARCHAR(250), tipo NVARCHAR(80), departamento NVARCHAR(60), provincia NVARCHAR(60),
    distrito NVARCHAR(60), ubigeo NVARCHAR(20), direccion NVARCHAR(250), codigo_disa NVARCHAR(20),
    codigo_red NVARCHAR(20), codigo_microrred NVARCHAR(20), disa NVARCHAR(80), red NVARCHAR(80),
    microrred NVARCHAR(80), codigo_ue NVARCHAR(20), unidad_ejecutora NVARCHAR(150), categoria NVARCHAR(30),
    telefono NVARCHAR(80), tipo_doc_categorizacion NVARCHAR(50), nro_doc_categorizacion NVARCHAR(100),
    horario NVARCHAR(150), inicio_de_actividad NVARCHAR(20), director_medico_y_o_responsable_de_la_atencion_de_salud NVARCHAR(200),
    estado NVARCHAR(30), situacion NVARCHAR(30), condicion NVARCHAR(50), inspeccion NVARCHAR(30),
    longitud NVARCHAR(30), latitud NVARCHAR(30), cota NVARCHAR(30), camas NVARCHAR(20)
);
GO

CREATE TABLE Staging_Dengue (
    staging_id INT IDENTITY(1,1) PRIMARY KEY,
    departamento NVARCHAR(60), provincia NVARCHAR(60), distrito NVARCHAR(60), localidad NVARCHAR(150),
    enfermedad NVARCHAR(60), ano NVARCHAR(10), semana NVARCHAR(10), diagnostic NVARCHAR(20),
    diresa NVARCHAR(20), ubigeo NVARCHAR(20), localcod NVARCHAR(30), edad NVARCHAR(20),
    tipo_edad NVARCHAR(5), sexo NVARCHAR(5)
);
GO



-- 8. Tabla de Trazabilidad y Seguridad Normativa (Auditoría)
CREATE TABLE Historial_Auditoria (
    id_log            INT IDENTITY(1,1) PRIMARY KEY,
    fecha_hora        DATETIME     NOT NULL DEFAULT GETDATE(),
    usuario_db        VARCHAR(50)  NOT NULL DEFAULT SYSTEM_USER,  -- captura el usuario real de SQL Server
    accion_realizada  VARCHAR(20)  NOT NULL,                       -- 'INSERT', 'UPDATE', 'DELETE'
    tabla_afectada    VARCHAR(50)  NOT NULL,
    id_registro       VARCHAR(50)  NULL,                           -- PK de la fila afectada (ej. codigo_unico o id_caso)
    detalle           VARCHAR(500) NULL,

    CONSTRAINT CK_Auditoria_Accion CHECK (accion_realizada IN ('INSERT', 'UPDATE', 'DELETE'))
);
GO