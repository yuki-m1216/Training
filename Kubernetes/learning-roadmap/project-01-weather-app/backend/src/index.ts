import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => {
  res.json({ status: "healthy", timestamp: new Date().toISOString() });
});

app.get("/api/weather", async (req, res) => {
  // TODO: OpenWeatherMap APIとの連携を実装
  res.json({
    location: "Tokyo",
    temperature: 20,
    description: "Sunny",
    humidity: 60,
    windSpeed: 5,
  });
});

app.listen(PORT, () => {
  console.log(`Backend server is running on port ${PORT}`);
});
