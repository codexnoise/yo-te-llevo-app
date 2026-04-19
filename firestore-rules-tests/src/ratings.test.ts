/**
 * Rules: /ratings/{ratingId} (firestore.rules:103-112)
 * Spec: §9 / §8 — create solo si fromUserId == auth.uid, fromUserId !=
 * toUserId, stars entero 1..5; update/delete nunca.
 */
import {
  RulesTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc, updateDoc } from 'firebase/firestore';
import { authedDb, initTestEnv, makeRating, seed } from './helpers';

describe('/ratings', () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    env = await initTestEnv();
  });

  afterAll(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await env.clearFirestore();
    await seed(env, 'ratings/existing', makeRating('alice', 'bob', 'm1'));
  });

  test('create válido (fromUserId = self, stars 1..5, no-self) pasa', async () => {
    const db = authedDb(env, 'alice');
    await assertSucceeds(
      setDoc(
        doc(db, 'ratings/new-ok'),
        makeRating('alice', 'bob', 'm2', { stars: 4 }),
      ),
    );
  });

  test('create con fromUserId != auth.uid falla', async () => {
    const db = authedDb(env, 'carol');
    await assertFails(
      setDoc(
        doc(db, 'ratings/new-spoof'),
        makeRating('alice', 'bob', 'm2'),
      ),
    );
  });

  test('create con stars = 6 falla', async () => {
    const db = authedDb(env, 'alice');
    await assertFails(
      setDoc(
        doc(db, 'ratings/new-bad-stars'),
        makeRating('alice', 'bob', 'm2', { stars: 6 }),
      ),
    );
  });

  test('create con fromUserId == toUserId falla', async () => {
    const db = authedDb(env, 'alice');
    await assertFails(
      setDoc(
        doc(db, 'ratings/new-self'),
        makeRating('alice', 'alice', 'm2'),
      ),
    );
  });

  test('update de un rating existente falla', async () => {
    const db = authedDb(env, 'alice');
    await assertFails(
      updateDoc(doc(db, 'ratings/existing'), { stars: 5 }),
    );
  });

  test('delete de un rating existente falla', async () => {
    const db = authedDb(env, 'alice');
    await assertFails(deleteDoc(doc(db, 'ratings/existing')));
  });
});
