import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

// Base URL por env (fallback a Prism del compose)
const BASE_URL = __ENV.BASE_URL || 'http://prism:4010/';

// Métricas personalizadas
export const httpOK = new Rate('http_ok');
export const peopleDuration = new Trend('people_duration');

// IDs de ejemplo (ajustá si querés otros)
const IDS = {
  people:   [1, 2, 3, 4, 5],
  films:    [1, 2, 3, 4, 5, 6],
  planets:  [1, 2, 3, 4, 5],
  starships:[2, 3, 5, 9],
  species:  [1, 2, 3, 4, 5],
  vehicles: [4, 6, 7, 8]
};

export const options = {
  // Tres escenarios útiles
  scenarios: {
    // Smoke: valida que “todo responde” rápido con poca carga
    smoke: {
      executor: 'constant-vus',
      vus: 2,
      duration: '30s',
      exec: 'scenarioSmoke',
      tags: { scenario: 'smoke' },
    },
    // Ramp-up / baseline
    ramp: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 10 },
        { duration: '1m',  target: 10 },
        { duration: '30s', target: 0  },
      ],
      gracefulRampDown: '10s',
      exec: 'scenarioRamp',
      tags: { scenario: 'ramp' },
    },
    // Stress (arrival rate) para ver límites y errores
    stress: {
      executor: 'constant-arrival-rate',
      rate: 40,              // req/seg totales
      timeUnit: '1s',
      duration: '1m',
      preAllocatedVUs: 20,
      maxVUs: 50,
      exec: 'scenarioStress',
      tags: { scenario: 'stress' },
    },
  },

  // SLO / thresholds
  thresholds: {
    http_req_failed: ['rate<0.01'],            // <1% errores
    http_req_duration: ['p(95)<500'],          // p95 < 500 ms
    'people_duration': ['p(95)<400'],          // métrica custom en people
    'checks': ['rate>0.99'],                   // >=99% checks OK
  },

  // Etiquetas por defecto
  tags: { project: 'swapi', tool: 'k6' },
};

// Utilidad para GET con checks comunes
function getAndCheck(path, expectArray = false) {
  const res = http.get(`${BASE_URL}${path}`, { tags: { endpoint: path } });

  const ok = check(res, {
    'status 200': (r) => r.status === 200,
    'content-type JSON': (r) => (r.headers['Content-Type'] || '').includes('application/json'),
    ...(expectArray
      ? { 'body is array': (r) => Array.isArray(r.json()) }
      : { 'body is object': (r) => r.json() && typeof r.json() === 'object' }
    ),
  });

  httpOK.add(ok);
  if (path.startsWith('people')) {
    peopleDuration.add(res.timings.duration);
  }
  return res;
}

// Utilidad para esperar 404
function get404(path) {
  const res = http.get(`${BASE_URL}${path}`, { tags: { endpoint: `${path}-404` } });
  check(res, { 'status 404': (r) => r.status === 404 });
  return res;
}

// ---- ESCENARIOS ----

// Smoke: 1 ronda de listas + 1 detalle + 404 por recurso
export function scenarioSmoke() {
  const lists = ['people', 'films', 'planets', 'starships', 'species', 'vehicles'];
  lists.forEach((p) => getAndCheck(p, true));

  getAndCheck(`people/${pick(IDS.people)}`);
  getAndCheck(`films/${pick(IDS.films)}`);
  getAndCheck(`planets/${pick(IDS.planets)}`);
  getAndCheck(`starships/${pick(IDS.starships)}`);
  getAndCheck(`species/${pick(IDS.species)}`);
  getAndCheck(`vehicles/${pick(IDS.vehicles)}`);

  // 404
  get404('people/999999');
  get404('films/999999');
  get404('planets/999999');
  get404('starships/999999');
  get404('species/999999');
  get404('vehicles/999999');

  sleep(1);
}

// Ramp: mezcla de listas + detalles random
export function scenarioRamp() {
  const resources = ['people', 'films', 'planets', 'starships', 'species', 'vehicles'];
  const r = resources[Math.floor(Math.random() * resources.length)];
  getAndCheck(r, true);
  const id = pick(IDS[r]);
  getAndCheck(`${r}/${id}`);
  sleep(0.3);
}

// Stress: foco en un par de endpoints “calientes”
export function scenarioStress() {
  // ejemplo: people y films concentran tráfico
  if (Math.random() < 0.6) {
    getAndCheck(`people/${pick(IDS.people)}`);
  } else {
    getAndCheck(`films/${pick(IDS.films)}`);
  }
}

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
