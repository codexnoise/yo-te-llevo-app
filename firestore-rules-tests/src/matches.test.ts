/**
 * Rules: /matches (firestore.rules:67-95)
 * Spec: §9 / §6 — lectura solo por participantes; create solo por
 * passenger con status=pending; update con campos inmutables y
 * transiciones válidas; delete nunca.
 */
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { authedDb, initTestEnv, makeMatch, seed } from './helpers';

describe('/matches', () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await initTestEnv();
  });

  afterAll(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    // Match pending entre alice (pasajero) y bob (conductor).
    await seed(env, 'matches/m1', makeMatch('alice', 'bob'));
  });

  describe('read', () => {
    test('participante (passenger) puede leer su match', async () => {
      const db = authedDb(env, 'alice');
      await assertSucceeds(getDoc(doc(db, 'matches/m1')));
    });

    test('participante (driver) puede leer su match', async () => {
      const db = authedDb(env, 'bob');
      await assertSucceeds(getDoc(doc(db, 'matches/m1')));
    });

    test('no-participante NO puede leer el match', async () => {
      const db = authedDb(env, 'carol');
      await assertFails(getDoc(doc(db, 'matches/m1')));
    });
  });

  describe('create', () => {
    test('passenger puede crear match propio con status pending', async () => {
      const db = authedDb(env, 'alice');
      await assertSucceeds(
        setDoc(doc(db, 'matches/m-new'), makeMatch('alice', 'bob')),
      );
    });

    test('NO permite create si passengerId != auth.uid', async () => {
      const db = authedDb(env, 'carol');
      await assertFails(
        setDoc(doc(db, 'matches/m-new'), makeMatch('alice', 'bob')),
      );
    });

    test('NO permite create con status != pending', async () => {
      const db = authedDb(env, 'alice');
      await assertFails(
        setDoc(
          doc(db, 'matches/m-new'),
          makeMatch('alice', 'bob', { status: 'accepted' }),
        ),
      );
    });
  });

  describe('update', () => {
    test('transición legal pending→accepted pasa', async () => {
      const db = authedDb(env, 'bob');
      await assertSucceeds(
        updateDoc(doc(db, 'matches/m1'), { status: 'accepted' }),
      );
    });

    test('transición ilegal pending→completed falla', async () => {
      const db = authedDb(env, 'bob');
      await assertFails(
        updateDoc(doc(db, 'matches/m1'), { status: 'completed' }),
      );
    });

    test('update que muta passengerId falla', async () => {
      const db = authedDb(env, 'alice');
      await assertFails(
        updateDoc(doc(db, 'matches/m1'), { passengerId: 'carol' }),
      );
    });
  });

  describe('delete', () => {
    test('participante NO puede borrar un match', async () => {
      const db = authedDb(env, 'alice');
      await assertFails(deleteDoc(doc(db, 'matches/m1')));
    });
  });
});
