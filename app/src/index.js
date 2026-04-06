const express = require('express');
const promClient = require('prom-client');

const app = express();
const port = process.env.PORT || 3000;

// Metrics
const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics();

app.get('/', (req, res) => {
    res.send('Hello DevSecOps World!');
});

app.get('/metrics', async (req, res) => {
    res.set('Content-Type', promClient.register.contentType);
    res.end(await promClient.register.metrics());
});

app.listen(port, () => console.log(`Server running on port ${port}`));

module.exports = app;