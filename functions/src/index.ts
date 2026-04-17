import {initializeApp} from "firebase-admin/app";

initializeApp();

export {onMatchCreated, onMatchStatusChanged} from "./matchNotifications";
export {onMessageCreated} from "./messageNotifications";
