import { readFileSync } from 'fs';
import { resolve } from 'path';
import {
  RulesTestEnvironment,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Firestore, setDoc, doc } from 'firebase/firestore';

/**
 * Inicializa un entorno de tests contra el archivo real `firestore.rules`
 * del proyecto (ubicado en `../firestore.rules`).
 *
 * Cada suite debe llamar esto en `beforeAll` y guardar el env, y en
 * `afterAll` hacer `env.cleanup()`.
 */
export async function initTestEnv(): Promise<RulesTestEnvironment> {
  const rulesPath = resolve(__dirname, '..', '..', 'firestore.rules');
  const rules = readFileSync(rulesPath, 'utf8');
  return initializeTestEnvironment({
    projectId: 'yo-te-llevo-tests',
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });
}

/** Firestore autenticado como `uid`. */
export function authedDb(env: RulesTestEnvironment, uid: string): Firestore {
  return env.authenticatedContext(uid).firestore() as unknown as Firestore;
}

/** Firestore sin autenticar (anónimo). */
export function unauthedDb(env: RulesTestEnvironment): Firestore {
  return env.unauthenticatedContext().firestore() as unknown as Firestore;
}

/**
 * Siembra un documento con las rules deshabilitadas. Útil para preparar
 * estado inicial (un match existente, una ruta de otro conductor, etc.)
 * sin tener que satisfacer las rules de create.
 */
export async function seed(
  env: RulesTestEnvironment,
  path: string,
  data: Record<string, unknown>,
): Promise<void> {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore() as unknown as Firestore;
    await setDoc(doc(db, path), data);
  });
}

// ---------------------------------------------------------------------------
// Factories de fixtures — valores mínimos que satisfacen las rules actuales.
// ---------------------------------------------------------------------------

export function makeUser(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    name: 'Test User',
    email: 'test@example.com',
    role: 'passenger',
    rating: 5.0,
    totalTrips: 0,
    createdAt: new Date(),
    ...overrides,
  };
}

export function makeRoute(
  driverId: string,
  overrides: Partial<Record<string, unknown>> = {},
) {
  return {
    driverId,
    originLat: -2.9,
    originLng: -79.0,
    originAddress: 'A',
    destinationLat: -2.91,
    destinationLng: -79.01,
    destinationAddress: 'B',
    polyline: '',
    geohashOrigin: 'd29',
    geohashDestination: 'd29',
    distance: 1000,
    duration: 600,
    schedule: { days: ['mon'], departureTime: '08:00' },
    pricing: { type: 'perTrip', amount: 1.0, currency: 'USD' },
    availableSeats: 3,
    isActive: true,
    createdAt: new Date(),
    ...overrides,
  };
}

export function makeMatch(
  passengerId: string,
  driverId: string,
  overrides: Partial<Record<string, unknown>> = {},
) {
  return {
    passengerId,
    driverId,
    routeId: 'route-1',
    status: 'pending',
    pickupLat: -2.9,
    pickupLng: -79.0,
    pickupAddress: 'pickup',
    dropoffLat: -2.91,
    dropoffLng: -79.01,
    dropoffAddress: 'dropoff',
    distanceToPickup: 200,
    distanceToDropoff: 300,
    detourDuration: 120,
    schedule: { type: 'oneTime', days: ['mon'] },
    pricing: { type: 'perTrip', amount: 1.0 },
    createdAt: new Date(),
    ...overrides,
  };
}

export function makeMessage(
  senderId: string,
  overrides: Partial<Record<string, unknown>> = {},
) {
  return {
    senderId,
    text: 'hola',
    timestamp: new Date(),
    read: false,
    ...overrides,
  };
}

export function makeRating(
  fromUserId: string,
  toUserId: string,
  matchId: string,
  overrides: Partial<Record<string, unknown>> = {},
) {
  return {
    fromUserId,
    toUserId,
    matchId,
    stars: 4,
    comment: null,
    createdAt: new Date(),
    ...overrides,
  };
}
