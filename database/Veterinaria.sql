CREATE database Veterinaria;
USE Veterinaria;

CREATE TABLE Clientes (
    cedula VARCHAR(20) PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    telefono VARCHAR(15) NOT NULL
);

CREATE TABLE Mascotas (
    codigo VARCHAR(15) PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    especie ENUM("PERRO", "GATO", "OTRO") NOT NULL,
    edad INT NOT NULL,
    cedula_cliente VARCHAR(20) NOT NULL,
    FOREIGN KEY (cedula_cliente) REFERENCES Clientes(cedula)
);