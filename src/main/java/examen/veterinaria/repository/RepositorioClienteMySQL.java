package examen.veterinaria.repository;

import examen.veterinaria.model.Cliente;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class RepositorioClienteMySQL implements RepositorioCliente {

    private final String url = "jdbc:mysql://localhost:3306/veterinaria"
            + "?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private final String user = "root";
    private final String password = "rootroot";

    @Override
    public List<Cliente> cargarTodos() {
        List<Cliente> lista = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            String query = "SELECT cedula, nombre, telefono FROM Clientes";
            try (Statement stmt = conn.createStatement(); ResultSet rs = stmt.executeQuery(query)) {
                while (rs.next()) {
                    Cliente c = new Cliente(rs.getString("cedula"), rs.getString("nombre"), rs.getString("telefono"));
                    lista.add(c);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al cargar clientes: " + e.getMessage(), e);
        }
        return lista;
    }

    @Override
    public void insertar(Cliente cliente) {
        try (Connection conn = DriverManager.getConnection(url, user, password)) {
            String query = "INSERT INTO Clientes (cedula, nombre, telefono) VALUES (?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(query)) {
                ps.setString(1, cliente.getCedula());
                ps.setString(2, cliente.getNombre());
                ps.setString(3, cliente.getTelefono());
                ps.executeUpdate();
            }
        } catch (SQLException e) {
            throw new RuntimeException("Error al insertar cliente: " + e.getMessage(), e);
        }
    }
}
