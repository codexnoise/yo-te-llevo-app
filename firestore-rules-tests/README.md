# firestore-rules-tests

Harness de tests automatizados para el archivo `../firestore.rules`
(Yo Te Llevo — Módulo 9 del spec).

Los tests levantan el **emulador de Firestore** in-process vía
[`@firebase/rules-unit-testing`](https://firebase.google.com/docs/rules/unit-tests)
y validan los criterios de aceptación del spec §9:

- Un usuario no puede leer matches de otros usuarios.
- No se puede crear una ruta con `driverId` de otro usuario.
- Solo participantes pueden crear mensajes en el chat.
- Los ratings no se pueden modificar ni eliminar.
- Transiciones de status inválidas de un match son rechazadas.
- Campos inmutables de un match no pueden mutarse.

## Requisitos

- **Node 20** (idéntico a `functions/`).
- **Java 21+** en el PATH — el emulador de Firestore es un jar; las
  versiones actuales de `firebase-tools` rechazan JDK < 21. Verificar
  con `java -version`.
  - macOS con Homebrew: `brew install openjdk@21` y seguir las
    instrucciones del `brew info` para agregarlo al PATH.
- **`firebase-tools`** accesible (global o vía `npx`). El harness lo
  invoca internamente para bajar/levantar el binario del emulador.
- **Emulador de Firestore corriendo** antes de `npm test`. Desde el
  directorio raíz del proyecto:
  ```bash
  firebase emulators:start --only firestore --project yo-te-llevo-tests
  ```
  Dejarlo corriendo en otra terminal y luego ejecutar los tests. Puerto
  por defecto: `8080` (configurado en `../firebase.json`).

## Uso

```bash
cd firestore-rules-tests
npm install
npm test
```

Esperado: ~20 casos en verde.

Para desarrollar los tests:

```bash
npm run test:watch
```

## Alcance

Baseline mínimo: un archivo por colección en `src/`, cubriendo los
criterios de aceptación §9 tal como están hoy (sin forzar hardenings
pendientes). Las brechas detectadas entre spec y `firestore.rules` están
documentadas en `../claude/yo-te-llevo-pending.md` §Módulo 9.
