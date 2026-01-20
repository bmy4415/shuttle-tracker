import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for Shuttle Tracker multi-user E2E tests
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './tests',

  // Run tests in parallel
  fullyParallel: false, // Sequential for multi-user sync tests

  // Fail the build on CI if you accidentally left test.only in the source code
  forbidOnly: !!process.env.CI,

  // Retry on CI only
  retries: process.env.CI ? 2 : 0,

  // Opt out of parallel tests on CI
  workers: 1,

  // Reporter to use
  reporter: 'html',

  // Shared settings for all the projects below
  use: {
    // Base URL for the apps
    baseURL: 'http://localhost:5001',

    // Collect trace when retrying the failed test
    trace: 'on-first-retry',

    // Screenshot on failure
    screenshot: 'only-on-failure',

    // Video on failure
    video: 'on-first-retry',
  },

  // Configure projects for major browsers
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  // Custom timeout for multi-user sync tests
  timeout: 60000,
  expect: {
    timeout: 10000,
  },
});
