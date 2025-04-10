const express = require('express');
const app = express();
const port = 8000;

// Serve static files
app.use(express.static('public'));

// Add a simple API endpoint
app.get('/api/status', (req, res) => {
  res.json({ status: 'running' });
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`JS-OS server running at http://0.0.0.0:${port}`);
});
