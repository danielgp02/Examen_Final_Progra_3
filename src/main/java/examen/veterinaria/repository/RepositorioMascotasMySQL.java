package examen.veterinaria.repository;

import examen.veterinaria.model.Especie;
import examen.veterinaria.model.Mascota;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class RepositorioMascotasMySQL implements RepositorioMascota {

    private final String url = "jdbc:mysql://localhost:3306/Veterinaria"
            + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private final String user = "root";
    private final String password = "rootroot";

    @Override
    public List<Mascota> cargarTodos() {
        List<Mascota> lista = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            String query = "SELECT codigo, nombre, especie, edad, cedula_cliente FROM Mascotas";
            try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(query)) {
                while (rs.next()) {
                    String especieStr = rs.getString("especie");
                    Especie especie = Especie.valueOf(especieStr);
                    Mascota m = new Mascota(rs.getString("codigo"), rs.getString("nombre"), especie, rs.getInt("edad"), rs.getString("cedula_cliente"));
                    lista.add(m);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al cargar mascotas: " + e.getMessage(), e);
        }
        return lista;
    }

    @Override
    public void insertar(Mascota mascota) {
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            String query = "INSERT INTO Mascotas (codigo, nombre, especie, edad, cedula_cliente) VALUES (?, ?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(query)) {
                ps.setString(1, mascota.getCodigo());
                ps.setString(2, mascota.getNombre());
                ps.setString(3, mascota.getEspecie().name());
                ps.setInt(4, mascota.getEdad());
                ps.setString(5, mascota.getCedulaCliente());
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al insertar mascota: " + e.getMessage(), e);
        }
    }

    @Override
    public void actualizar(Mascota mascota) {
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            String query = "UPDATE Mascotas SET nombre = ?, especie = ?, edad = ?, cedula_cliente = ? WHERE codigo = ?";
            try (PreparedStatement ps = conn.prepareStatement(query)) {
                ps.setString(1, mascota.getNombre());
                ps.setString(2, mascota.getEspecie().name());
                ps.setInt(3, mascota.getEdad());
                ps.setString(4, mascota.getCedulaCliente());
                ps.setString(5, mascota.getCodigo());
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al actualizar mascota: " + e.getMessage(), e);
        }
    }

    @Override
    public void eliminar(String codigo) {
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            String query = "DELETE FROM Mascotas WHERE codigo = ?";
            try (PreparedStatement ps = conn.prepareStatement(query)) {
                ps.setString(1, codigo);
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al eliminar mascota: " + e.getMessage(), e);
        }
    }

    @Override
    public List<String> listarConDueno() {
        List<String> filas = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            String query = "SELECT m.codigo, m.nombre, m.especie, m.edad, m.cedula_cliente, c.nombre AS nombre_dueno FROM Mascotas m JOIN Clientes c ON m.cedula_cliente = c.cedula";
            try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(query)) {
                while (rs.next()) {
                    String dueno = rs.getString("nombre_dueno");
                    String fila = rs.getString("codigo") + ";" + rs.getString("nombre") + ";" + rs.getString("especie") + ";" + rs.getInt("edad") + ";" + rs.getString("cedula_cliente") + " | Cliente: " + dueno;
                    filas.add(fila);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al listar mascotas con dueño: " + e.getMessage(), e);
        }
        return filas;
    }
}