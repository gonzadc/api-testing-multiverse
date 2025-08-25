# API Testing Multiverse — SWAPI (Star Wars)

Repositorio para experimentar un **multiverso de testing de APIs** alrededor de una especificación **OpenAPI de Star Wars (SWAPI)**. Incluye mock/proxy con Prism, documentación con Swagger UI y perfiles para ejecutar distintas herramientas de testing: **StepCI**, **Dredd**, **k6** y **OWASP ZAP** (además de un job opcional de **Karate**).

> **Objetivo**: levantar rápidamente un entorno reproducible con Docker/Compose y correr pruebas de contrato, flujos, performance y seguridad contra la misma OAS.

---

## Tabla de contenido
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos](#requisitos)
- [Arranque rápido](#arranque-rápido)
- [Servicios base: Prism, Prism Proxy & Swagger UI](#servicios-base-prism-prism-proxy--swagger-ui)
- [Perfiles y ejecución de herramientas](#perfiles-y-ejecución-de-herramientas)
  - [StepCI (flujos end-to-end declarativos)](#stepci-flujos-end-to-end-declarativos)
  - [Dredd (contrato OpenAPI)](#dredd-contrato-openapi)
  - [k6 (performance)](#k6-performance)
  - [OWASP ZAP (seguridad)](#owasp-zap-seguridad)
  - [Karate (opcional)](#karate-opcional)
- [Notas de red y puertos](#notas-de-red-y-puertos)
- [Solución de problemas](#solución-de-problemas)
- [CI/CD en GitHub Actions](#cicd-en-github-actions)
- [Archivos clave](#archivos-clave)
- [Licencia](#licencia)

---

## Estructura del repositorio

```
/api-testing-multiverse
├── bruno/
├── dredd/
│   └── dredd.yml
├── extra/
├── k6/
│   ├── results/
│   │   └── summary.json
│   └── starwars.js
├── karate/
├── openapi/
│   ├── swapi.yaml
│   └── swapi_extended.yaml
├── prism/
│   └── prism.yml
├── stepci/
│   ├── smoke.yml
│   └── workflow.yml
├── zap/
│   ├── openapi.yaml
│   ├── zap-api-report.html
│   ├── zap-api-report.json
│   └── zap.yaml
├── docker-compose.yml
└── README.md
```

> Ajusta descripciones si cambian nombres o rutas.

---

## Requisitos
- **Docker** (20.10+) y **Docker Compose v2** (`docker compose ...`).
- Puertos libres (por defecto):
  - **4010** → Prism (mock conforme a OAS)
  - **4011** → Prism Proxy (proxy hacia `https://swapi.info/api`)
  - **8080** → Swagger UI
- **YAML** válido en `openapi/swapi.yaml`.

---

## Arranque rápido

1) Clona el repo y entra al directorio:
```bash
cd api-testing-multiverse
```

2) Levanta los **servicios base** (Prism, Prism Proxy y Swagger UI):
```bash
# logs en foreground
docker compose up
# o en segundo plano
# docker compose up -d
```

3) Verifica:
- **Prism** (mock): `http://localhost:4010`
- **Prism Proxy** (proxy → `https://swapi.info/api`): `http://localhost:4011`
- **Swagger UI**: `http://localhost:8080`

4) Ejecuta herramientas por **perfil** (ver sección siguiente). Para bajar todo:
```bash
docker compose down
```

---

## Servicios base: Prism, Prism Proxy & Swagger UI
- **Prism (mock)** lee `openapi/swapi.yaml` y responde conforme a esquemas/ejemplos. Tiene *healthcheck* a `/people`.
- **Prism Proxy** reenvía el tráfico a `https://swapi.info/api` respetando el contrato (útil para comparar mock vs real).
- **Swagger UI** sirve la documentación interactiva contra la misma OAS.

---

## Perfiles y ejecución de herramientas
> Levantá Prism/Swagger primero y luego corré cada herramienta **a demanda**.

### StepCI (flujos end-to-end declarativos)
Perfil: **`tests-stepci`**. Ejecuta el workflow en `stepci/workflow.yml` (y/o `smoke.yml`).

```bash
# Devuelve el exit code del contenedor de StepCI
docker compose --profile tests-stepci up \
  --abort-on-container-exit \
  --exit-code-from stepci-job \
  stepci-job
```

- Ajustá variables/inputs en `stepci/*.yml`.

### Dredd (contrato OpenAPI)
No está como servicio en Compose (se usa `docker run`). Dos opciones:

**A) Usando el puerto publicado (más simple):**
```bash
docker run --rm \
  -v "$PWD/openapi:/openapi:ro" \
  apiaryio/dredd:latest \
  dredd /openapi/swapi.yaml http://localhost:4010 --color
```

**B) Usando la red de Compose (para apuntar a `http://prism:4010`):**
```bash
# reemplazá <NOMBRE_RED> por el nombre real, por ejemplo: api-testing-multiverse_swapi_net
docker run --rm \
  --network <NOMBRE_RED> \
  -v "$PWD/openapi:/openapi:ro" \
  apiaryio/dredd:latest \
  dredd /openapi/swapi.yaml http://prism:4010 --color
```

> Agregá `--dry-run` si querés solo validar sin ejecutar requests.

### k6 (performance)
Perfil: **`tests-k6`**. Exporta el resumen a `k6/results/summary.json` y ejecuta `k6/starwars.js`.

```bash
docker compose --profile tests-k6 up \
  --abort-on-container-exit \
  --exit-code-from k6 \
  k6
```

- Configurá `BASE_URL` en el compose (por defecto `http://prism:4010/`).

### OWASP ZAP (seguridad)
Perfil: **`security`**. Corre **API Scan** con la OAS y deja reportes en `zap/`.

```bash
docker compose --profile security up \
  --abort-on-container-exit \
  --exit-code-from zap-api \
  zap-api
```

- Reportes: `zap/zap-api-report.html` y `zap/zap-api-report.json`.

### Karate (opcional)
Perfil: **`tests-karate`**. Si tenés features en `karate/`, podés ejecutarlas:
```bash
docker compose --profile tests-karate up \
  --abort-on-container-exit \
  --exit-code-from karate-job \
  karate-job
```

---

## Notas de red y puertos
- Dentro de la **red de Compose** podés usar el nombre del servicio (p.ej., `http://prism:4010`).
- Desde **host** usá `http://localhost:4010` (o `4011` para el proxy).
- Para contenedores externos (`docker run`), unilos a la red de Compose **o** apuntá a los puertos publicados en `localhost`.

---

## Solución de problemas
- **Dredd: "Must specify path to API description"** → Pasá ambos: ruta a OAS y URL del server de pruebas.
- **`Permission denied` al montar OAS** → Revisa permisos del archivo (`chmod 644 openapi/swapi.yaml`) y el volumen `:ro`.
- **`Invalid URL`/`Connection refused`** → Asegurate de que Prism esté *up* (`docker compose ps`, `curl http://localhost:4010`).
- **No resuelve `prism` desde `docker run`** → Usá `--network <red>` o `http://localhost:4010`.
- **Puertos ocupados** → Cambiá los puertos publicados en el compose.

---

## CI/CD en GitHub Actions
Ejemplo de pipeline que levanta los servicios base y ejecuta **StepCI**, **Dredd**, **k6** y **ZAP**, publicando artefactos clave.

Guarda como `.github/workflows/api-testing.yml`:

```yaml
name: API Testing Multiverse

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Docker Compose version
        run: docker compose version

      - name: Start base services (Prism, Proxy, Swagger)
        run: |
          docker compose up -d prism prism-proxy swagger-ui
          # Espera a que Prism esté listo (healthcheck)
          for i in {1..40}; do
            curl -fsS http://localhost:4010/people && break
            sleep 3
          done

      - name: StepCI
        run: |
          docker compose --profile tests-stepci up --abort-on-container-exit --exit-code-from stepci-job stepci-job

      - name: Dredd (contract)
        run: |
          docker run --rm \
            -v "$PWD/openapi:/openapi:ro" \
            apiaryio/dredd:latest \
            dredd /openapi/swapi.yaml http://localhost:4010 --color

      - name: k6 (performance)
        run: |
          docker compose --profile tests-k6 up --abort-on-container-exit --exit-code-from k6 k6

      - name: ZAP (security)
        run: |
          docker compose --profile security up --abort-on-container-exit --exit-code-from zap-api zap-api

      - name: Upload k6 summary
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: k6-summary
          path: k6/results/summary.json
          if-no-files-found: warn

      - name: Upload ZAP reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: zap-reports
          path: |
            zap/zap-api-report.html
            zap/zap-api-report.json
          if-no-files-found: warn

      - name: Tear down
        if: always()
        run: docker compose down -v
```

> Consejo: agregá esta acción como **status check** requerido en tu repositorio para PRs.

---

## Archivos clave
- **`openapi/swapi.yaml`** — OAS principal
- **`k6/starwars.js`** — script de carga (exporta resumen a `k6/results/summary.json`)
- **`stepci/workflow.yml`** — workflow de StepCI (y `smoke.yml` para smoke tests)
- **`zap/zap.yaml`** — config adicional de ZAP (si aplica)
- **`dredd/dredd.yml`** — configuración/hooks de Dredd (si aplica)
- **`prism/prism.yml`** — reglas de Prism (si aplica)
- **`docker-compose.yml`** — servicios, perfiles y red

---


### ✨ Créditos

Creado para facilitar pruebas de APIs REST usando la especificación OpenAPI.
