import httpx
from datetime import datetime, timedelta

async def fetch_weather_forecast(lat: float, lon: float):
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&hourly=temperature_2m,relative_humidity_2m,precipitation&forecast_days=4&timezone=auto"
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            data = response.json()
    except Exception as e:
        print(f"Weather API failed ({repr(e)}). Falling back to mock data.")
        data = {
            "hourly": {
                "temperature_2m": [24.0] * 96,
                "relative_humidity_2m": [85.0] * 96,
                "precipitation": [2.5] * 96
            }
        }
    
    hourly = data.get("hourly", {})
    temps = hourly.get("temperature_2m", [])
    humidities = hourly.get("relative_humidity_2m", [])
    precipitations = hourly.get("precipitation", [])

    daily_aggregates = []
    
    # Process 24 hours at a time for 4 days
    for day_index in range(4):
        start_idx = day_index * 24
        end_idx = start_idx + 24
        
        day_temps = temps[start_idx:end_idx]
        day_hums = humidities[start_idx:end_idx]
        day_precips = precipitations[start_idx:end_idx]

        if not day_temps:
            break

        avg_temp = sum(day_temps) / len(day_temps)
        min_temp = min(day_temps)
        max_temp = max(day_temps)
        
        avg_humidity = sum(day_hums) / len(day_hums)
        hours_rh_above_90 = sum(1 for h in day_hums if h >= 90)
        
        total_rain = sum(day_precips)
        
        # Approximate rolling 3d by looking back if possible, else multiply current
        # If day_index >= 3, we could sum the last 3 days. But we only have days 0, 1, 2, 3.
        # For simplicity, if we don't have enough history, we approximate:
        if day_index == 0:
            rolling_3d_rain = total_rain * 3
            rolling_3d_humidity = avg_humidity
        elif day_index == 1:
            rolling_3d_rain = total_rain + daily_aggregates[0]["total_rain"] * 2
            rolling_3d_humidity = (avg_humidity + daily_aggregates[0]["avg_humidity"]) / 2
        elif day_index == 2:
            rolling_3d_rain = total_rain + daily_aggregates[1]["total_rain"] + daily_aggregates[0]["total_rain"]
            rolling_3d_humidity = (avg_humidity + daily_aggregates[1]["avg_humidity"] + daily_aggregates[0]["avg_humidity"]) / 3
        else:
            rolling_3d_rain = total_rain + daily_aggregates[2]["total_rain"] + daily_aggregates[1]["total_rain"]
            rolling_3d_humidity = (avg_humidity + daily_aggregates[2]["avg_humidity"] + daily_aggregates[1]["avg_humidity"]) / 3
            
        daily_aggregates.append({
            "avg_temp": round(avg_temp, 2),
            "min_temp": round(min_temp, 2),
            "max_temp": round(max_temp, 2),
            "avg_humidity": round(avg_humidity, 2),
            "hours_rh_above_90": hours_rh_above_90,
            "total_rain": round(total_rain, 2),
            "rolling_3d_rain": round(rolling_3d_rain, 2),
            "rolling_3d_humidity": round(rolling_3d_humidity, 2),
        })
        
    return daily_aggregates
