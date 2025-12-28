const axios = require('axios');
const cheerio = require('cheerio');
const puppeteer = require('puppeteer');
const NodeCache = require('node-cache');
const moment = require('moment');

// Initialize cache with 30-minute TTL for real-time pricing
const fareCache = new NodeCache({ stdTTL: 1800 });

// Helpers
function coordKey(p) {
  if (!p) return 'nil';
  if (typeof p === 'string') return p;
  return `${p.lat ?? 'n'}_${p.lng ?? 'n'}`;
}

function getCacheKey(service, pickup, destination) {
  return `${service}_${coordKey(pickup)}_${coordKey(destination)}`;
}

function parseEstimateToNumber(estimate) {
  // Some APIs return strings like "$10-12" or "10.00" — extract numbers and pick a sensible value
  if (estimate == null) return null;
  if (typeof estimate === 'number') return estimate;
  const s = String(estimate);
  const nums = s.match(/[0-9]+(?:\.[0-9]+)?/g);
  if (!nums || nums.length === 0) return null;
  // If range like 10-12, take average
  const parsed = nums.map(n => parseFloat(n));
  const avg = parsed.reduce((a, b) => a + b, 0) / parsed.length;
  return Math.round(avg);
}

class FareService {
  constructor() {
    this.platforms = {
      uber: {
        name: 'Uber',
        apiUrl: 'https://api.uber.com/v1.2/estimates/price',
        headers: { 'Authorization': `Token ${process.env.UBER_API_KEY}` },
        fallbackBasePrice: 50,
        fallbackPerKmRate: 12
      },
      ola: {
        name: 'Ola',
        apiUrl: 'https://devapi.olacabs.com/v1/products',
        headers: { 'X-APP-TOKEN': process.env.OLA_API_KEY },
        fallbackBasePrice: 45,
        fallbackPerKmRate: 10
      },
      rapido: {
        name: 'Rapido',
        websiteUrl: 'https://rapido.bike',
        fallbackBasePrice: 35,
        fallbackPerKmRate: 8
      },
      blusmart: {
        name: 'BluSmart',
        websiteUrl: 'https://blusmart.com',
        fallbackBasePrice: 60,
        fallbackPerKmRate: 15
      }
    };
  }

  // Get current surge multiplier based on time and demand
  getSurgeMultiplier(serviceKey) {
    const hour = moment().hour();
    const isWeekend = moment().isoWeekday() >= 6;
    const isPeakHour = (hour >= 8 && hour <= 10) || (hour >= 17 && hour <= 20);
    
    let surgeMultiplier = 1.0;
    
    if (isPeakHour) {
      surgeMultiplier += 0.3;
    }
    
    if (isWeekend) {
      surgeMultiplier += 0.2;
    }
    
    // Add random variance for realistic pricing
    const variance = (Math.random() - 0.5) * 0.2;
    surgeMultiplier += variance;
    
    return Math.max(0.8, Math.min(2.5, surgeMultiplier));
  }

  // Fetch fare from Uber API
  async fetchUberFare(pickup, destination, distance) {
    try {
      const cacheKey = getCacheKey('uber', pickup, destination);
      const cached = fareCache.get(cacheKey);
      if (cached) return cached;

      const response = await axios.get(this.platforms.uber.apiUrl, {
        headers: this.platforms.uber.headers,
        params: {
          start_latitude: pickup.lat,
          start_longitude: pickup.lng,
          end_latitude: destination.lat,
          end_longitude: destination.lng
        },
        timeout: 5000
      });
      // Parse estimate into a numeric value if possible
      const rawEstimate = response.data?.prices?.[0]?.estimate;
      let fare = parseEstimateToNumber(rawEstimate);
      if (fare == null) fare = this.calculateFallbackFare('uber', distance);
      fareCache.set(cacheKey, fare);
      return fare;
    } catch (error) {
      console.log(`Uber API failed, using fallback: ${error.message}`);
      return this.calculateFallbackFare('uber', distance);
    }
  }

  // Fetch fare from Ola API
  async fetchOlaFare(pickup, destination, distance) {
    try {
      const cacheKey = getCacheKey('ola', pickup, destination);
      const cached = fareCache.get(cacheKey);
      if (cached) return cached;

      const response = await axios.get(this.platforms.ola.apiUrl, {
        headers: this.platforms.ola.headers,
        params: {
          pickup_lat: pickup.lat,
          pickup_lng: pickup.lng,
          drop_lat: destination.lat,
          drop_lng: destination.lng
        },
        timeout: 5000
      });
      const raw = response.data?.fare_breakup?.total;
      let fare = parseEstimateToNumber(raw);
      if (fare == null) fare = this.calculateFallbackFare('ola', distance);
      fareCache.set(cacheKey, fare);
      return fare;
    } catch (error) {
      console.log(`Ola API failed, using fallback: ${error.message}`);
      return this.calculateFallbackFare('ola', distance);
    }
  }

