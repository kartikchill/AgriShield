import json
import os

class AdvisoryTranslator:
    def __init__(self):
        self.dicts = {}
        base_dir = os.path.dirname(__file__)
        for lang in ['en', 'mr', 'hi']:
            path = os.path.join(base_dir, f'dict_{lang}.json')
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    self.dicts[lang] = json.load(f)
            except FileNotFoundError:
                self.dicts[lang] = {}

    def get_text(self, key: str, lang: str, **kwargs) -> str:
        dictionary = self.dicts.get(lang, self.dicts.get('en', {}))
        text = dictionary.get(key)
        
        # Fallback to English if key missing
        if not text and lang != 'en':
            text = self.dicts.get('en', {}).get(key, key)
        elif not text:
            return key
            
        if kwargs:
            try:
                text = text.format(**kwargs)
            except KeyError:
                pass
        return text

    def _map_to_key(self, text: str) -> str:
        """Map common English values to their dictionary keys."""
        if not text:
            return None
        text_lower = text.lower()
        if "safe" in text_lower:
            return "risk_status_safe"
        if "monitor" in text_lower:
            return "risk_status_monitor"
        if "critical" in text_lower or "etl_breach" in text_lower or "high" in text_lower:
            return "risk_status_critical"
        if "cotton" in text_lower:
            return "crop_cotton"
        if "tomato" in text_lower:
            return "crop_tomato"
        if "pink bollworm" in text_lower:
            return "pest_pink_bollworm"
        if "late blight" in text_lower:
            return "pest_late_blight"
        return None

    def translate_payload(self, payload: dict, lang: str) -> dict:
        if lang == 'en':
            return payload
            
        translated = payload.copy()

        # Translate status / risk_level
        if "status" in translated:
            key = self._map_to_key(translated["status"])
            if key:
                translated["status"] = self.get_text(key, lang)
        
        if "risk_level" in translated:
            key = self._map_to_key(translated["risk_level"])
            if key:
                translated["risk_level"] = self.get_text(key, lang)
                
        # Translate crop name and pest name if present
        for field in ["crop_name", "crop", "pest_name", "disease"]:
            if field in translated and translated[field]:
                key = self._map_to_key(translated[field])
                if key:
                    translated[field] = self.get_text(key, lang)

        # Translate IPM Advisory blocks
        if "ipm_advisory" in translated and translated["ipm_advisory"]:
            ipm = translated["ipm_advisory"]
            if isinstance(ipm, dict):
                # We could translate cultural/biological completely, but that requires full ML translation.
                # Here we just inject the PPE warning and PHI warning if applicable.
                
                # If PPE is required, we can prepend/append the translated warning
                if ipm.get("required_ppe"):
                    ppe_warn = self.get_text("ppe_warning", lang)
                    ipm["required_ppe"] = f"{ppe_warn} ({ipm['required_ppe']})"
                    
                if ipm.get("phi_days"):
                    phi_warn = self.get_text("phi_warning", lang, days=ipm["phi_days"])
                    # Store it dynamically or overwrite phi_days string
                    ipm["phi_warning_text"] = phi_warn
                    
            translated["ipm_advisory"] = ipm

        return translated

translator = AdvisoryTranslator()
