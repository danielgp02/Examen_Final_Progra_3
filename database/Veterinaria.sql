CREATE DATABASE Veterinaria;
USE Veterinaria;

CREATE TABLE Clientes (
    cedula VARCHAR(20) PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    telefono VARCHAR(15) NOT NULL
);

CREATE TABLE Mascotas (
    codigo VARCHAR(15) PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    especie ENUM('PERRO', 'GATO', 'OTRO') NOT NULL,
    edad INT NOT NULL,
    cedula_cliente VARCHAR(20) NOT NULL,
    FOREIGN KEY (cedula_cliente) REFERENCES Clientes(cedula);

CREATE TABLE HistorialConsultas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mascota_codigo VARCHAR(15) NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    sintomas TEXT,
    diagnostico TEXT,
    tratamiento TEXT,
    FOREIGN KEY (mascota_codigo) REFERENCES Mascotas(codigo);

CREATE TABLE Usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    cedula VARCHAR(20) UNIQUE,
    rol ENUM('ADMINISTRADOR', 'MEDICO_VETERINARIO', 'AUXILIAR') NOT NULL,
    password VARCHAR(255) NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Usuario administrador por defecto (password: vet2024 encriptado)
INSERT INTO Usuarios (nombre, cedula, rol, password) VALUES 
('Administrador', 'ADM001', 'ADMINISTRADOR', '$2a$10$KIQN5JlL2pZhxQzGzJlH3eXyP.HxY5GXyYXeFd1qQvR6bYH7yJuAO');

CREATE TABLE Citas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    mascota_codigo VARCHAR(15) NOT NULL,
    fecha_hora DATETIME NOT NULL,
    motivo VARCHAR(100),
    estado ENUM('AGENDADA', 'COMPLETADA', 'CANCELADA') DEFAULT 'AGENDADA',
    FOREIGN KEY (mascota_codigo) REFERENCES Mascotas(codigo)
);
-- Procedimientos almacenados para Clientes
DELIMITER //
CREATE PROCEDURE sp_listar_clientes()
BEGIN
    SELECT cedula, nombre, telefono FROM Clientes ORDER BY nombre;
END //

CREATE PROCEDURE sp_buscar_cliente(IN p_cedula VARCHAR(20))
BEGIN
    SELECT cedula, nombre, telefono FROM Clientes WHERE cedula = p_cedula;
END //

CREATE PROCEDURE sp_actualizar_cliente(IN p_cedula VARCHAR(20), IN p_nombre VARCHAR(80), IN p_telefono VARCHAR(15))
BEGIN
    UPDATE Clientes SET nombre = p_nombre, telefono = p_telefono WHERE cedula = p_cedula;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
END //

CREATE PROCEDURE sp_eliminar_cliente(IN p_cedula VARCHAR(20))
BEGIN
    DELETE FROM Clientes WHERE cedula = p_cedula;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cliente no encontrado';
    END IF;
END //
DELIMITER ;
-- Procedimientos almacenados para Mascotas
DELIMITER //
CREATE PROCEDURE sp_obtener_mascotas_con_dueno()
BEGIN
    SELECT m.codigo, m.nombre, m.especie, m.edad, c.nombre AS dueño_nombre
    FROM Mascotas m
    JOIN Clientes c ON m.cedula_cliente = c.cedula
    ORDER BY m.nombre;
END //

CREATE PROCEDURE sp_buscar_mascota(IN p_codigo VARCHAR(15))
BEGIN
    SELECT m.codigo, m.nombre, m.especie, m.edad, m.cedula_cliente, c.nombre AS dueño_nombre
    FROM Mascotas m
    JOIN Clientes c ON m.cedula_cliente = c.cedula
    WHERE m.codigo = p_codigo;
END //

