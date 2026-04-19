/** @type {import('jest').Config} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/*.test.ts'],
  // El harness levanta un emulador in-process por suite; correr en serie
  // evita colisiones de puerto entre workers.
  maxWorkers: 1,
  testTimeout: 30000,
};
