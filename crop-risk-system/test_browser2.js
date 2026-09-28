const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({headless: "new"});
    const page = await browser.newPage();
    page.on('response', response => {
        if (!response.ok()) {
            console.log('404 URL:', response.url());
        }
    });
    
    await page.goto('http://127.0.0.1:8000/', {waitUntil: 'networkidle0'});
    await browser.close();
})();
