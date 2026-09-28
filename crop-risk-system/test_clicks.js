const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({headless: "new"});
    const page = await browser.newPage();
    page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));
    page.on('pageerror', err => console.log('BROWSER ERROR:', err.toString()));
    
    await page.goto('http://127.0.0.1:8000/', {waitUntil: 'networkidle0'});
    
    // Test clicking tabs
    console.log('Clicking Pest tab...');
    await page.click('#tabPest');
    const pestVisible = await page.$eval('#sectionPest', el => !el.classList.contains('hidden'));
    console.log('Pest tab visible:', pestVisible);
    
    console.log('Clicking Vision tab...');
    await page.click('#tabVision');
    const visionVisible = await page.$eval('#sectionVision', el => !el.classList.contains('hidden'));
    console.log('Vision tab visible:', visionVisible);

    await browser.close();
})();
