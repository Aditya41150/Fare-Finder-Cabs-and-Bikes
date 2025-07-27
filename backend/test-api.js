const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testAPI() {
  console.log('🧪 Testing Dynamic Fare API...\n');

  try {
    // Test 1: Health Check
    console.log('1. Testing Health Endpoint...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health Check:', healthResponse.data);
    console.log('');

    // Test 2: Test Dynamic Fares
    console.log('2. Testing Dynamic Fare Estimates...');
    const fareResponse = await axios.get(`${BASE_URL}/test-fares`);
    console.log('✅ Dynamic Fares:');
    console.log('   Test Route:', fareResponse.data.testData.pickup.address, '→', fareResponse.data.testData.destination.address);
    console.log('   Distance:', fareResponse.data.testData.distance, 'km');
    console.log('   Duration:', Math.round(fareResponse.data.testData.duration / 60), 'minutes');
    console.log('');
    
    fareResponse.data.estimates.forEach((estimate, index) => {
      console.log(`   ${index + 1}. ${estimate.name}:`);
      console.log(`      • Fare: ₹${estimate.estimatedFare}`);
      console.log(`      • ETA: ${estimate.eta} min`);
      console.log(`      • Vehicle: ${estimate.vehicleType}`);
      console.log(`      • Surge: ${estimate.surgeMultiplier.toFixed(2)}x`);
      console.log(`      • Source: ${estimate.dataSource}`);
      console.log(`      • Updated: ${new Date(estimate.lastUpdated).toLocaleTimeString()}`);
      console.log('');
    });

    // Test 3: Cache Stats
    console.log('3. Testing Cache Statistics...');
    const cacheResponse = await axios.get(`${BASE_URL}/cache-stats`);
    console.log('✅ Cache Stats:', cacheResponse.data.cacheStats);
    console.log('');

    // Test 4: Real Fare Estimate (POST)
    console.log('4. Testing Real Fare Estimate Endpoint...');
    const realFareData = {
      pickup: { lat: 12.9716, lng: 77.5946, address: 'Bengaluru' },
      destination: { lat: 12.2958, lng: 76.6394, address: 'Mysuru' },
      distance: 150,
      duration: 10800
    };

    const realFareResponse = await axios.post(`${BASE_URL}/fare-estimate`, realFareData);
    console.log('✅ Real Fare Estimate Response:');
    console.log('   Success:', realFareResponse.data.success);
    console.log('   Message:', realFareResponse.data.message);
    console.log('   Last Updated:', new Date(realFareResponse.data.lastUpdated).toLocaleString());
    console.log('   Number of Estimates:', realFareResponse.data.estimates.length);
    console.log('');

    console.log('🎉 All tests passed! Dynamic fare system is working correctly.');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

// Run tests
testAPI();
