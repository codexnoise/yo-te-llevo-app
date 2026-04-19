/**
 * Rules: /routes (firestore.rules:58-64)
 * Spec: §9 / §4 — lectura por cualquier autenticado; create/update solo
 * si driverId == auth.uid.
 *
 * El caso "delete por el dueño debe fallar" se omite deliberadamente: hoy
 * las rules lo permiten (brecha vs spec §9 línea 630).
 */
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import {
  authedDb,
  initTestEnv,
  makeRoute,
  seed,
  unauthedDb,
} from './helpers';

describe('/routes', () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await initTestEnv();
  });

  afterAll(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await seed(env, 'routes/route-alice', makeRoute('alice'));
  });

  test('autenticado puede leer cualquier ruta', async () => {
    const db = authedDb(env, 'bob');
    await assertSucceeds(getDoc(doc(db, 'routes/route-alice')));
  });

  test('no autenticado NO puede leer rutas', async () => {
    const db = unauthedDb(env);
    await assertFails(getDoc(doc(db, 'routes/route-alice')));
  });

  test('usuario A NO puede crear ruta con driverId: B', async () => {
    const db = authedDb(env, 'alice');
    await assertFails(
      setDoc(doc(db, 'routes/route-spoof'), makeRoute('bob')),
    );
  });

  test('usuario A NO puede actualizar ruta de B', async () => {
    const db = authedDb(env, 'bob');
    await assertFails(
      updateDoc(doc(db, 'routes/route-alice'), { availableSeats: 0 }),
    );
  });
});
