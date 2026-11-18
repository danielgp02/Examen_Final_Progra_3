# Examen Final Programación 3 - Clínica Veterinaria

## Descripción
Aplicación Java para la gestión de una clínica veterinaria que permite registrar clientes, mascotas, historiales de consultas y citas médicas. El sistema utiliza una base de datos MySQL con procedimientos almacenados y repositorios JDBC.

---

## Estructura del Proyecto

```
Examen_Final_Progra_3/
├── database/Veterinaria.sql    # Script de base de datos
├── pom.xml                     # Dependencias Maven
├── src/main/java/              # Código fuente Java
├── datos/clientes.txt          # Datos de ejemplo (clientes)
├── datos/mascotas.txt          # Datos de ejemplo (mascotas)
└── README.md                   # Esta documentación
```

---

## Configuración y Ejecución

### 1. Ejecutar el script de base de datos

Para configurar la base de datos, ejecuta el script `database/Veterinaria.sql` en tu gestor MySQL:

```bash
mysql -u root -p < C:/Users/gfall/IdeaProjects/Examen_Final_Progra_3/database/Veterinaria.sql
```

El script crea:
- La base de datos `Veterinaria`
- Las tablas: Clientes, Mascotas, HistorialConsultas, Citas, Usuarios
- Los procedimientos almacenados para CRUD operations
- Tres usuarios con permisos diferenciados:
  - `vet_app`@`localhost`: Usuario de la aplicación (SELECT, INSERT, UPDATE, DELETE)
  - `vet_report`@`localhost`: Usuario de solo lectura
  - `vet_admin`@`localhost`: Administrador completo
- Usuario administrador por defecto: `ADM001` (con password encriptado)

### 2. Configurar variables de conexión

Las credenciales de base de datos están definidas en las clases de repositorio:

- **URL**: `jdbc:mysql://localhost:3306/Veterinaria`
- **Usuario**: `root`
- **Password**: `rootroot`

Estas variables se encuentran en:
- `src/main/java/examen/veterinaria/repository/RepositorioClienteMySQL.java`
- `src/main/java/examen/veterinaria/repository/RepositorioMascotasMySQL.java`

**Nota**: No modifique estas credenciales a menos que haya creado nuevos usuarios en la base de datos. El proyecto sigue el principio de mínimo privilegio.

### 3. Ejecutar la aplicación

Usando Maven:

```bash
mvn clean javafx:run
```

O usando el plugin exec configured en pom.xml:

```bash
mvn exec:java
```

La aplicación se abrirá en una ventana Swing con pestañas para:
- **Clientes**: Registrar, listar y buscar clientes
- **Mascotas**: Registrar, actualizar, eliminar y listar mascotas con dueños

---

## Procedimientos de Seguridad (Testing)

### Prueba 1: Validación de entrada de datos
El sistema rechaza correctamente datos inválidos que contengan puntos y coma o saltos de línea:

```java
// El validador en model.Cliente y model.Mascota lanzan IllegalArgumentException si:
// - El valor es null
// - El valor está vacío o en blanco
// - El valor contiene ";"
// - El valor contiene saltos de línea (\n o \r)

try {
    new Cliente("123;456", "Nombre", "Tel");  # Lanzará excepción
} catch (IllegalArgumentException e) {
    System.out.println("Validación correcta: " + e.getMessage());
}
```

### Prueba 2: Permisos de base de datos
Verificar que los usuarios tienen los permisos correctos y no pueden acceder a recursos que no les corresponden:

```sql
-- Como usuario vet_report (solo lectura):
SELECT * FROM Clientes;  # Funciona: SELECT está concedido

-- Como usuario vet_report (intento de INSERT):
INSERT INTO Mascotas VALUES ('M99', 'Test', 'PERRO', 1, 'ADM001');  # Fallará: solo SELECT

-- Como usuario vet_app (usuario normal):
CALL sp_registrar_mascota('M99', 'Test', 'PERRO', 1, 'ADM001');  # Funciona
CALL sp_eliminar_mascota('M99');  # Funciona
```

### Prueba 3: Prevención de inyección SQL
Los repositorios usan PreparedStatement en lugar de sentencias concatenadas, protegiendo automáticamente contra inyección SQL:

```java
# Correcto - usa ? placeholders:
query = "INSERT INTO Clientes (cedula, nombre, telefono) VALUES (?, ?, ?)"
ps = conn.prepareStatement(query)
ps.setString(1, cedula)
ps.setString(2, nombre)
ps.setString(3, telefono)

# Incorrecto - concatenación vulnerable:
# query = "INSERT INTO Clientes VALUES ('" + cedula + "', '" + nombre + "')"
```

---

## Consideraciones Importantes

### Sobre el archivo .env
**No cargue contraseñas reales ni un archivo .env en Git.** El proyecto utiliza credenciales incorporadas en el código fuente de los repositorios MySQL. Para entornos de producción, se recomienda externalizar estas configuraciones.

### Datos de ejemplo
Los archivos `datos/clientes.txt` y `datos/mascotas.txt` contienen datos de prueba iniciales que se utilizaban con los repositorios de tipo TXT. Los repositorios MySQL ahora usan la base de datos directamente.

### Ejecución mínima
Para que la aplicación funcione:
1. Ejecutar `database/Veterinaria.sql` en MySQL
2. Verificar que MySQL esté corriendo en `localhost:3306`
3. Ejecutar la aplicación con `mvn javafx:run`
3. Iniciar desde la pestaña "Mascotas" (ejecuta `controller.verMascotas()` al cargar)
Examen Final Programación 3

Relaciones en SQL y claves

Se da una relacion de 1:N ya que un dueño puede tener varias mascotas pero una mascota no puede tener varios dueños por eso usamos una FOREING KEY dentro de mascotas haciendo referencia a la cedula
del dueño de la mascota,
