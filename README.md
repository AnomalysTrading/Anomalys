# Anomalys — edición visual renovada

Página adaptable a Android y escritorio, preparada para GitHub Pages + Supabase.

## Incluye
- Portada con la imagen de calabaza que compartiste (incluida en `assets/anomaly-hero.jpg`).
- Nombre de marca simplificado a **ANOMALYS**.
- Personalización global del fondo (imagen HTTPS y color) desde el panel privado.
- Logo/imagen del juego personalizable en la esquina superior izquierda y nombre del juego editable.
- Catálogo con tarjetas, buscador, filtros por categoría, orden por valor/nombre/actualización y vista en lista.
- Favoritos guardados en el navegador.
- Ficha de cada objeto e historial de cambios.
- Panel de administración que aparece solo después de iniciar sesión y validar permisos en Supabase.
- Crear, editar y eliminar objetos.
- Gestión de admins solo para el propietario (`owner`).
- Políticas RLS: el público puede consultar objetos e historial, pero no modificarlos.

## 1. Crear o preparar Supabase
1. Abrí tu proyecto en https://supabase.com/dashboard.
2. Entrá a **SQL Editor → New query**.
3. Abrí `supabase-setup.sql`, copiá todo el contenido y ejecutalo. Si ya habías ejecutado una versión anterior, también podés ejecutar solamente el bloque final titulado “Apariencia global de Anomalys”.
4. En **Authentication → Users**, creá tu usuario si todavía no existe.
5. Copiá el UUID de tu cuenta.
6. En SQL Editor ejecutá lo siguiente, cambiando el UUID de ejemplo por el tuyo:

```sql
insert into public.admins (user_id, role)
values ('UUID-DE-TU-USUARIO', 'owner')
on conflict (user_id) do update set role = 'owner';
```

Este paso te convierte en propietario. Solo el propietario puede agregar o quitar administradores desde el menú privado. No compartas tu contraseña.

## 2. Conectar la web
1. Abrí `index.html` en GitHub.
2. Tocá el lápiz para editar.
3. Buscá `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`.
4. Pegá la **Project URL** y la clave pública **publishable** (en proyectos viejos puede figurar como `anon/public`).
5. Nunca uses la clave `service_role` ni una clave `secret` en una web pública.
6. Guardá con **Commit changes**.

La URL y la clave publishable/anon están destinadas al navegador; la protección real depende de las políticas RLS del SQL.

## 3. Publicar con GitHub Pages
1. Subí todos los archivos y la carpeta `assets` al repositorio.
2. En **Settings → Pages**, elegí `Deploy from a branch`, rama `main`, carpeta `/(root)`.
3. Esperá a que termine la publicación y abrí la URL de GitHub Pages de tu repositorio.

## 4. Personalizar fondo y logo del juego
1. Conectate a Supabase y asegurate de haber ejecutado el bloque SQL de `site_appearance`.
2. Iniciá sesión en Anomalys con una cuenta administradora.
3. Abrí **⚙ Mod menu → Personalizar página**.
4. Pegá una URL HTTPS directa para la imagen de fondo y/o para el logo del juego; elegí el color de fondo y escribí el nombre del juego.
5. Usá **Vista previa** para revisar y **Guardar apariencia** para publicar los cambios a todos los visitantes.

Las imágenes se enlazan por URL pública HTTPS; la página no sube archivos directamente a almacenamiento.

## 5. Agregar más administradores
1. En Supabase, creá el usuario en **Authentication → Users → Add user**.
2. Copiá su UUID/UID.
3. Iniciá sesión en la página con tu cuenta propietaria.
4. Tocá **Mod menu → Administrar equipo**, pegá el UUID y agregalo.
5. Los admins podrán administrar objetos, pero no podrán gestionar otros administradores.

## Importante
- Las tarjetas iniciales son **datos de demostración** y no valores reales. Al conectar Supabase, el catálogo se alimenta desde la base de datos.
- Para imágenes de objetos, usá URL públicas HTTPS.
- El menú de administración no se muestra al público. Los permisos se verifican también en la base de datos; ocultar un botón por sí solo no sería seguridad.
- No se puede crear la cuenta propietaria automáticamente desde una web pública: el primer owner se establece una vez desde SQL Editor.
- Los valores son comunitarios, no oficiales, y no hay afiliación con Roblox.
