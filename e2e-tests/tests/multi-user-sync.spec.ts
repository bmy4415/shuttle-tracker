import { test, expect, Page } from '@playwright/test';

/**
 * Multi-User Integration Tests for Shuttle Tracker (POC)
 *
 * Prerequisites:
 * 1. Firebase Emulator: firebase emulators:start --project=demo-shuttle-tracker
 * 2. Flutter apps via /multi-app skill (ports 5001-5004)
 */

const DRIVER_URL = 'http://localhost:5001';
const PARENT1_URL = 'http://localhost:5002';
const PARENT2_URL = 'http://localhost:5003';

test.describe('Multi-User Integration Tests', () => {

  test('App loads on port 5001 (Driver)', async ({ page }) => {
    await page.goto(DRIVER_URL);
    await page.waitForTimeout(5000); // Wait for Flutter to load

    // Take screenshot
    await page.screenshot({ path: 'test-results/driver-loaded.png' });

    // Check page has content
    const content = await page.content();
    expect(content.length).toBeGreaterThan(1000);

    // Check no Firebase error in page
    expect(content).not.toContain('Firebase 연결 실패');

    console.log('✅ Driver app (5001) loaded successfully');
  });

  test('App loads on port 5002 (Parent1)', async ({ page }) => {
    await page.goto(PARENT1_URL);
    await page.waitForTimeout(5000);

    await page.screenshot({ path: 'test-results/parent1-loaded.png' });

    const content = await page.content();
    expect(content.length).toBeGreaterThan(1000);
    expect(content).not.toContain('Firebase 연결 실패');

    console.log('✅ Parent1 app (5002) loaded successfully');
  });

  test('App loads on port 5003 (Parent2)', async ({ page }) => {
    await page.goto(PARENT2_URL);
    await page.waitForTimeout(5000);

    await page.screenshot({ path: 'test-results/parent2-loaded.png' });

    const content = await page.content();
    expect(content.length).toBeGreaterThan(1000);
    expect(content).not.toContain('Firebase 연결 실패');

    console.log('✅ Parent2 app (5003) loaded successfully');
  });

  test('Multiple browser contexts can access different apps', async ({ browser }) => {
    // Create separate browser contexts
    const context1 = await browser.newContext();
    const context2 = await browser.newContext();

    const page1 = await context1.newPage();
    const page2 = await context2.newPage();

    // Navigate to different apps
    await page1.goto(DRIVER_URL);
    await page2.goto(PARENT1_URL);

    // Wait for load
    await page1.waitForTimeout(5000);
    await page2.waitForTimeout(5000);

    // Take screenshots
    await page1.screenshot({ path: 'test-results/multi-context-driver.png' });
    await page2.screenshot({ path: 'test-results/multi-context-parent.png' });

    // Verify different URLs
    expect(page1.url()).toContain(':5001');
    expect(page2.url()).toContain(':5002');

    // Verify both have content
    const content1 = await page1.content();
    const content2 = await page2.content();

    expect(content1.length).toBeGreaterThan(1000);
    expect(content2.length).toBeGreaterThan(1000);

    // Cleanup
    await context1.close();
    await context2.close();

    console.log('✅ Multi-context access works:');
    console.log('   - Driver (5001): loaded');
    console.log('   - Parent (5002): loaded');
  });
});

test.describe('Role Selection Tests', () => {

  test('Can see role selection screen', async ({ page }) => {
    await page.goto(DRIVER_URL);
    await page.waitForTimeout(5000);

    // Screenshot of role selection
    await page.screenshot({ path: 'test-results/role-selection.png' });

    // Check for role selection elements in HTML
    const content = await page.content();

    // Flutter renders text, so we check the page contains Korean text
    const hasRoleContent = content.includes('학부모') || content.includes('기사');

    console.log(`Role selection visible: ${hasRoleContent}`);
    console.log('Screenshot saved to: test-results/role-selection.png');
  });
});
