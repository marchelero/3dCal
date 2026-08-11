# Auditoría de cambios

- No se modificó persistencia ni se agregaron llamadas de red.
- Las rutas legales son internas: `/legal/privacy` y `/legal/terms`.
- El contenido legal usa el provider reactivo de locale y tiene variantes es/en.
- Splash mantiene contraste con fondo fijo y preserva proporción del logo mediante `BoxFit.contain` y límites responsive.
- No se incluyeron secretos ni credenciales.
- Pendiente antes de release: validación legal del texto y corrección del test existente con finder ambiguo.
