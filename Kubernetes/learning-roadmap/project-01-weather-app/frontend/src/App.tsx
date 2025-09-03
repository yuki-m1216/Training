import { useState, useEffect } from "react";
import "./App.css";

interface WeatherData {
  location: string;
  temperature: number;
  description: string;
  humidity: number;
  windSpeed: number;
}

function App() {
  const [weather, setWeather] = useState<WeatherData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const API_URL = import.meta.env.VITE_API_URL || "http://localhost:3001";
  useEffect(() => {
    fetchWeather();
  }, []);

  const fetchWeather = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_URL}/api/weather`);
      if (!response.ok) throw new Error("failed to fetch weather data");
      const data = await response.json();
      setWeather(data);
    } catch (error) {
      setError(error instanceof Error ? error.message : "An error occurred");
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <div className="loading">Loading weather data...</div>;
  if (error) return <div className="error">Error: {error}</div>;
  if (!weather) return <div>No weather data available</div>;

  return (
    <div className="App">
      <h1>Weather App</h1>
      <div className="weather-card">
        <h2>{weather.location}</h2>
        <p className="temperature">{weather.temperature}°C</p>
        <p className="description">{weather.description}</p>
        <div className="details">
          <p>Humidity: {weather.humidity}%</p>
          <p>Wind Speed: {weather.windSpeed} km/h</p>
        </div>
        <button onClick={fetchWeather}>Refresh</button>
      </div>
    </div>
  );
}

export default App;
