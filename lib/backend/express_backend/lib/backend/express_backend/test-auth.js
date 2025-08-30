const axios = require('axios');

const BASE_URL = 'http://localhost:5000';

// Test user data
const testUser = {
  name: 'Test User',
  email: 'test@example.com',
  password: 'password123',
  role: 'citizen',
  location: 'Test City'
};

let authToken = null;

async function testRegister() {
  console.log('\n=== Testing Registration ===');
  try {
    const response = await axios.post(`${BASE_URL}/auth/register`, testUser);
    console.log('✓ Registration successful');
    console.log('Response:', {
      id: response.data.id,
      name: response.data.name,
      email: response.data.email,
      role: response.data.role,
      points: response.data.points
    });
    authToken = response.data.access_token;
    return true;
  } catch (error) {
    console.error('✗ Registration failed:', error.response?.data || error.message);
    return false;
  }
}

async function testLogin() {
  console.log('\n=== Testing Login ===');
  try {
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: testUser.email,
      password: testUser.password
    });
    console.log('✓ Login successful');
    console.log('Response:', response.data);
    authToken = response.data.access_token;
    return true;
  } catch (error) {
    console.error('✗ Login failed:', error.response?.data || error.message);
    return false;
  }
}

async function testGetProfile() {
  console.log('\n=== Testing Get Profile ===');
  try {
    const response = await axios.get(`${BASE_URL}/user/profile`, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    console.log('✓ Get profile successful');
    console.log('Profile:', {
      id: response.data.id,
      name: response.data.name,
      email: response.data.email,
      role: response.data.role,
      points: response.data.points,
      rank: response.data.rank
    });
    return true;
  } catch (error) {
    console.error('✗ Get profile failed:', error.response?.data || error.message);
    return false;
  }
}

async function testUpdateProfile() {
  console.log('\n=== Testing Update Profile ===');
  try {
    const response = await axios.put(`${BASE_URL}/user/profile`, {
      location: 'Updated City',
      phone: '+1234567890'
    }, {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });
    console.log('✓ Update profile successful');
    console.log('Response:', response.data.message);
    return true;
  } catch (error) {
    console.error('✗ Update profile failed:', error.response?.data || error.message);
    return false;
  }
}

async function runTests() {
  console.log('Starting authentication tests...');
  console.log(`Server URL: ${BASE_URL}`);
  
  // Test registration (might fail if user already exists)
  await testRegister();
  
  // Test login
  const loginSuccess = await testLogin();
  
  if (loginSuccess && authToken) {
    // Test authenticated endpoints
    await testGetProfile();
    await testUpdateProfile();
    await testGetProfile(); // Get profile again to see updates
  }
  
  console.log('\n=== Tests Complete ===');
}

// Check if axios is installed
try {
  require.resolve('axios');
  runTests();
} catch (e) {
  console.log('Installing axios for testing...');
  require('child_process').execSync('npm install axios', { stdio: 'inherit' });
  console.log('Please run this script again.');
}
