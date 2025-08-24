import express from 'express';

const app = express();
const port = parseInt(process.env.PORT || '3000', 10);

app.get('/', (req, res) => {
  res.send('Hello, Kubernetes!');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running at http://0.0.0.0:${port}`);
});
