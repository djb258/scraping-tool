require('dotenv').config();
const axios = require('axios');

const API_KEY = apify_api_63EvQr4y247iyULJibGB1JSOHYtd2VDqH';
const DATASET_ID = trG644GcFz8Alev;

async function testApiKey() {
  try {
    console.log('Testing API key...');
    const response = await axios.get(`https://api.apify.com/v2datasets/${DATASET_ID}/items`, {
      headers: {
        Authorization: `Bearer ${API_KEY}`,
        Accept: 'application/json'
      }
    });
    console.log('Success! Found', response.data.length, 'items');
    console.log('First item:', response.data[0]);
  } catch (error) {
    console.error('Error:', error.response?.data || error.message);
  }
}

testApiKey(); 