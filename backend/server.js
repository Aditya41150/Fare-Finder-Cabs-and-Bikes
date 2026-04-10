const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
// Accept either env var name to reduce misconfiguration:
// - backend expects GOOGLE_MAPS_API_KEY
// - Flutter app commonly uses GOOGLE_PLACES_API_KEY
const GOOGLE_API_KEY = process.env.GOOGLE_MAPS_API_KEY || process.env.GOOGLE_PLACES_API_KEY;

// Set USE_MOCK_DATA=true in env to force mock mode.
const USE_MOCK_DATA = String(process.env.USE_MOCK_DATA || '').toLowerCase() === 'true';
const HAS_GOOGLE_API_KEY = Boolean(GOOGLE_API_KEY && GOOGLE_API_KEY.trim());

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

function getMockPredictions(input) {
  const query = String(input || '').toLowerCase();
  return MOCK_LOCATIONS.filter((location) =>
    location.description.toLowerCase().includes(query),
  ).slice(0, 5);
}

// Middleware — allow Flutter Web (localhost on any port) + Render-hosted frontend
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, curl, Postman)
    if (!origin) return callback(null, true);
    // Allow any localhost origin (Flutter web dev server uses a random port)
    if (origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      return callback(null, true);
    }
    // Allow your Render-hosted frontend if you have one
    if (origin.includes('onrender.com')) {
      return callback(null, true);
    }
    callback(new Error(`CORS blocked: ${origin}`));
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));
app.use(express.json());

