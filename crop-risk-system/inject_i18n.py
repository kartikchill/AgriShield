import re
import codecs

translations = {
    "Crop Health & Pest Surveillance System": {"mr": "पीक आरोग्य आणि कीड पाळत ठेवणे प्रणाली", "hi": "फसल स्वास्थ्य और कीट निगरानी प्रणाली"},
    "Unified Dashboard: Disease Risk Forecasting & Pest ETL Rule Engine": {"mr": "एकात्मिक डॅशबोर्ड: रोग धोका अंदाज आणि कीड ETL नियम", "hi": "एकीकृत डैशबोर्ड: रोग जोखिम पूर्वानुमान और कीट ETL नियम"},
    "Language:": {"mr": "भाषा:", "hi": "भाषा:"},
    "Disease Risk (Model A)": {"mr": "रोग धोका (मॉडेल A)", "hi": "रोग जोखिम (मॉडल A)"},
    "Pest Surveillance (ETL)": {"mr": "कीड पाळत ठेवणे (ETL)", "hi": "कीट निगरानी (ETL)"},
    "Expert Referral (Lab Routing)": {"mr": "तज्ञ संदर्भ (लॅब)", "hi": "विशेषज्ञ संदर्भ (लैब)"},
    "Geospatial Hotspots": {"mr": "भौगोलिक हॉटस्पॉट्स", "hi": "भू-स्थानिक हॉटस्पॉट"},
    "Field Parameters": {"mr": "शेत परिमाण", "hi": "खेत पैरामीटर"},
    "Crop Type": {"mr": "पिकाचा प्रकार", "hi": "फसल का प्रकार"},
    "Crop Variety": {"mr": "पिकाची जात", "hi": "फसल की किस्म"},
    "Growth Stage": {"mr": "वाढीचा टप्पा", "hi": "विकास चरण"},
    "Soil Type": {"mr": "मातीचा प्रकार", "hi": "मिट्टी का प्रकार"},
    "Location": {"mr": "स्थान", "hi": "स्थान"},
    "Detect Location": {"mr": "स्थान शोधा", "hi": "स्थान का पता लगाएं"},
    "Analyze Disease Risk": {"mr": "रोग धोक्याचे विश्लेषण करा", "hi": "रोग जोखिम का विश्लेषण करें"},
    "Current Disease Risk": {"mr": "सध्याचा रोग धोका", "hi": "वर्तमान रोग जोखिम"},
    "Executive Summary": {"mr": "कार्यकारी सारांश", "hi": "कार्यकारी सारांश"},
    "Actionable Advisory": {"mr": "कृती करण्यायोग्य सल्ला", "hi": "कार्रवाई योग्य सलाह"},
    "Cultural Control": {"mr": "सांस्कृतिक नियंत्रण", "hi": "सांस्कृतिक नियंत्रण"},
    "Biological Control": {"mr": "जैविक नियंत्रण", "hi": "जैविक नियंत्रण"},
    "Chemical Control": {"mr": "रासायनिक नियंत्रण", "hi": "रासायनिक नियंत्रण"},
    "4-Day Trajectory (Weather features)": {"mr": "४-दिवसीय हवामान अंदाज", "hi": "४-दिवसीय मौसम प्रक्षेपवक्र"},
    "Model Factors (XGBoost Inputs)": {"mr": "मॉडेल घटक (XGBoost)", "hi": "मॉडल कारक (XGBoost)"},
    "Log Sensor/Trap Data": {"mr": "सेन्सर/ट्रॅप डेटा नोंदवा", "hi": "सेंसर/ट्रैप डेटा लॉग करें"},
    "Field ID": {"mr": "शेत आयडी", "hi": "खेत आईडी"},
    "Pest": {"mr": "कीड", "hi": "कीट"},
    "Metric Type (Auto-mapped)": {"mr": "मेट्रिक प्रकार", "hi": "मीट्रिक प्रकार"},
    "Observed Value": {"mr": "निरीक्षण केलेले मूल्य", "hi": "देखा गया मूल्य"},
    "Evaluate ETL Risk": {"mr": "ETL धोक्याचे मूल्यांकन करा", "hi": "ETL जोखिम का मूल्यांकन करें"},
    "View Field History": {"mr": "शेताचा इतिहास पहा", "hi": "खेत का इतिहास देखें"},
    "ICAR ETL Evaluation Result": {"mr": "ICAR ETL मूल्यांकन निकाल", "hi": "ICAR ETL मूल्यांकन परिणाम"},
    "Recommended Action": {"mr": "शिफारस केलेली कृती", "hi": "अनुशंसित कार्रवाई"},
    "Escalate to Lab / Expert": {"mr": "लॅब / तज्ञाकडे पाठवा", "hi": "लैब / विशेषज्ञ को भेजें"},
    "Farmer Name": {"mr": "शेतकऱ्याचे नाव", "hi": "किसान का नाम"},
    "Phone Number": {"mr": "फोन नंबर", "hi": "फ़ोन नंबर"},
    "Crop": {"mr": "पीक", "hi": "फसल"},
    "Symptoms": {"mr": "लक्षणे", "hi": "लक्षण"},
    "Farmer Location": {"mr": "शेतकऱ्याचे स्थान", "hi": "किसान का स्थान"},
    "Submit Referral Ticket": {"mr": "संदर्भ तिकीट सबमिट करा", "hi": "रेफरल टिकट सबमिट करें"},
    "Ticket Created Successfully": {"mr": "तिकीट यशस्वीरित्या तयार केले", "hi": "टिकट सफलतापूर्वक बनाया गया"},
    "Ticket ID": {"mr": "तिकीट आयडी", "hi": "टिकट आईडी"},
    "Routing Info": {"mr": "राउटिंग माहिती", "hi": "रूटिंग जानकारी"},
    "Physical Sample Packaging Guidelines": {"mr": "नमुना पॅकेजिंग मार्गदर्शक तत्त्वे", "hi": "भौतिक नमूना पैकेजिंग दिशानिर्देश"},
    "Live Epidemiological Map (Maharashtra)": {"mr": "थेट रोगराई नकाशा (महाराष्ट्र)", "hi": "लाइव महामारी विज्ञान मानचित्र (महाराष्ट्र)"},
    "District Surveillance Summary": {"mr": "जिल्हा पाळत ठेवणे सारांश", "hi": "जिला निगरानी सारांश"},
    "District": {"mr": "जिल्हा", "hi": "जिला"},
    "Active Outbreaks": {"mr": "सक्रिय प्रादुर्भाव", "hi": "सक्रिय प्रकोप"},
    "Dominant Threat": {"mr": "प्रमुख धोका", "hi": "प्रमुख खतरा"},
    "Alert Status": {"mr": "अलर्ट स्थिती", "hi": "अलर्ट स्थिति"}
}

