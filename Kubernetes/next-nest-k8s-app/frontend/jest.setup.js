import '@testing-library/jest-dom';

// Suppress act warnings in tests
global.IS_REACT_ACT_ENVIRONMENT = true;

// Setup for tests
beforeEach(() => {
  // Clear all mocks before each test
  jest.clearAllMocks();
});

// Suppress console.error for act warnings during tests
const originalError = console.error;
console.error = (...args) => {
  if (
    typeof args[0] === 'string' &&
    args[0].includes('An update to') &&
    args[0].includes('act(...)')
  ) {
    return;
  }
  originalError(...args);
};
