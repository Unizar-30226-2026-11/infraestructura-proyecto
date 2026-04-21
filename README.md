# Infraestructura del proyecto

Este repositorio contiene la infraestructura mínima para desplegar la aplicación con Docker Compose. La pila incluye un frontend, un backend, Redis y dos servicios auxiliares para migraciones y sincronización de datos.

## Arquitectura

Los contenedores definidos en este repositorio son:

- `db`: PostgreSQL de Supabase, expuesto en el puerto `5432`.
- `storage`: Storage API de Supabase, expuesto en el puerto `5000`.
- `frontend`: expone la interfaz web en el puerto `80`.
- `backend`: expone la API en el puerto `3000`.
- `redis`: almacena caché y estado temporal, con persistencia en un volumen local.
- `migrate`: ejecuta migraciones Prisma antes de levantar el backend.
- `sync`: servicio manual para tareas de sincronización en producción.

```mermaid
graph TD
    U[Navegador del usuario] --> F[Frontend]
    F --> B[Backend]
    B --> R[Redis]
   B --> S[Storage API]
   B --> D[Postgres]
    M[Migraciones Prisma] --> R
   X[Sync manual] --> R
   S --> D
   B --> D
```

## Requisitos

- Docker con Docker Compose v2.
- Acceso a las imágenes publicadas en GitHub Container Registry.
- Un archivo `.env` válido en la raíz del repositorio, copiado desde `.env.example`.

## Despliegue

1. Copia el archivo de ejemplo y ajusta los valores reales:

   ```bash
   cp .env.example .env
   ```

2. Verifica que el script tenga permisos de ejecución:

   ```bash
   chmod +x deploy.sh
   ```

3. Lanza el despliegue:

   ```bash
   ./deploy.sh deploy
   ```

El script comprueba que existan `.env` y `docker-compose.yaml`, levanta primero `db`, `redis` y `storage`, ejecuta `migrate`, y solo si todo sale bien arranca `backend`.

## Sync manual

Si necesitas ejecutar la tarea de sincronización del backend tools, usa:

```bash
./deploy.sh sync
```

También puedes ejecutar sync durante el deploy:

```bash
./deploy.sh deploy --with-sync
```

## Variables de entorno

El archivo `.env.example` ya deja preparados los valores locales para:

- PostgreSQL de Supabase.
- Storage API en modo file backend.
- Redis interno de Docker.
- Claves JWT/servicio/anon coherentes entre backend y storage.
- La URL del frontend y la API del backend.
- El volumen del servicio `sync` mediante `SYNC_VOLUME_MOUNT`.

Para `sync`, puedes elegir el tipo de volumen con:

- `SYNC_VOLUME_MOUNT="sync_data:/app/sync-data"` para usar volumen nombrado (por defecto).
- `SYNC_VOLUME_MOUNT="./sync-data:/app/sync-data"` para usar bind mount desde el host.

## Notas operativas

- Redis se ejecuta como servicio interno en Docker y usa un volumen llamado `redis_data`.
- PostgreSQL usa los volúmenes `db_data` y `db_config` para persistencia y configuración.
- Storage usa el volumen `storage_data` para el backend de ficheros.
- Las migraciones fallan de forma explícita si el servicio `migrate` devuelve error; en ese caso el backend no se arranca.
- Si despliegas en un servidor remoto, ajusta `CORS_ORIGIN`, `API_URL` y `STORAGE_PUBLIC_URL` a la URL pública real, no a `localhost`.
