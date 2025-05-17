# Fase de implementación

## Proceso de Autenticación
### Inicialización de Supabase
- Antes de cualquier operación de autenticación, se configura el cliente de Supabase en `main.dart`: 
   
    ``` dart
    void main() async {
        WidgetsFlutterBinding.ensureInitialized();
        await dotenv.load(fileName: ".env"); 
        await Supabase.initialize(
            url: SupabaseCredentials.url,      // SupabaseDB URL
            anonKey: SupabaseCredentials.anonKey, // Public Key
        );
        runApp(MyApp(locale: locale));
    }
    ```
- `SupabaseCredentials` obtiene la URL y la clave desde `.env`.

- `Supabase.initialize()` establece la conexión con el backend.

### Login
- El método `_login()` gestiona el proceso completo de inicio de sesión en la aplicación, validando que los campos del formulario estén correctamente rellenado; en su defecto, se cancela la operación. 

- Si la validación es exitosa, activa un indicador de carga(*Throbber*) y realiza un intento para autenticar al usuario mediante Supabase usando el email y la contraseña proporcionados. Si la autenticación es exitosa y se recupera un usuario válido, guardando las credenciales localmente si se seleccionó el checkbox `Remember me` y redirige al usuario a la pantalla principal. En caso de error, ya sea por credenciales incorrectas o por problemas inesperados, muestra un mensaje adecuado al usuario. 

- Finalmente, independientemente del resultado, desactiva el indicador de carga para actualizar la interfaz, indicando así al usuario que se ha finalizado el proceso.

``` dart
  /// Handles the login functionality using Supabase.
  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user == null) {
        throw Exception('User not found');
      }
      // Save credentials if "Remember Me" is checked
      await _saveCredentials();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
```
### SharedPreferences
- El método `_saveCredentials()` decide si persiste o elimina las credenciales del usuario según la opción marcada en el checkbox `Remember me`.
  Para ello, utiliza la librería `SharedPreferences` para almacenar los credenciales de forma persistente en el dispositivo en formato **clave-valor**.

- Este proceso conlleva una serie de pasos:
    1. **Instancia de `SharedPreferences`**  
        - `SharedPreferences.getInstance()` abre el almacén clave‑valor persistente del dispositivo.

    2. **Cuando “Recordar sesión” está activado (`_rememberMe == true`)**  
        - Guarda:
            - `'rememberMe' = true` (booleano)
            - `'email' = <correo>` (string)
            - `'password' = <contraseña>` (string)  

        - Estos datos permanecen tras cerrar la app.

    3. **Cuando está desactivado**  
        - Elimina las claves `'rememberMe'`, `'email'` y `'password'` para no conservar información de la sesión.
``` dart
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.remove('rememberMe');
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }
```
