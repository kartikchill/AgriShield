import re

with open(r"D:\PDD2\AgriShield\lib\database\db_helper.dart", "r", encoding="utf-8") as f:
    code = f.read()

# Bump version to 4
code = re.sub(r'static const _databaseVersion = \d+;', 'static const _databaseVersion = 4;', code)

# Change table risk_assessments schema
old_schema = """        growth_stage    TEXT,
        disease         TEXT,
        current_risk    REAL,
        risk_level      TEXT,
        summary         TEXT,
        recommendation  TEXT,
        forecast_json   TEXT,
        factors_json    TEXT,"""
new_schema = """        growth_stage    TEXT,
        diseases_json   TEXT,
        summary         TEXT,
        recommendation  TEXT,
        forecast_json   TEXT,"""
code = code.replace(old_schema, new_schema)

with open(r"D:\PDD2\AgriShield\lib\database\db_helper.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("db_helper.dart patched!")
