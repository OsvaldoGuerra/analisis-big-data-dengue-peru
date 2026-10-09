// ==========================================
// SCRIPT CRUD PARA MONGODB (VS Code)
// ==========================================

// 0. Crea/Usa la base de datos
use DengueCapacidadSanitaria

// 1. CREATE (Insertar documentos con estructura anidada)
db.ipress.insertMany([
  {
    "codigo_unico": "00000001",
    "nombre_del_establecimiento": "HOSPITAL NACIONAL DOS DE MAYO",
    "condicion": "EN FUNCIONAMIENTO",
    "camas": 120,
    "ubicacion": {
      "departamento": "LIMA",
      "provincia": "LIMA",
      "distrito": "LIMA"
    },
    "clasificacion": {
      "institucion": "MINSA",
      "categoria": "III-1"
    }
  },
  {
    "codigo_unico": "00000002",
    "nombre_del_establecimiento": "POSTA MEDICA MIRONES",
    "condicion": "EN FUNCIONAMIENTO",
    "camas": 0,
    "ubicacion": {
      "departamento": "LIMA",
      "provincia": "LIMA",
      "distrito": "CERCADO DE LIMA"
    },
    "clasificacion": {
      "institucion": "ESSALUD",
      "categoria": "I-2"
    }
  },
  {
    "codigo_unico": "00000003",
    "nombre_del_establecimiento": "CLINICA SAN JUAN (PRUEBA)",
    "condicion": "INOPERATIVO",
    "camas": 10,
    "ubicacion": {
      "departamento": "CALLAO",
      "provincia": "CALLAO",
      "distrito": "CALLAO"
    },
    "clasificacion": {
      "institucion": "PRIVADO",
      "categoria": "II-1"
    }
  }
])

// 2. READ (Consultas demostrando el acceso a datos anidados con "punto")
// Lee todos los establecimientos
db.ipress.find()

// Busca solo los establecimientos que están en LIMA (usando notación de punto)
db.ipress.find({ "ubicacion.departamento": "LIMA" })

// Busca establecimientos de ESSALUD sin camas (múltiples filtros)
db.ipress.find({ 
  "clasificacion.institucion": "ESSALUD", 
  "camas": 0 
})

// 3. UPDATE (Actualizar un registro)
// Simula que la posta Mirones recibe 5 camas de internamiento temporal
db.ipress.updateOne(
  { "codigo_unico": "00000002" },
  { $set: { "camas": 5 } }
)

// Verificar la actualización
db.ipress.find({ "codigo_unico": "00000002" })

// 4. DELETE (Eliminar un registro)
// Elimina la clínica de prueba que está inoperativa
db.ipress.deleteOne({ "codigo_unico": "00000003" })

// Verifica que se eliminó
db.ipress.find({ "codigo_unico": "00000003" })