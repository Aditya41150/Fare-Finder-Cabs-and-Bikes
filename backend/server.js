const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const GOOGLE_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

// Toggle this to use mock data (true) or real Google API (false)
const USE_MOCK_DATA = true; // Set to true to use mock data without Google API

// Mock location data for testing without Google API
const MOCK_LOCATIONS = [
  { description: 'Bangalore, Karnataka, India', place_id: 'mock_blr_1' },
  { description: 'MG Road, Bangalore, Karnataka, India', place_id: 'mock_blr_mg' },
  { description: 'Koramangala, Bangalore, Karnataka, India', place_id: 'mock_blr_kmg' },
  { description: 'Indiranagar, Bangalore, Karnataka, India', place_id: 'mock_blr_inr' },
  { description: 'Whitefield, Bangalore, Karnataka, India', place_id: 'mock_blr_wtf' },
  { description: 'Electronic City, Bangalore, Karnataka, India', place_id: 'mock_blr_ec' },
  { description: 'Mumbai, Maharashtra, India', place_id: 'mock_mum_1' },
  { description: 'Andheri, Mumbai, Maharashtra, India', place_id: 'mock_mum_and' },
  { description: 'Bandra, Mumbai, Maharashtra, India', place_id: 'mock_mum_ban' },
  { description: 'Delhi, India', place_id: 'mock_del_1' },
  { description: 'Connaught Place, Delhi, India', place_id: 'mock_del_cp' },
  { description: 'Pune, Maharashtra, India', place_id: 'mock_pun_1' },
  { description: 'Hyderabad, Telangana, India', place_id: 'mock_hyd_1' },
  { description: 'Chennai, Tamil Nadu, India', place_id: 'mock_che_1' },
];

// Mock coordinates for place IDs
const MOCK_COORDINATES = {
  'mock_blr_1': { lat: 12.9716, lng: 77.5946 },
  'mock_blr_mg': { lat: 12.9759, lng: 77.6061 },
  'mock_blr_kmg': { lat: 12.9352, lng: 77.6245 },
  'mock_blr_inr': { lat: 12.9784, lng: 77.6408 },
  'mock_blr_wtf': { lat: 12.9698, lng: 77.7500 },
  'mock_blr_ec': { lat: 12.8456, lng: 77.6603 },
  'mock_mum_1': { lat: 19.0760, lng: 72.8777 },
  'mock_mum_and': { lat: 19.1136, lng: 72.8697 },
  'mock_mum_ban': { lat: 19.0596, lng: 72.8295 },
  'mock_del_1': { lat: 28.7041, lng: 77.1025 },
  'mock_del_cp': { lat: 28.6315, lng: 77.2167 },
  'mock_pun_1': { lat: 18.5204, lng: 73.8567 },
  'mock_hyd_1': { lat: 17.3850, lng: 78.4867 },
  'mock_che_1': { lat: 13.0827, lng: 80.2707 },
};

// Middleware
app.use(cors());
app.use(express.json());

// 1. DYNAMIC LOCATION ROUTES
// Route: Get address suggestions as the user types
app.get('/api/places-autocomplete', async (req, res) => {
  try {
    const { input } = req.query;
    if (!input) return res.status(400).json({ error: 'Input is required' });

    if (USE_MOCK_DATA) {
      // Mock mode: Filter locations based on input
      const filtered = MOCK_LOCATIONS.filter(loc =>
        loc.description.toLowerCase().includes(input.toLowerCase())
      );
      return res.json({ success: true, predictions: filtered.slice(0, 5) });
    }

    // Real Google API mode
    const response = await axios.get(
      `https://maps.googleapis.com/maps/api/place/autocomplete/json`,
      {
        params: {
          input: input,
          key: GOOGLE_API_KEY,
          components: 'country:in', // Restrict search to India
          types: 'geocode'          // Only return addresses/cities
        }
      }
    );
    res.json({ success: true, predictions: response.data.predictions });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch suggestions', details: error.message });
  }
});

