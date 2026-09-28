import requests
import pandas as pd
import numpy as np

# 1. Configuration: Jalandhar, Punjab (Major Potato Belt)
LATITUDE = 31.3260
LONGITUDE = 75.5762
START_DATE = "2019-01-01"
END_DATE = "2024-01-01"

print("Fetching 5 years of historical weather data from Open-Meteo...")

url = "https://archive-api.open-meteo.com/v1/archive"
params = {
    "latitude": LATITUDE,
    "longitude": LONGITUDE,
    "start_date": START_DATE,
    "end_date": END_DATE,
    "hourly": "temperature_2m,relative_humidity_2m,precipitation",
    "timezone": "Asia/Kolkata"
}

response = requests.get(url, params=params)
data = response.json()

df_hourly = pd.DataFrame({
    "date": pd.to_datetime(data["hourly"]["time"]),
    "temp": data["hourly"]["temperature_2m"],
    "humidity": data["hourly"]["relative_humidity_2m"],
    "rain": data["hourly"]["precipitation"]
})

df_hourly["day"] = df_hourly["date"].dt.date

# 2. Refined Epidemiological Logic (Adapted for Indian Agro-Climatic Data)
def calculate_daily_sv(group):
    # Count hours of high humidity (>= 85% RH)
    high_rh_hours = (group['humidity'] >= 85.0).sum()
    avg_temp = group['temp'].mean()
    
    # Pathogen germination sweet spot: 12C to 24C with sustained humidity
    if 12.0 <= avg_temp <= 24.0:
        if high_rh_hours >= 12:
            return 4
        elif high_rh_hours >= 9:
            return 3
        elif high_rh_hours >= 6:
            return 2
        elif high_rh_hours >= 4:
            return 1
    elif (8.0 <= avg_temp < 12.0) or (24.0 < avg_temp <= 27.0):
        if high_rh_hours >= 10:
            return 2
        elif high_rh_hours >= 6:
            return 1
            
    return 0

print("Extracting features and generating realistic outbreak labels...")

daily_data = []
for day, group in df_hourly.groupby("day"):
    high_rh_hours = (group["humidity"] >= 85.0).sum()
    sv = calculate_daily_sv(group)
    
    daily_data.append({
        "date": day,
        "avg_temp": round(group["temp"].mean(), 2),
        "min_temp": round(group["temp"].min(), 2),
        "max_temp": round(group["temp"].max(), 2),
        "avg_humidity": round(group["humidity"].mean(), 2),
        "hours_rh_above_90": high_rh_hours,
        "total_rain": round(group["rain"].sum(), 2),
        "daily_severity_value": sv
    })

df_daily = pd.DataFrame(daily_data)

# Rolling features
df_daily["rolling_3d_rain"] = df_daily["total_rain"].rolling(window=3, min_periods=1).sum().round(2)
df_daily["rolling_3d_humidity"] = df_daily["avg_humidity"].rolling(window=3, min_periods=1).mean().round(2)

# 7-day rolling severity accumulation
df_daily["rolling_7d_sv"] = df_daily["daily_severity_value"].rolling(window=7, min_periods=1).sum()

# Trigger an Outbreak Risk (1) if accumulated severity >= 10 in 7 days
df_daily["disease_outbreak"] = np.where(df_daily["rolling_7d_sv"] >= 10, 1, 0)

# Shift to predict 2 days ahead
df_daily["disease_outbreak"] = df_daily["disease_outbreak"].shift(-2).fillna(0).astype(int)

# Clean and Save
df_final = df_daily.drop(columns=["daily_severity_value", "rolling_7d_sv"])
df_final.to_csv("crop_disease_dataset.csv", index=False)

print(f"Success! Saved to 'crop_disease_dataset.csv'")
print(f"Total Days: {len(df_final)}")
print(f"Total Outbreak Days (Class 1): {df_final['disease_outbreak'].sum()} ({(df_final['disease_outbreak'].sum() / len(df_final) * 100):.1f}%)")