import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    precision_recall_curve,
    auc,
    roc_auc_score
)
import joblib

# 1. Load the Dataset
print("Loading dataset...")
df = pd.read_csv("crop_disease_dataset.csv")

# 2. Sort chronologically to prevent time-travel data leakage
if "date" in df.columns:
    df["date"] = pd.to_datetime(df["date"])
    df = df.sort_values("date").reset_index(drop=True)

# 3. Define Features (X) and Target (y)
feature_cols = [
    "avg_temp",
    "min_temp",
    "max_temp",
    "avg_humidity",
    "hours_rh_above_90",
    "total_rain",
    "rolling_3d_rain",
    "rolling_3d_humidity"
]

X = df[feature_cols]
y = df["disease_outbreak"]

# 4. Chronological Train-Test Split (80% Train, 20% Test)
split_idx = int(len(df) * 0.80)
X_train, X_test = X.iloc[:split_idx], X.iloc[split_idx:]
y_train, y_test = y.iloc[:split_idx], y.iloc[split_idx:]

print(f"Training samples: {len(X_train)} | Test samples: {len(X_test)}")

# 5. Handle Class Imbalance
# Calculate the ratio of Safe days (0) to Outbreak days (1)
neg_count = (y_train == 0).sum()
pos_count = (y_train == 1).sum()
scale_weight = neg_count / max(pos_count, 1)

print(f"Class distribution in train set -> Safe (0): {neg_count}, Outbreak (1): {pos_count}")
print(f"Applying scale_pos_weight: {scale_weight:.2f}")

# 6. Initialize & Train XGBoost
model = xgb.XGBClassifier(
    n_estimators=120,
    learning_rate=0.04,
    max_depth=4,
    subsample=0.8,
    colsample_bytree=0.8,
    scale_pos_weight=scale_weight,
    eval_metric="logloss",
    random_state=42
)

print("Training model...")
model.fit(
    X_train,
    y_train,
    eval_set=[(X_train, y_train), (X_test, y_test)],
    verbose=False
)

# 7. Evaluate Model Performance
y_pred = model.predict(X_test)
y_prob = model.predict_proba(X_test)[:, 1]

print("\n================ CLASSIFICATION REPORT ================")
print(classification_report(y_test, y_pred, target_names=["Safe (0)", "Outbreak (1)"]))

print("================ CONFUSION MATRIX ================")
print(confusion_matrix(y_test, y_pred))

# PR-AUC Calculation (Crucial for rare outbreaks)
precision, recall, _ = precision_recall_curve(y_test, y_prob)
pr_auc = auc(recall, precision)
roc_auc = roc_auc_score(y_test, y_prob)

print(f"\nPR-AUC Score:  {pr_auc:.3f}")
print(f"ROC-AUC Score: {roc_auc:.3f}")

# 8. Inspect Feature Importance
feature_importance = pd.DataFrame({
    "Feature": X.columns,
    "Importance": model.feature_importances_
}).sort_values(by="Importance", ascending=False)

print("\n================ FEATURE IMPORTANCE ================")
print(feature_importance.to_string(index=False))

# 9. Export the Model Artifacts for FastAPI
model_filename = "model_a_risk_predictor.json"
model.save_model(model_filename)

# Save feature list to ensure FastAPI sends variables in the exact same order
joblib.dump(list(X.columns), "model_a_features.pkl")

print(f"\nModel successfully saved to '{model_filename}'")
print("Feature schema saved to 'model_a_features.pkl'")