import codecs

# 1. Append models
with codecs.open('D:/PDD2/Active Learning Loop/models.py', 'r', 'utf-8') as f:
    al_models = f.read()

# Extract just the classes (skip the first 3 lines of imports which are already in app/models.py mostly, except Float)
al_models_classes = "\nfrom sqlalchemy import Float\n" + "\n".join(al_models.split('\n')[4:])

with codecs.open('D:/PDD2/crop-risk-system/app/models.py', 'a', 'utf-8') as f:
    f.write("\n\n" + al_models_classes)

# 2. Append schemas
with codecs.open('D:/PDD2/Active Learning Loop/schemas.py', 'r', 'utf-8') as f:
    al_schemas = f.read()

# Extract just the classes
al_schemas_classes = "\n" + "\n".join(al_schemas.split('\n')[4:])

with codecs.open('D:/PDD2/crop-risk-system/app/schemas.py', 'a', 'utf-8') as f:
    f.write("\n\n" + al_schemas_classes)

print("Merged models and schemas successfully.")
