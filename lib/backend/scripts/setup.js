#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🚀 Setting up Mangrove Watch Backend...\n');

// Check if .env file exists
const envPath = path.join(__dirname, '../.env');
const envExamplePath = path.join(__dirname, '../.env.example');

if (!fs.existsSync(envPath)) {
  if (fs.existsSync(envExamplePath)) {
    console.log('📋 Creating .env file from .env.example...');
    fs.copyFileSync(envExamplePath, envPath);
    console.log('✅ .env file created successfully!\n');
  } else {
    console.log('❌ .env.example file not found. Please create it first.\n');
    process.exit(1);
  }
} else {
  console.log('✅ .env file already exists.\n');
}

console.log('🔧 Configuration Steps:');
console.log('1. Edit the .env file with your actual values:');
console.log('   - MongoDB connection string (MONGODB_URI)');
console.log('   - JWT secret key (JWT_SECRET)');
console.log('   - Cloudinary credentials (CLOUDINARY_*)');
console.log('   - Email configuration (EMAIL_*)');
console.log('   - Google API keys if needed\n');

console.log('2. Install dependencies:');
console.log('   cd express_backend && npm install\n');

console.log('3. Start the server:');
console.log('   npm run dev (development)');
console.log('   npm start (production)\n');

console.log('📚 Available API endpoints:');
console.log('   - GET  /health           - Health check');
console.log('   - POST /upload/incident-image - Upload incident image');
console.log('   - POST /upload/profile-image  - Upload profile image');
console.log('   - GET  /upload/user-uploads   - Get user uploads');
console.log('   - POST /email/test            - Test email configuration');
console.log('   - POST /email/notify/*        - Send notifications\n');

console.log('🎉 Setup complete! Make sure to configure your environment variables.\n');
