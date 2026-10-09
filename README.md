# Análisis Big Data: Capacidad Sanitaria e Incidencia del Dengue en Perú (2000-2024) 🦟📊

> **Descripción:** Análisis de la capacidad de respuesta sanitaria ante la incidencia histórica de dengue en el Perú (2000–2024), mediante SQL Server, MongoDB, procesos ETL, almacén de datos, Power BI y Apache Spark.

## 📑 Sobre el Proyecto
Este repositorio contiene el código fuente y la documentación oficial del proyecto de investigación. El análisis se centra en procesar más de un millón de registros epidemiológicos integrados con el padrón nacional de establecimientos de salud (IPRESS), con el objetivo de identificar la presión operativa en el primer nivel de atención ante escenarios de brotes exponenciales.

## 🛠️ Arquitectura y Tecnologías
* **Procesamiento Distribuido:** Apache Spark, PySpark (Procesamiento en memoria de +104 MB de datos).
* **Bases de Datos y Almacenamiento:** SQL Server, MongoDB.
* **Integración:** Procesos ETL y construcción de Data Warehouse.
* **Visualización de Datos:** Power BI.

## 📁 Archivos del Proyecto
En este repositorio podrás auditar los siguientes componentes de la investigación:

* 💻 **Scripts de PySpark y SQL:** Código fuente para la limpieza, transformación y análisis descriptivo de los datos.
* 📄 **[Leer el Informe Final de la Investigación (PDF)](./[Informe_Final_Analisis_Dengue.pdf])** <- *(Haz clic aquí para leer la tesis completa, gráficos y conclusiones)*.

## 🗄️ Fuentes de Datos (Open Data)
Bajo los estándares de arquitectura Big Data y las políticas de almacenamiento de GitHub, los archivos planos transaccionales no se encuentran versionados en este repositorio debido a su gran volumen (>100 MB). 

La investigación se sustenta en las siguientes bases de datos públicas oficiales obtenidas de la **Plataforma Nacional de Datos Abiertos del Gobierno del Perú**:

1. **[Vigilancia Epidemiológica de dengue](https://www.datosabiertos.gob.pe/dataset/vigilancia-epidemiológica-de-dengue)**
   * **Archivo procesado:** `datos_abiertos_vigilancia_dengue_2000_2024.csv`
   * **Fuente original:** Centro Nacional de Epidemiología, Prevención y Control de Enfermedades (CDC Perú).
2. **[MINSA - IPRESS](https://www.datosabiertos.gob.pe/dataset/minsa-ipress)**
   * **Archivo procesado:** `IPRESS.csv`
   * **Fuente original:** Ministerio de Salud (MINSA).