// Route: Get Lat/Lng for a selected Place ID
app.get('/api/place-details', async (req, res) => {
  try {
    const { placeId } = req.query;
    if (!placeId) return res.status(400).json({ error: 'Place ID is required' });

    if (USE_MOCK_DATA) {
      // Mock mode: Return coordinates from mock data
      const coords = MOCK_COORDINATES[placeId];
      if (coords) {
        const location = MOCK_LOCATIONS.find(loc => loc.place_id === placeId);
        return res.json({
          success: true,
          address: location ? location.description : 'Unknown Location',
          lat: coords.lat,
          lng: coords.lng
        });
      }
      return res.status(404).json({ error: 'Place not found in mock data' });
    }

    // Real Google API mode
    const response = await axios.get(
      `https://maps.googleapis.com/maps/api/place/details/json`,
      {
        params: {
          place_id: placeId,
          fields: 'geometry,formatted_address', // Cost optimization
          key: GOOGLE_API_KEY
        }
      }
    );
    const result = response.data.result;
    res.json({
      success: true,
      address: result.formatted_address,
      lat: result.geometry.location.lat,
      lng: result.geometry.location.lng
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch coordinates' });
  }
});

// 2. FARE ESTIMATION ROUTE
app.post('/api/fare-estimate', async (req, res) => {
  try {
    const { distance, duration } = req.body;
    const distanceNum = Number(distance) || 15.5;
    const durationNum = Number(duration) || 1800;

    // Dynamic Surge Logic
    const hour = new Date().getHours();
    let surge = 1.0;
    if ((hour >= 8 && hour <= 10) || (hour >= 18 && hour <= 21)) {
      surge = 1.5; // 50% increase during peak hours
    }

    const estimates = [
      {
        id: 'uber',
        name: 'UberGo',
        estimatedFare: Math.round((40 + distanceNum * 10) * surge),
        eta: 5,
        surgeMultiplier: surge,
        vehicleType: 'Hatchback',
        distance: distanceNum,
        duration: Math.round(durationNum / 60)
      },
      {
        id: 'uber-premier',
        name: 'Uber Premier',
        estimatedFare: Math.round((60 + distanceNum * 15) * surge),
        eta: 6,
        surgeMultiplier: surge,
        vehicleType: 'Sedan',
        distance: distanceNum,
        duration: Math.round(durationNum / 60)
      },
      {
        id: 'ola',
        name: 'Ola Mini',
        estimatedFare: Math.round((35 + distanceNum * 9) * surge),
        eta: 5,
        surgeMultiplier: surge,
        vehicleType: 'Hatchback',
        distance: distanceNum,
        duration: Math.round(durationNum / 60)
      },
      {
        id: 'ola-prime',
        name: 'Ola Prime',
        estimatedFare: Math.round((55 + distanceNum * 14) * surge),
        eta: 6,
        surgeMultiplier: surge,
        vehicleType: 'Sedan',
        distance: distanceNum,
        duration: Math.round(durationNum / 60)
      },
      {
        id: 'rapido',
        name: 'Rapido Bike',
        estimatedFare: Math.round((15 + distanceNum * 5) * surge),
        eta: 3,
        surgeMultiplier: surge,
        vehicleType: 'Bike',
        distance: distanceNum,
        duration: Math.round(durationNum / 60)
      },
      {
        id: 'rapido-auto',
        name: 'Rapido Auto',
        estimatedFare: Math.round((25 + distanceNum * 7) * surge),
        eta: 4,
        surgeMultiplier: surge,
        vehicleType: 'Auto Rickshaw',
        distance: distanceNum,
        duration: Math.round(durationNum / 60)
      }
    ];

    // Sort by price (lowest first)
    estimates.sort((a, b) => a.estimatedFare - b.estimatedFare);

    res.json({ success: true, estimates, surgeMultiplier: surge });
  } catch (error) {
    res.status(500).json({ error: 'Fare calculation failed', details: error.message });
  }
});

// 3. BOOKING ROUTE
app.post('/api/booking', (req, res) => {
  const booking = { id: Date.now(), ...req.body, status: 'pending' };
  console.log('Booking Saved:', booking);
  res.json({ success: true, booking });
});
// New route for real driving distance
app.get('/api/distance', async (req, res) => {
  try {
    const { origin, destination } = req.query; // Expects "lat,lng" strings

    const response = await axios.get(
      `https://maps.googleapis.com/maps/api/distancematrix/json`,
      {
        params: {
          origins: origin,
          destinations: destination,
          key: process.env.GOOGLE_MAPS_API_KEY
        }
      }
    );

    const data = response.data.rows[0].elements[0];
    res.json({
      distance: data.distance.value / 1000, // Converts meters to km
      duration: data.duration.value / 60     // Converts seconds to minutes
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to calculate road distance' });
  }
});
app.get('/api/health', (req, res) => res.json({ status: 'OK', mode: USE_MOCK_DATA ? 'MOCK' : 'REAL' }));

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Mode: ${USE_MOCK_DATA ? '🎭 MOCK DATA (No Google API needed)' : '🌍 REAL Google Maps API'}`);
  if (USE_MOCK_DATA) {
    console.log('✅ Using mock location data - Perfect for testing!');
    console.log('💡 To use real Google API, set USE_MOCK_DATA = false in server.js');
  }
});