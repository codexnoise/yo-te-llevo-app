import {getFirestore} from "firebase-admin/firestore";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";

import {sendPushToUser} from "./push";

const PREVIEW_MAX_LENGTH = 100;

/**
 * Envía push al otro participante del match cuando un usuario publica un
 * mensaje nuevo (spec §7.2). No notifica al autor.
 */
export const onMessageCreated = onDocumentCreated(
  "matches/{matchId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const matchId = event.params.matchId;
    const messageId = event.params.messageId;
    const data = snap.data();
    const senderId = data.senderId as string | undefined;
    const text = data.text as string | undefined;

    if (!senderId || !text) {
      logger.warn("onMessageCreated: mensaje inválido", {matchId, messageId});
      return;
    }

    const matchSnap = await getFirestore()
      .doc(`matches/${matchId}`)
      .get();
    if (!matchSnap.exists) {
      logger.warn("onMessageCreated: match padre no existe", {matchId});
      return;
    }

    const passengerId = matchSnap.get("passengerId") as string | undefined;
    const driverId = matchSnap.get("driverId") as string | undefined;

    if (!passengerId || !driverId) {
      logger.warn("onMessageCreated: match sin participantes", {matchId});
      return;
    }

    const recipientId =
      senderId === passengerId ? driverId :
        senderId === driverId ? passengerId :
          undefined;

    if (!recipientId) {
      // senderId no coincide con ningún participante: las rules lo bloquean,
      // pero defendemos por las dudas.
      logger.warn("onMessageCreated: senderId no es participante", {
        matchId,
        senderId,
      });
      return;
    }

    // Obtener nombre del sender; fallback al genérico si no está disponible.
    const senderSnap = await getFirestore()
      .doc(`users/${senderId}`)
      .get()
      .catch(() => undefined);
    const senderName = senderSnap?.get("name") as string | undefined;

    const title = senderName && senderName.trim().length > 0 ?
      senderName :
      "Nuevo mensaje";
    const body = text.length > PREVIEW_MAX_LENGTH ?
      `${text.substring(0, PREVIEW_MAX_LENGTH)}…` :
      text;

    await sendPushToUser(recipientId, {
      title,
      body,
      data: {
        matchId,
        messageId,
        type: "chat_message",
      },
    });
  }
);
