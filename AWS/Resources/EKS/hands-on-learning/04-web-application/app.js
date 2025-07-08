const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send({
    message: 'Hello from Kubernetes!',
    hostname: require('os').hostname(),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
    });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: process.uptime()
    });
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
});
