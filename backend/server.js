const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin (you'll need to add your service account key)
// const serviceAccount = require('./firebase-service-account.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
//   databaseURL: "https://your-project-id-default-rtdb.firebaseio.com"
// });

// Import the new fare service
const fareService = require('./services/fareService');

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Find Fare API is running' });
});

// Get fare estimates
app.post('/api/fare-estimate', async (req, res) => {
  try {
    const { pickup, destination, distance, duration } = req.body;

    if (!pickup || !destination || !distance) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Use the new dynamic fare service
    const estimates = await fareService.getAllFareEstimates(
      pickup, 
      destination, 
      distance, 
      duration
    );

    res.json({
      success: true,
      pickup,
      destination,
      estimates,
      lastUpdated: new Date().toISOString(),
      message: 'Dynamic fare estimates fetched successfully'
    });

  } catch (error) {
    console.error('Error calculating fare estimate:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

// Save booking request
app.post('/api/booking', async (req, res) => {
  try {
    const { userId, serviceId, pickup, destination, fare, bookingTime } = req.body;

    // In a real app, you would save this to Firebase
    const bookingData = {
      id: Date.now().toString(),
      userId,
      serviceId,
      pickup,
      destination,
      fare,
      bookingTime,
      status: 'pending',
      createdAt: new Date().toISOString()
    };

    // Mock saving to database
    console.log('Booking saved:', bookingData);

    res.json({
      success: true,
      booking: bookingData,
      message: 'Booking request saved successfully'
    });

  } catch (error) {
    console.error('Error saving booking:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Test endpoint for dynamic fares
app.get('/api/test-fares', async (req, res) => {
  try {
    const testData = {
      pickup: { lat: 12.9716, lng: 77.5946, address: 'Bengaluru' },
      destination: { lat: 12.2958, lng: 76.6394, address: 'Mysuru' },
      distance: 150, // km
      duration: 10800 // seconds (3 hours)
    };

    const estimates = await fareService.getAllFareEstimates(
      testData.pickup,
      testData.destination,
      testData.distance,
      testData.duration
    );

    res.json({
      success: true,
      testData,
      estimates,
      message: 'Test fare estimates generated successfully'
    });
  } catch (error) {
    console.error('Error in test endpoint:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get cache statistics
app.get('/api/cache-stats', (req, res) => {
  try {
    const stats = fareService.getCacheStats();
    res.json({
      success: true,
      cacheStats: stats
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Clear cache
app.post('/api/clear-cache', async (req, res) => {
  try {
    await fareService.refreshAllFares();
    res.json({
      success: true,
      message: 'Cache cleared successfully'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user bookings
app.get('/api/bookings/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    // Mock booking history
    const mockBookings = [
      {
        id: '1',
        serviceId: 'ola',
        serviceName: 'Ola',
        pickup: 'Home',
        destination: 'Office',
        fare: 120,
        status: 'completed',
        bookingTime: '2025-01-25T10:30:00Z'
      },
      {
        id: '2',
        serviceId: 'uber',
        serviceName: 'Uber',
        pickup: 'Mall',
        destination: 'Airport',
        fare: 450,
        status: 'completed',
        bookingTime: '2025-01-24T15:45:00Z'
      }
    ];

    res.json({
      success: true,
      bookings: mockBookings
    });

  } catch (error) {
    console.error('Error fetching bookings:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Find Fare API server running on port ${PORT}`);
});
