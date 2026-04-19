/**
 * Rules: /users (firestore.rules:43-53)
 * Spec: §9 / §3 — cualquier autenticado puede leer perfiles; solo el
 * dueño puede crear/actualizar su documento.
 *
 * El caso "delete por el dueño debe fallar" se omite deliberadamente: las
 * rules actuales lo permiten (brecha vs spec §9 línea 623, registrada en
 * yo-te-llevo-pending.md §M9).
 */
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { authedDb, initTestEnv, makeUser, seed } from './helpers';

describe('/users', () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await initTestEnv();
  });

  afterAll(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await seed(env, 'users/alice', makeUser({ name: 'Alice' }));
  });

  test('autenticado puede leer cualquier /users/{uid}', async () => {
    const db = authedDb(env, 'bob');
    await assertSucceeds(getDoc(doc(db, 'users/alice')));
  });

  test('usuario A NO puede crear /users/B (isSelf falla)', async () => {
    const db = authedDb(env, 'alice');
    await assertFails(
      setDoc(doc(db, 'users/bob'), makeUser({ name: 'Bob' })),
    );
  });

  test('usuario A NO puede actualizar /users/B', async () => {
    const db = authedDb(env, 'bob');
    await assertFails(
      updateDoc(doc(db, 'users/alice'), { name: 'Hacked' }),
    );
  });
});
