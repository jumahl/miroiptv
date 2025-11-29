# MiroIPTV

Reproductor IPTV moderno para Roku con interfaz limpia y navegación rápida.

## 🎯 Características

- **Lista Simple** - Navegación fácil por todos tus canales
- **Múltiples Listas M3U** - Guarda y cambia entre diferentes playlists
- **Cambio Rápido** - Zapea canales con flechas ↑↓ mientras ves TV
- **Menú Flotante** - Presiona ← para ver canales sin pausar el video
- **Vista Previa** - Ve el canal en miniatura mientras navegas por la lista
- **Opciones de Audio** - Cambia la pista de audio/idioma durante la reproducción
- **Subtítulos** - Activa/desactiva subtítulos cuando estén disponibles
- **Pantalla Completa** - Video en 1920x1080 sin bordes negros
- **Multi-formato** - HLS, MP4, MKV, AVI y más de 20 formatos

## 📥 Instalación

https://my.roku.com/account/add?channel=DMQKLXP

## 🎮 Controles

### Menú Principal

| Botón            | Acción                                             |
| ---------------- | -------------------------------------------------- |
| **←→**           | Cambiar entre menú de playlists y lista de canales |
| **↑↓**           | Navegar por playlists o canales                    |
| **OK**           | Reproducir canal seleccionado                      |
| **Options (\*)** | Agregar nueva playlist M3U                         |
| **Replay**       | Opciones de la playlist seleccionada               |

> **Vista Previa:** Al navegar por los canales, verás una vista previa en miniatura a la derecha

### Durante Reproducción

| Botón                | Acción                                            |
| -------------------- | ------------------------------------------------- |
| **OK**               | Abrir menú de opciones (audio, subtítulos, info)  |
| **Play/Pause**       | Pausar o reanudar el video                        |
| **←**                | Mostrar/ocultar menú de canales (el video sigue!) |
| **↑ / Rewind**       | Canal anterior (zapping instantáneo)              |
| **↓ / Fast Forward** | Canal siguiente (zapping instantáneo)             |
| **Back**             | Volver al menú principal                          |

### Menú de Opciones (presiona OK mientras reproduces)

- 🔊 **Cambiar Audio** - Selecciona la pista de audio/idioma
- 💬 **Subtítulos** - Activa o desactiva subtítulos
- ℹ️ **Info del Canal** - Muestra información del canal actual
- ❌ **Cerrar** - Cierra el menú de opciones

> **Tip:** Los canales son cíclicos - el último conecta con el primero

## 📺 Playlists Personalizadas

Usa tu propia lista M3U o la URL de tu proveedor IPTV. Formatos soportados:

- URLs HTTP/HTTPS
- Formato M3U con etiquetas EXTINF
- Logos de canales (tvg-logo)
- Grupos de canales (group-title)

### Listas Predefinidas

La app incluye listas de canales gratuitos para:

- 🇨🇴 Colombia
- 🇨🇱 Chile
- 🇦🇷 Argentina
- 🇲🇽 México
- 🇪🇨 Ecuador
- 🇺🇸 Estados Unidos

### Agregar Lista Personalizada

1. Selecciona "➕ Agregar Lista" en el menú de playlists
2. Ingresa un nombre para tu lista
3. Ingresa la URL de tu lista M3U
4. ¡Listo! Tu lista aparecerá en el menú

**Playlists recomendadas:**

- [M3U.cl](https://m3u.cl/) - Listas por país
- [IPTV-ORG](https://github.com/iptv-org/iptv) - Colección global

## 🔧 Solución de Problemas

**La app se cierra al iniciar:**

- Verifica tu conexión a internet
- Prueba con una playlist más pequeña primero

**La playlist no carga:**

- Verifica que la URL sea accesible desde un navegador
- Asegúrate que el formato sea M3U válido
- Intenta con la playlist demo por defecto

**No aparecen pistas de audio:**

- Espera unos segundos después de que el canal empiece a reproducir
- No todos los canales tienen múltiples pistas de audio
- Presiona OK para ver las opciones disponibles

**El canal muestra error:**

- Algunos canales pueden estar temporalmente no disponibles
- Usa ↑↓ para cambiar a otro canal sin cerrar nada

**Debug:**

```bash
telnet TU_IP_ROKU 8085
```

## 📋 Versión

- **Versión actual:** 1.2.0
- **Última actualización:** Noviembre 2025

## 📄 Documentación Legal

- [Política de Privacidad](PRIVACY_POLICY.md)
- [Términos de Servicio](TERMS_OF_SERVICE.md)

## 📧 Contacto

- Email: Jumahl@proton.me
- GitHub: https://github.com/jumahl/SimpleIPTVRoku
