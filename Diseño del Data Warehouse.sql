CREATE DATABASE DengueCapacidadSanitaria_DW;
GO

USE DengueCapacidadSanitaria_DW;
GO

-- DIMENSIONES

CREATE TABLE Dim_Tiempo (
    id_tiempo INT IDENTITY(1,1) PRIMARY KEY,
    ano       SMALLINT NOT NULL,
    semana    TINYINT  NOT NULL,
    CONSTRAINT UQ_Dim_Tiempo UNIQUE (ano, semana)
);
GO

CREATE TABLE Dim_Ubicacion (
    id_ubicacion INT IDENTITY(1,1) PRIMARY KEY,
    ubigeo       CHAR(6)     NOT NULL UNIQUE,
    departamento VARCHAR(60) NOT NULL,
    provincia    VARCHAR(60) NOT NULL,
    distrito     VARCHAR(60) NOT NULL,
    tiene_ipress BIT         NOT NULL DEFAULT 0   -- se calcula en el ETL (pendiente resuelto)
);
GO

CREATE TABLE Dim_Diagnostico (
    id_diagnostico   INT IDENTITY(1,1) PRIMARY KEY,
    tipo_diagnostico VARCHAR(50) NOT NULL UNIQUE,
    codigo_cie10     VARCHAR(10) NOT NULL
);
GO

CREATE TABLE Dim_Establecimiento (
    id_establecimiento INT IDENTITY(1,1) PRIMARY KEY,
    codigo_unico        CHAR(8)      NOT NULL UNIQUE,
    nombre               VARCHAR(150) NOT NULL,
    institucion           VARCHAR(60)  NULL,
    categoria             VARCHAR(20)  NULL,
    tipo                  VARCHAR(80)  NULL,
    es_capacidad          BIT          NOT NULL DEFAULT 0,   -- se calcula en el ETL (pendiente resuelto)
    id_ubicacion          INT          NOT NULL,

    CONSTRAINT FK_DimEstablecimiento_Ubicacion FOREIGN KEY (id_ubicacion) REFERENCES Dim_Ubicacion(id_ubicacion)
);
GO


-- HECHOS

CREATE TABLE Fact_Casos_Dengue (
    id_hecho_caso        BIGINT IDENTITY(1,1) PRIMARY KEY,

    -- Llaves foráneas hacia las dimensiones
    id_tiempo             INT NOT NULL,
    id_ubicacion          INT NOT NULL,
    id_diagnostico        INT NOT NULL,

    -- Atributos degenerados (no ameritan dimensión propia)
    edad                   DECIMAL(6,3) NULL,
    sexo                   CHAR(1)      NULL,

    -- Trazabilidad hacia el sistema fuente (OLTP)
    id_caso_origen         INT NOT NULL,

    -- Medidas
    total_casos            INT NOT NULL DEFAULT 1,     -- aditiva: SUM() cuenta casos
    n_ocurrencias_en_celda INT NOT NULL,                -- pendiente resuelto: tamaño del grupo año-semana-ubigeo-localidad

    CONSTRAINT FK_FactCasos_Tiempo      FOREIGN KEY (id_tiempo)      REFERENCES Dim_Tiempo(id_tiempo),
    CONSTRAINT FK_FactCasos_Ubicacion   FOREIGN KEY (id_ubicacion)   REFERENCES Dim_Ubicacion(id_ubicacion),
    CONSTRAINT FK_FactCasos_Diagnostico FOREIGN KEY (id_diagnostico) REFERENCES Dim_Diagnostico(id_diagnostico)
);
GO

CREATE TABLE Fact_Infraestructura (
    id_hecho_infra       INT IDENTITY(1,1) PRIMARY KEY,

    id_establecimiento    INT NOT NULL,
    id_ubicacion          INT NOT NULL,

    camas                  INT NULL,                    -- NULL = sin dato, no confundir con 0 camas
    total_establecimientos INT NOT NULL DEFAULT 1,       -- aditiva: SUM() cuenta establecimientos

    CONSTRAINT FK_FactInfra_Establecimiento FOREIGN KEY (id_establecimiento) REFERENCES Dim_Establecimiento(id_establecimiento),
    CONSTRAINT FK_FactInfra_Ubicacion       FOREIGN KEY (id_ubicacion)       REFERENCES Dim_Ubicacion(id_ubicacion)
);
GO