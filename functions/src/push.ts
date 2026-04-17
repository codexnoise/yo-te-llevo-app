import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions/v2";

export interface PushPayload {
  title: string;
  body: string;
  data: Record<string, string>;
}

/**
 * Envía una notificación push al [userId] leyendo su `fcmToken` de
 * `/users/{userId}`. Si el token está inválido o revocado, lo limpia.
 */
export async function sendPushToUser(
  userId: string,
  payload: PushPayload
): Promise<void> {
  const userSnap = await getFirestore().doc(`users/${userId}`).get();
  const token = userSnap.get("fcmToken") as string | undefined;

  if (!token) {
    logger.info("sendPushToUser: usuario sin fcmToken", {userId});
    return;
  }

  try {
    await getMessaging().send({
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
      android: {
        priority: "high",
        notification: {
          channelId: "yo_te_llevo_default",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
  } catch (error: unknown) {
    const err = error as {code?: string; errorInfo?: {code?: string}};
    const code = err?.code ?? err?.errorInfo?.code ?? "unknown";
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      logger.warn("Token FCM inválido, limpiando", {userId, code});
      await getFirestore()
        .doc(`users/${userId}`)
        .update({fcmToken: null})
        .catch(() => undefined);
      return;
    }
    logger.error("Error enviando push", {userId, code, error});
  }
}
