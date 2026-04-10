const axios = require('axios');
const path = require('path');
const { spawn } = require('child_process');

const PORT = Number(process.env.PORT || 3000);
const BASE_URL = `http://127.0.0.1:${PORT}/api`;
const SERVER_PATH = path.join(__dirname, 'server.js');

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitForHealth(maxAttempts = 30) {
  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      await axios.get(`${BASE_URL}/health`, { timeout: 1500 });
      return;
    } catch (_) {
      await wait(400);
    }
  }
  throw new Error('Server did not become healthy in time.');
}

function startServer() {
  const serverProcess = spawn(process.execPath, [SERVER_PATH], {
    cwd: __dirname,
    stdio: 'inherit',
    env: {
      ...process.env,
      PORT: String(PORT),
      USE_MOCK_DATA: process.env.USE_MOCK_DATA || 'true',
    },
  });

  return serverProcess;
}

async function runTests() {
  console.log('Testing Dynamic Fare API...\n');

  console.log('1. Testing Health Endpoint...');
  const healthResponse = await axios.get(`${BASE_URL}/health`);
  console.log('Health Check:', healthResponse.data);
  console.log('');

  console.log('2. Testing Fare Estimate Endpoint...');
  const fareRequest = {
    pickup: { lat: 12.9716, lng: 77.5946, address: 'Bengaluru' },
    destination: { lat: 12.2958, lng: 76.6394, address: 'Mysuru' },
    distance: 150,
    duration: 10800,
  };

  const fareResponse = await axios.post(`${BASE_URL}/fare-estimate`, fareRequest);
  if (!fareResponse.data.success || !Array.isArray(fareResponse.data.estimates)) {
    throw new Error('Fare estimate response missing expected data.');
  }

  console.log('Fare response contains estimates:', fareResponse.data.estimates.length);
  console.log('Cheapest estimate:', fareResponse.data.estimates[0]);
  console.log('');

  console.log('3. Testing Places Autocomplete Endpoint...');
  const placesResponse = await axios.get(`${BASE_URL}/places-autocomplete`, {
    params: { input: 'Bangalore' },
  });

  if (!Array.isArray(placesResponse.data.predictions)) {
    throw new Error('Places autocomplete response missing predictions.');
  }

  console.log('Predictions returned:', placesResponse.data.predictions.length);
  console.log('');

  console.log('All API checks passed.');
}

async function testAPI() {
  const serverProcess = startServer();

  try {
    await waitForHealth();
    await runTests();
  } finally {
    if (!serverProcess.killed) {
      serverProcess.kill('SIGTERM');
    }
  }
}

testAPI().catch((error) => {
  console.error('Test failed:');
  if (error.response) {
    console.error('Status:', error.response.status);
    console.error('Data:', error.response.data);
  } else {
    console.error(error.message);
  }
  process.exit(1);
});
