const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({headless: "new"});
    const page = await browser.newPage();
    page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));
    
    await page.goto('http://127.0.0.1:8000/', {waitUntil: 'networkidle0'});
    
    console.log('Clicking Learning tab...');
    await page.click('#tabLearning');
    const learningVisible = await page.$eval('#sectionLearning', el => !el.classList.contains('hidden'));
    console.log('Learning tab visible:', learningVisible);
    
    console.log('Testing Export Weather API call...');
    await page.click('#btnExportWeather');
    
    // wait for network
    await new Promise(r => setTimeout(r, 2000));
    
    const statusText = await page.$eval('#exportStatus', el => el.innerText);
    console.log('Export Status:', statusText);

    await browser.close();
})();
