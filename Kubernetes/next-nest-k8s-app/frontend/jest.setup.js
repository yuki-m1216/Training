import '@testing-library/jest-dom';

// Suppress act warnings in tests
global.IS_REACT_ACT_ENVIRONMENT = true;

// Setup for tests
beforeEach(() => {
  // Clear all mocks before each test
  jest.clearAllMocks();
});