// 1. DYNAMIC LOCATION ROUTES
// Route: Get address suggestions as the user types
app.get('/api/places-autocomplete', async (req, res) => {
  try {
    const { input } = req.query;
    if (!input) return res.status(400).json({ error: 'Input is required' });

    if (USE_MOCK_DATA || !HAS_GOOGLE_API_KEY) {
      // Mock mode: Filter locations based on input
      const filtered = getMockPredictions(input);
      return res.json({ success: true, predictions: filtered, source: 'mock' });
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

    const googleStatus = response.data.status;
    const predictions = response.data.predictions || [];

    if (googleStatus === 'OK' || googleStatus === 'ZERO_RESULTS') {
      return res.json({ success: true, predictions, source: 'google' });
    }

    const fallbackPredictions = getMockPredictions(input);
    return res.json({
      success: true,
      predictions: fallbackPredictions,
      source: 'mock-fallback',
      warning: `Google Places status: ${googleStatus}`,
    });
  } catch (error) {
    const fallbackPredictions = getMockPredictions(req.query.input);
    res.status(200).json({
      success: true,
      predictions: fallbackPredictions,
      source: 'mock-fallback',
      error: 'Failed to fetch suggestions from Google API',
      details: error.message,
    });
  }
});

// Route: Get Lat/Lng for a selected Place ID
app.get('/api/place-details', async (req, res) => {
  try {
    const { placeId } = req.query;
    if (!placeId) return res.status(400).json({ error: 'Place ID is required' });

    if (USE_MOCK_DATA || !HAS_GOOGLE_API_KEY || String(placeId).startsWith('mock_')) {
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

    if (response.data.status !== 'OK') {
      return res.status(502).json({
        error: 'Google place details request failed',
        status: response.data.status,
      });
    }

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
    const distanceKm  = Number(distance) || 15.5;
    const durationMin = Number(duration) / 60 || 30; // convert seconds → minutes

    // ── Real 2024/25 Indian surge logic ──────────────────────────────────────
    // Surge is per-provider and time-of-day based (lighter than the old 1.5x flat).
    const hour = new Date().getHours();
    const isPeak = (hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 20);
    const isNight = hour >= 23 || hour <= 5;

    // helper: clamp to nearest ₹5
    const round5 = (n) => Math.round(n / 5) * 5;

    // ── Fare formula: base + (perKm × km) + (perMin × min), then surge + GST ─
    // All rates sourced from Bangalore (metro city) 2024/25 tariff cards.
    const services = [
      {
        id: 'uber-go',
        name: 'UberGo',
        provider: 'Uber',
        vehicleType: 'Hatchback',
        eta: 4 + Math.floor(Math.random() * 3),
        capacity: 4,
        baseFare: 30,
        perKm: 11,    // ₹11/km
        perMin: 1.25, // ₹1.25/min
        surge: isPeak ? 1.2 : isNight ? 1.15 : 1.0,
      },
      {
        id: 'uber-premier',
        name: 'Uber Premier',
        provider: 'Uber',
        vehicleType: 'Sedan',
        eta: 5 + Math.floor(Math.random() * 4),
        capacity: 4,
        baseFare: 50,
        perKm: 14,
        perMin: 1.5,
        surge: isPeak ? 1.2 : isNight ? 1.15 : 1.0,
      },
      {
        id: 'ola-mini',
        name: 'Ola Mini',
        provider: 'Ola',
        vehicleType: 'Hatchback',
        eta: 4 + Math.floor(Math.random() * 3),
        capacity: 4,
        baseFare: 28,
        perKm: 10,
        perMin: 1.0,
        surge: isPeak ? 1.25 : isNight ? 1.1 : 1.0,
      },
      {
        id: 'ola-prime-sedan',
        name: 'Ola Prime Sedan',
        provider: 'Ola',
        vehicleType: 'Sedan',
        eta: 6 + Math.floor(Math.random() * 4),
        capacity: 4,
        baseFare: 45,
        perKm: 13,
        perMin: 1.25,
        surge: isPeak ? 1.25 : isNight ? 1.1 : 1.0,
      },
      {
        id: 'rapido-bike',
        name: 'Rapido Bike',
        provider: 'Rapido',
        vehicleType: 'Bike',
        eta: 2 + Math.floor(Math.random() * 3),
        capacity: 1,
        baseFare: 20,
        perKm: 6,
        perMin: 0.75, // Rapido bills heavy on per-minute basis
        surge: isPeak ? 1.1 : 1.0,
      },
      {
        id: 'rapido-auto',
        name: 'Rapido Auto',
        provider: 'Rapido',
        vehicleType: 'Auto Rickshaw',
        eta: 3 + Math.floor(Math.random() * 3),
        capacity: 3,
        baseFare: 30,
        perKm: 8,
        perMin: 1.0,
        surge: isPeak ? 1.1 : 1.0,
      },
      {
        id: 'namma-yatri-auto',
        name: 'Namma Yatri Auto',
        provider: 'Namma Yatri',
        vehicleType: 'Auto Rickshaw',
        eta: 4 + Math.floor(Math.random() * 4),
        capacity: 3,
        // Namma Yatri: govt-regulated meter rates, no surge, no commission
        baseFare: 30,
        perKm: 7,
        perMin: 0.0,
        surge: 1.0, // never surges
      },
      {
        id: 'indrive-cab',
        name: 'inDrive',
        provider: 'inDrive',
        vehicleType: 'Sedan',
        eta: 7 + Math.floor(Math.random() * 5),
        capacity: 4,
        // inDrive lets drivers bid, estimate a slightly lower price
        baseFare: 40,
        perKm: 10,
        perMin: 1.0,
        surge: 1.0, // no surge — driver negotiated
      },
    ];

    const GST = 1.04; // 5% GST rounded to flat 4% net (Uber/Ola absorb part)

    const estimates = services.map((s) => {
      const raw = (s.baseFare + s.perKm * distanceKm + s.perMin * durationMin) * s.surge * GST;
      const fareMin = round5(raw * 0.92); // ±8% variance band
      const fareMax = round5(raw * 1.08);
      const estimatedFare = round5(raw);

      return {
        id: s.id,
        name: s.name,
        provider: s.provider,
        vehicleType: s.vehicleType,
        eta: s.eta,
        capacity: s.capacity,
        estimatedFare,
        fareMin,
        fareMax,
        surgeMultiplier: s.surge,
        distance: distanceKm,
        duration: Math.round(durationMin),
      };
    });

    // Sort by estimatedFare ascending
    estimates.sort((a, b) => a.estimatedFare - b.estimatedFare);

    res.json({ success: true, estimates, surgeMultiplier: isPeak ? 1.2 : 1.0 });
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
  console.log(`Google API key configured: ${HAS_GOOGLE_API_KEY ? 'YES' : 'NO'}`);
  if (USE_MOCK_DATA || !HAS_GOOGLE_API_KEY) {
    console.log('✅ Using mock location data - Perfect for testing!');
    console.log('💡 To use real Google API, set GOOGLE_MAPS_API_KEY and USE_MOCK_DATA=false');
  }
});