USE DengueCapacidadSanitaria;
GO

-- 1. Medir el "Antes" (Sin índice)
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Consulta crítica de ejemplo adaptada al esquema normalizado
SELECT 
    u.departamento, 
    u.provincia, 
    u.distrito, 
    c.ano, 
    c.semana, 
    COUNT(*) AS Total_Casos
FROM Caso_Dengue c
INNER JOIN Ubicacion u ON c.ubigeo = u.ubigeo
WHERE u.departamento = 'LIMA' AND c.ano = 2023
GROUP BY 
    u.departamento, 
    u.provincia, 
    u.distrito, 
    c.ano, 
    c.semana;
GO

-- 2. Crear el Índice
-- Se indexa el año (filtro principal) y el ubigeo (llave de cruce), 
-- incluyendo la semana (para cubrir la consulta sin ir a la tabla base)
CREATE NONCLUSTERED INDEX IX_CasoDengue_Ano_Ubigeo_Opt
ON Caso_Dengue (ano, ubigeo)
INCLUDE (semana);
GO

-- 3. Medir el "Después" (Con el índice)
SELECT 
    u.departamento, 
    u.provincia, 
    u.distrito, 
    c.ano, 
    c.semana, 
    COUNT(*) AS Total_Casos
FROM Caso_Dengue c
INNER JOIN Ubicacion u ON c.ubigeo = u.ubigeo
WHERE u.departamento = 'LIMA' AND c.ano = 2023
GROUP BY 
    u.departamento, 
    u.provincia, 
    u.distrito, 
    c.ano, 
    c.semana;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO