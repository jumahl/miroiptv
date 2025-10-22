# MiroIPTV

Reproductor IPTV moderno para Roku con interfaz limpia y navegación rápida.

## 🎯 Características

- **Lista Simple** - Navegación fácil por todos tus canales
- **Múltiples Listas M3U** - Guarda y cambia entre diferentes playlists
- **Cambio Rápido** - Zapea canales con flechas ↑↓ mientras ves TV
- **Menú Flotante** - Presiona ← para ver canales sin pausar el video
- **Pantalla Completa** - Video en 1920x1080 sin bordes negros
- **Multi-formato** - HLS, MP4, MKV, AVI y más de 20 formatos

## 📥 Instalación

1. **Activa Developer Mode en tu Roku:**
   - Presiona: Home 3x, Up 2x, Right, Left, Right, Left, Right


3. **Instala en Roku:**
   - Abre `http://TU_IP_ROKU` en tu navegador
   - Sube el archivo `SimpleIPTVRoku.zip`

## 🎮 Controles

### Menú Principal

- **←→** Cambiar entre menú de playlists y lista de canales
- **↑↓** Navegar por playlists o canales
- **OK** Reproducir canal seleccionado
- **Options** Agregar nueva playlist M3U

### Durante Reproducción

- **←** Mostrar/ocultar menú de canales (el video sigue!)
- **↑** Canal anterior (zapping instantáneo)
- **↓** Canal siguiente (zapping instantáneo)
- **Back** Volver al menú principal

> **Tip:** Los canales son cíclicos - el último conecta con el primero

## 📺 Playlists Personalizadas

Usa tu propia lista M3U o la URL de tu proveedor IPTV. Formatos soportados:

- URLs HTTP/HTTPS
- Formato M3U con etiquetas EXTINF
- Logos de canales (tvg-logo)

**Playlists recomendadas:**

- [M3U.cl](https://m3u.cl/) - Listas por país
- [IPTV-ORG](https://github.com/iptv-org/iptv) - Colección global (muy grande)

## 🔧 Solución de Problemas

**La app se cierra al iniciar:**

- Verifica tu conexión a internet
- Prueba con una playlist más pequeña primero

**La playlist no carga:**

- Verifica que la URL sea accesible desde un navegador
- Asegúrate que el formato sea M3U válido
- Intenta con la playlist demo por defecto

**Debug:**

```bash
telnet TU_IP_ROKU 8085
```
