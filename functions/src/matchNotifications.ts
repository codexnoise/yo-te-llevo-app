import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";

import {sendPushToUser} from "./push";

const STATUS_LABELS: Record<string, string> = {
  accepted: "aceptó tu solicitud",
  rejected: "rechazó tu solicitud",
  cancelled: "canceló el viaje",
  completed: "marcó el viaje como completado",
  active: "inició el viaje",
};

/**
 * Envía push al conductor cuando un pasajero crea una solicitud (status = pending).
 */
export const onMatchCreated = onDocumentCreated(
  "matches/{matchId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const match = snap.data();
    const matchId = event.params.matchId;
    const driverId = match.driverId as string | undefined;

    if (!driverId) {
      logger.warn("onMatchCreated: match sin driverId", {matchId});
      return;
    }
    if (match.status !== "pending") {
      logger.debug("onMatchCreated: status inicial != pending, skip", {matchId});
      return;
    }

    await sendPushToUser(driverId, {
      title: "Nueva solicitud de viaje",
      body: "Un pasajero quiere unirse a tu ruta.",
      data: {
        matchId,
        type: "trip_request",
      },
    });
  }
);

/**
 * Envía push a la contraparte cuando el status cambia a accepted, rejected,
 * cancelled, active o completed.
 */
export const onMatchStatusChanged = onDocumentUpdated(
  "matches/{matchId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) return;

    const matchId = event.params.matchId;
    const fromStatus = beforeData.status as string;
    const toStatus = afterData.status as string;
    if (fromStatus === toStatus) return;
    if (!STATUS_LABELS[toStatus]) return;

    const passengerId = afterData.passengerId as string;
    const driverId = afterData.driverId as string;

    // Recipient = la contraparte del que probablemente hizo el cambio.
    // No tenemos el uid del actor en el trigger. Usamos heurística:
    // - accepted / rejected / active / completed: el driver responde → notifica al pasajero.
    // - cancelled: puede ser cualquiera; notificamos a ambos.
    const recipients: string[] = [];
    if (toStatus === "cancelled") {
      recipients.push(passengerId, driverId);
    } else if (["accepted", "rejected", "active", "completed"].includes(toStatus)) {
      recipients.push(passengerId);
    }

    if (recipients.length === 0) return;

    const title = toStatus === "cancelled"
      ? "Viaje cancelado"
      : `El conductor ${STATUS_LABELS[toStatus]}`;
    const body = toStatus === "cancelled"
      ? "Uno de los participantes canceló este viaje."
      : "Abre la app para ver los detalles.";

    await Promise.all(
      recipients.map((uid) =>
        sendPushToUser(uid, {
          title,
          body,
          data: {
            matchId,
            type: "status_change",
            status: toStatus,
          },
        })
      )
    );
  }
);

