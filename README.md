# API Testing Multiverse — SWAPI (Star Wars)

Repositorio para experimentar un **multiverso de testing de APIs** alrededor de una especificación **OpenAPI de Star Wars (SWAPI)**. Incluye mock/proxy con Prism, documentación con Swagger UI y herramientas de testing: **StepCI**, **Dredd**, **k6**, **OWASP ZAP** y **Karate**.

> **Objetivo**: levantar rápidamente un entorno reproducible con Docker/Compose y correr pruebas de contrato, flujos, performance y seguridad contra la misma OAS.

---

## Tabla de contenido
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos](#requisitos)
- [Arranque rápido](#arranque-rápido)
- [Servicios base: Prism, Prism Proxy & Swagger UI](#servicios-base-prism-prism-proxy--swagger-ui)
- [Cómo ejecutar las pruebas (scripts `run-*`)](#cómo-ejecutar-las-pruebas-scripts-run-)
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
├── bruno/                      # Files de Bruno, generados al importar el openapi
├── dredd/
│   └── dredd.yml
├── extra/                      # Material extra
├── k6/
│   ├── results/
│   │   └── summary.json
│   └── starwars.js
├── karate/
│   ├── target/                 # salida de build/runner
│   ├── auto.feature            # ejemplo de feature
│   ├── build-karate.sh         # helper para construir imagen
│   ├── Dockerfile              # imagen para ejecutar tests
│   └── karate-config.js        # configuración de Karate
├── openapi/
│   ├── swapi.yaml              # openapi estandar 
│   └── swapi_extended.yaml     # openapi extendida, para una implementacion con metodos POST / PATCH
├── prism/
│   └── prism.yml
├── stepci/
│   ├── smoke.yml
│   └── workflow.yml
├── zap/
│   ├── automation.yaml         # plan de automatización de ZAP
│   ├── openapi.yaml            # OAS para ZAP (si aplica, se genera al correr la imagen Docker)
│   ├── zap-automation.html     # reporte HTML
│   └── zap.yaml                # config adicional
├── docker-compose.yml
├── README.md
├── run-dredd-tests.sh
├── run-k6-tests.sh
├── run-karate-tests.sh
├── run-stepci-tests.sh
└── run-zap-tests.sh
```

> Las rutas pueden evolucionar; en cada sección se indica dónde ajustar variables si cambian.

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

2) **Levantá los servicios base** (Prism, Prism Proxy y Swagger UI):
```bash
# logs en foreground
docker compose up
# o en segundo plano
# docker compose up -d
```
> **¿Es necesario levantar el entorno antes de correr los tests?** Sí. Los scripts `run-*` asumen que Prism/Swagger ya están arriba para poder alcanzar `http://prism:4010` (o `http://localhost:4010`).

3) Verifica desde host:
- **Prism (mock)**: `http://localhost:4010`
- **Prism Proxy**: `http://localhost:4011`
- **Swagger UI**: `http://localhost:8080`

Para bajar todo:
```bash
docker compose down
```

---

## Servicios base: Prism, Prism Proxy & Swagger UI
- **Prism (mock)** lee `openapi/swapi.yaml` y responde conforme a esquemas/ejemplos. Tiene *healthcheck* a `/people`.
- **Prism Proxy** reenvía tráfico a `https://swapi.info/api` respetando el contrato (útil para comparar mock vs real).
- **Swagger UI** sirve la documentación interactiva contra la misma OAS.

---

## Cómo ejecutar las pruebas (scripts `run-*`)
> Desde la raíz del repo, con el entorno base ya levantado. Si fuera necesario, marcá los scripts como ejecutables: `chmod +x run-*.sh`

### StepCI (flujos end-to-end declarativos)
Ejecuta los escenarios definidos en `stepci/workflow.yml` (y/o `smoke.yml`).
```bash
./run-stepci-tests.sh
```
> Ajustá variables/inputs en `stepci/*.yml`.

### Dredd (contrato OpenAPI)
Valida que las respuestas cumplen el contrato en `openapi/swapi.yaml`.
```bash
./run-dredd-tests.sh
```
> Si querés sólo simular, agregá `--dry-run` dentro del script.

### k6 (performance)
Ejecuta `k6/starwars.js` y guarda el resumen en `k6/results/summary.json`.
```bash
./run-k6-tests.sh
```

### OWASP ZAP (seguridad)
Lanza el escaneo automático con configuración de `zap/automation.yaml`. Genera reporte HTML.
```bash
./run-zap-tests.sh
```
> Los reportes quedan en `zap/zap-automation.html` (y/o JSON si está configurado).

### Karate 
1. Usá `karate/build-karate.sh` para construir/actualizar la imagen Docker.

2. Ejecuta las *features* de `karate/` usando la imagen definida en `karate/Dockerfile`.
```bash
./run-karate-tests.sh
```

---

## Notas de red y puertos
- Dentro de la **red de Compose** usá el nombre del servicio (p.ej., `http://prism:4010`).
- Desde **host** usá `http://localhost:4010` (o `4011` para el proxy).
- Si ejecutás contenedores externos, unilos a la red de Compose **o** apuntá a los puertos publicados en `localhost`.

---

## Solución de problemas
- **Dredd: "Must specify path to API description"** → El runner debe pasar la ruta a la OAS **y** la URL del server de pruebas.
- **`Permission denied` al montar OAS** → Verificá permisos del archivo (`chmod 644 openapi/swapi.yaml`) y el volumen `:ro`.
- **`Invalid URL`/`Connection refused`** → Asegurate de que Prism esté *up* (`docker compose ps`, `curl http://localhost:4010`).
- **No resuelve `prism` desde un contenedor** → Usá `--network <red>` o `http://localhost:4010`.
- **Puertos ocupados** → Cambiá los puertos publicados en el compose.

---

## CI/CD en GitHub Actions
Ejemplo de pipeline que **levanta los servicios base** y ejecuta **los scripts `run-*`**, publicando artefactos.

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

      - name: Start base services (Prism, Proxy, Swagger)
        run: |
          docker compose up -d prism prism-proxy swagger-ui
          # Espera a que Prism esté listo
          for i in {1..40}; do
            curl -fsS http://localhost:4010/people && break
            sleep 3
          done

      - name: StepCI
        run: ./run-stepci-tests.sh

      - name: Dredd (contract)
        run: ./run-dredd-tests.sh

      - name: k6 (performance)
        run: ./run-k6-tests.sh

      - name: ZAP (security)
        run: ./run-zap-tests.sh

      - name: Karate (optional)
        if: ${{ false }} # Cambia a true si querés incluir Karate en el pipeline
        run: ./run-karate-tests.sh

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
            zap/zap-automation.html
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
- **`openapi/swapi_extended.yaml`** — variantes/recursos extendidos
- **`k6/starwars.js`** — script de carga (exporta resumen a `k6/results/summary.json`)
- **`stepci/workflow.yml`** — workflow de StepCI (y `smoke.yml` para smoke tests)
- **`zap/automation.yaml`**, **`zap/zap.yaml`** — configuración ZAP; reportes en `zap/zap-automation.html`
- **`dredd/dredd.yml`** — configuración/hooks de Dredd
- **`prism/prism.yml`** — reglas de Prism
- **`karate/*.feature`, `karate-config.js`, `karate/Dockerfile`** — tests de Karate
- **Scripts `run-*`** — runners de cada herramienta
- **`docker-compose.yml`** — servicios, perfiles y red

---


### ✨ Créditos

Creado para facilitar pruebas de APIs REST usando la especificación OpenAPI.
