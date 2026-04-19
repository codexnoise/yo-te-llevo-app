/**
 * Rules: /matches/{matchId}/messages/{messageId} (firestore.rules:83-94)
 * Spec: §9 / §7 — solo participantes del match padre pueden leer; create
 * solo si senderId == auth.uid y el usuario es participante; delete
 * nunca.
 */
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc } from 'firebase/firestore';
import {
  authedDb,
  initTestEnv,
  makeMatch,
  makeMessage,
  seed,
} from './helpers';

describe('/matches/{matchId}/messages', () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await initTestEnv();
  });

  afterAll(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await seed(env, 'matches/m1', makeMatch('alice', 'bob'));
    await seed(env, 'matches/m1/messages/seeded', makeMessage('alice'));
  });

  test('participante puede crear mensaje con senderId = self', async () => {
    const db = authedDb(env, 'alice');
    await assertSucceeds(
      setDoc(
        doc(db, 'matches/m1/messages/msg-new'),
        makeMessage('alice'),
      ),
    );
  });

  test('no-participante NO puede crear mensaje', async () => {
    const db = authedDb(env, 'carol');
    await assertFails(
      setDoc(
        doc(db, 'matches/m1/messages/msg-new'),
        makeMessage('carol'),
      ),
    );
  });

  test('participante NO puede crear mensaje con senderId != self', async () => {
    const db = authedDb(env, 'alice');
    await assertFails(
      setDoc(doc(db, 'matches/m1/messages/msg-new'), makeMessage('bob')),
    );
  });

  test('delete de mensajes falla siempre', async () => {
    const db = authedDb(env, 'alice');
    await assertFails(deleteDoc(doc(db, 'matches/m1/messages/seeded')));
  });
});