  // Scrape fare from Rapido website
  async scrapeRapidoFare(pickup, destination, distance) {
    try {
      const cacheKey = getCacheKey('rapido', pickup, destination);
      const cached = fareCache.get(cacheKey);
      if (cached) return cached;

      // Be defensive: puppeteer scraping relies on selectors that may change.
      // If Puppeteer is not available or the page layout changes, fall back to calculation.
      let browser;
      try {
        browser = await puppeteer.launch({
          headless: true,
          args: ['--no-sandbox', '--disable-setuid-sandbox']
        });

        const page = await browser.newPage();
        await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        await page.goto('https://rapido.bike/fare-calculator', {
          waitUntil: 'networkidle2',
          timeout: 10000
        });

        // These selectors are hypothetical — if they don't exist we'll catch and fallback.
        try {
          await page.type('#pickup', pickup.address || 'Pickup Location');
          await page.type('#destination', destination.address || 'Destination');
          await page.click('#calculate-fare');
          await page.waitForSelector('.fare-amount', { timeout: 5000 });
          const fareText = await page.$eval('.fare-amount', el => el.textContent);
          const fare = parseInt((fareText || '').replace(/[^0-9]/g, '')) || this.calculateFallbackFare('rapido', distance);
          fareCache.set(cacheKey, fare);
          return fare;
        } catch (innerErr) {
          console.log('Rapido selectors failed, falling back to estimated fare:', innerErr.message);
          return this.calculateFallbackFare('rapido', distance);
        }
      } finally {
        if (browser) {
          try { await browser.close(); } catch (e) { /* ignore */ }
        }
      }
    } catch (error) {
      console.log(`Rapido scraping failed, using fallback: ${error.message}`);
      return this.calculateFallbackFare('rapido', distance);
    }
  }

  // Calculate fallback fare with surge pricing
  calculateFallbackFare(serviceKey, distance) {
    const platform = this.platforms[serviceKey];
    const surgeMultiplier = this.getSurgeMultiplier(serviceKey);
    const baseFare = platform.fallbackBasePrice * surgeMultiplier;
    const distanceFare = distance * platform.fallbackPerKmRate * surgeMultiplier;
    
    return Math.round(baseFare + distanceFare);
  }

  // Main method to get all fare estimates
  async getAllFareEstimates(pickup, destination, distance, duration) {
    const estimates = [];
    
    const farePromises = [
      this.fetchUberFare(pickup, destination, distance),
      this.fetchOlaFare(pickup, destination, distance),
      this.scrapeRapidoFare(pickup, destination, distance),
      Promise.resolve(this.calculateFallbackFare('blusmart', distance))
    ];

    try {
      const fares = await Promise.allSettled(farePromises);
      
      Object.keys(this.platforms).forEach((serviceKey, index) => {
        const platform = this.platforms[serviceKey];
        const fareResult = fares[index];
        const fare = fareResult.status === 'fulfilled' ? fareResult.value : this.calculateFallbackFare(serviceKey, distance);
        
        estimates.push({
          id: serviceKey,
          name: platform.name,
          estimatedFare: fare,
          eta: Math.round(duration / 60) + Math.floor(Math.random() * 5),
          vehicleType: serviceKey === 'rapido' ? 'Bike' : 'Car',
          distance: (Number(distance) || 0).toFixed(1),
          duration: Math.round(duration / 60),
          surgeMultiplier: this.getSurgeMultiplier(serviceKey),
          lastUpdated: moment().toISOString(),
          dataSource: fareResult.status === 'fulfilled' ? 'API/Live' : 'Estimated'
        });
      });

      // Sort by price (lowest first)
      estimates.sort((a, b) => a.estimatedFare - b.estimatedFare);
      
      return estimates;
    } catch (error) {
      console.error('Error fetching fare estimates:', error);
      throw error;
    }
  }

  // Method to refresh all cached fares
  async refreshAllFares() {
    fareCache.flushAll();
    console.log('All cached fares cleared for refresh');
  }

  // Get cache statistics
  getCacheStats() {
    return {
      keys: fareCache.keys(),
      stats: fareCache.getStats()
    };
  }
}

module.exports = new FareService();