CREATE PROCEDURE sp_registrar_mascota(
    IN p_codigo VARCHAR(15), IN p_nombre VARCHAR(80), 
    IN p_especie ENUM('PERRO', 'GATO', 'OTRO'), IN p_edad INT, 
    IN p_cedula_cliente VARCHAR(20)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Clientes WHERE cedula = p_cedula_cliente) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente dueño no existe';
    END IF;
    IF EXISTS (SELECT 1 FROM Mascotas WHERE codigo = p_codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe una mascota con ese código';
    END IF;
    INSERT INTO Mascotas (codigo, nombre, especie, edad, cedula_cliente)
    VALUES (p_codigo, p_nombre, p_especie, p_edad, p_cedula_cliente);
END //

CREATE PROCEDURE sp_actualizar_mascota(
    IN p_codigo VARCHAR(15), IN p_nombre VARCHAR(80), 
    IN p_especie ENUM('PERRO', 'GATO', 'OTRO'), IN p_edad INT, 
    IN p_cedula_cliente VARCHAR(20)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Mascotas WHERE codigo = p_codigo) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mascota no encontrada';
    END IF;
    IF p_cedula_cliente IS NOT NULL AND p_cedula_cliente != '' THEN
        IF NOT EXISTS (SELECT 1 FROM Clientes WHERE cedula = p_cedula_cliente) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El cliente dueño no existe';
        END IF;
    END IF;
    UPDATE Mascotas SET nombre = p_nombre, especie = p_especie, edad = p_edad, cedula_cliente = p_cedula_cliente WHERE codigo = p_codigo;
END //

CREATE PROCEDURE sp_eliminar_mascota(IN p_codigo VARCHAR(15))
BEGIN
    DELETE FROM Mascotas WHERE codigo = p_codigo;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mascota no encontrada';
    END IF;
END //
DELIMITER ;
-- Procedimientos para Historial
DELIMITER //
CREATE PROCEDURE sp_agregar_historial(
    IN p_mascota_codigo VARCHAR(15), IN p_sintomas TEXT, 
    IN p_diagnostico TEXT, IN p_tratamiento TEXT
)
BEGIN
    INSERT INTO HistorialConsultas (mascota_codigo, sintomas, diagnostico, tratamiento)
    VALUES (p_mascota_codigo, p_sintomas, p_diagnostico, p_tratamiento);
END //

CREATE PROCEDURE sp_obtener_historial(IN p_mascota_codigo VARCHAR(15))
BEGIN
    SELECT fecha, sintomas, diagnostico, tratamiento FROM HistorialConsultas
    WHERE mascota_codigo = p_mascota_codigo
    ORDER BY fecha DESC;
END //
DELIMITER ;
-- Procedimientos para Citas
DELIMITER //
CREATE PROCEDURE sp_agendar_cita(
    IN p_mascota_codigo VARCHAR(15), IN p_fecha_hora DATETIME, 
    IN p_motivo VARCHAR(100)
)
BEGIN
    INSERT INTO Citas (mascota_codigo, fecha_hora, motivo, estado)
    VALUES (p_mascota_codigo, p_fecha_hora, p_motivo, 'AGENDADA');
END //

CREATE PROCEDURE sp_cancelar_cita(IN p_id INT)
BEGIN
    UPDATE Citas SET estado = 'CANCELADA' WHERE id = p_id;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cita no encontrada';
    END IF;
END //

CREATE PROCEDURE sp_obtener_citas(IN p_estado ENUM('AGENDADA', 'COMPLETADA', 'CANCELADA'))
BEGIN
    SELECT c.id, m.nombre AS mascota, c.fecha_hora, c.motivo, c.estado
    FROM Citas c
    JOIN Mascotas m ON c.mascota_codigo = m.codigo
    WHERE c.estado = p_estado
    ORDER BY c.fecha_hora;
END //
DELIMITER ;
-- Procedimientos para gestión de usuarios
DELIMITER //
CREATE PROCEDURE sp_registrar_usuario(
    IN p_nombre VARCHAR(80), IN p_cedula VARCHAR(20), 
    IN p_rol ENUM('ADMINISTRADOR', 'MEDICO_VETERINARIO', 'AUXILIAR')
)
BEGIN
    IF EXISTS (SELECT 1 FROM Usuarios WHERE cedula = p_cedula) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ya existe un usuario con esa cédula';
    END IF;
    INSERT INTO Usuarios (nombre, cedula, rol, password) VALUES (p_nombre, p_cedula, p_rol, '$2a$10$KIQN5JlL2pZhxQzGzJlH3eXyP.HxY5GXyYXeFd1qQvR6bYH7yJuAO');
END //

CREATE PROCEDURE sp_autenticar_usuario(IN p_cedula VARCHAR(20), IN p_password VARCHAR(255), OUT p_id INT, OUT p_rol VARCHAR(20), OUT p_activo BOOLEAN)
BEGIN
    SELECT id, rol, activo INTO p_id, p_rol, p_activo FROM Usuarios WHERE cedula = p_cedula;
    IF p_id IS NULL THEN
        SET p_rol = NULL;
    END IF;
END //
DELIMITER ;
-- Permisos de base de datos
CREATE USER IF NOT EXISTS 'vet_app'@'localhost' IDENTIFIED BY 'vet2024';
GRANT SELECT, INSERT, UPDATE, DELETE ON Veterinaria.* TO 'vet_app'@'localhost';
GRANT EXECUTE ON PROCEDURE sp_obtener_clientes TO 'vet_app'@'localhost';
GRANT EXECUTE ON PROCEDURE sp_registrar_mascota TO 'vet_app'@'localhost';
GRANT EXECUTE ON PROCEDURE sp_actualizar_mascota TO 'vet_app'@'localhost';
GRANT EXECUTE ON PROCEDURE sp_eliminar_mascota TO 'vet_app'@'localhost';
GRANT EXECUTE ON PROCEDURE sp_agendar_cita TO 'vet_app'@'localhost';
GRANT EXECUTE ON PROCEDURE sp_autenticar_usuario TO 'vet_app'@'localhost';

CREATE USER IF NOT EXISTS 'vet_report'@'localhost' IDENTIFIED BY 'report2024';
GRANT SELECT ON Veterinaria.* TO 'vet_report'@'localhost';
GRANT EXECUTE ON ALL PROCEDURES IN Veterinaria TO 'vet_report'@'localhost';

CREATE USER IF NOT EXISTS 'vet_admin'@'localhost' IDENTIFIED BY 'admin2024';
GRANT ALL PRIVILEGES ON Veterinaria.* TO 'vet_admin'@'localhost';
GRANT EXECUTE ON ALL PROCEDURES IN Veterinaria TO 'vet_admin'@'localhost';

FLUSH PRIVILEGES;