def inject_i18n():
    html_path = 'd:/PDD2/crop-risk-system/static/index.html'
    with codecs.open(html_path, 'r', 'utf-8') as f:
        content = f.read()

    # Add data-i18n attributes to HTML tags that exactly contain these strings
    for eng_text in translations.keys():
        # Match tag containing exactly the text (ignoring leading/trailing whitespace but preserving it)
        # We need to capture the tag opening to inject data-i18n
        pattern = r'(<[^>]+?)>(\s*)(' + re.escape(eng_text) + r')(\s*</)'
        replacement = r'\1 data-i18n="\3">\2\3\4'
        content = re.sub(pattern, replacement, content)
        
        # Also handle cases without a closing tag right away, e.g. <label>Crop Type</label> (handled by above)
        # What about <button>Disease Risk (Model A)</button> (handled by above)
        
        # Another pattern for inputs with value="..." 
        # But our dict doesn't map inputs except maybe submit buttons? 
        # Actually our submit buttons use <button>Analyze Disease Risk</button>.
        pass
        
    import json
    js_dict = json.dumps(translations, ensure_ascii=False)
    
    # Inject the JS logic right before </script>\n</body>
    js_logic = f"""
        const uiTranslations = {js_dict};
        
        function updateUILanguage(lang) {{
            document.querySelectorAll('[data-i18n]').forEach(el => {{
                const key = el.getAttribute('data-i18n');
                if (lang === 'en') {{
                    el.innerText = key;
                }} else if (uiTranslations[key] && uiTranslations[key][lang]) {{
                    el.innerText = uiTranslations[key][lang];
                }}
            }});
        }}
        
        document.getElementById('langSelector').addEventListener('change', (e) => {{
            updateUILanguage(e.target.value);
        }});
        
        // Initial setup
        updateUILanguage(document.getElementById('langSelector').value);
    """
    
    content = content.replace("</script>\n</body>", js_logic + "\n    </script>\n</body>")
    
    with codecs.open(html_path, 'w', 'utf-8') as f:
        f.write(content)
        
    print("Injected i18n successfully.")

if __name__ == '__main__':
    inject_i18n()
