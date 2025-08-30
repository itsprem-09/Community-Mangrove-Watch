#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

/**
 * Setup script for Mangrove Watch Express Backend
 * This script helps initialize the development environment
 */

console.log('🌱 Setting up Mangrove Watch Express Backend...\n');

// Check if .env file exists
const envPath = path.join(__dirname, '..', '.env');
const envExamplePath = path.join(__dirname, '..', '.env.example');

if (!fs.existsSync(envPath)) {
    if (fs.existsSync(envExamplePath)) {
        // Copy .env.example to .env
        fs.copyFileSync(envExamplePath, envPath);
        console.log('✅ Created .env file from .env.example');
        console.log('⚠️  Please edit the .env file with your actual configuration values:\n');
        
        // Read and display environment variables that need configuration
        const envContent = fs.readFileSync(envPath, 'utf8');
        const needsConfig = envContent
            .split('\n')
            .filter(line => line.includes('your_') || line.includes('_here'))
            .map(line => line.split('=')[0])
            .filter(key => key && !key.startsWith('#'));
        
        if (needsConfig.length > 0) {
            console.log('   Required configuration variables:');
            needsConfig.forEach(key => {
                console.log(`   - ${key}`);
            });
            console.log('');
        }
    } else {
        console.log('❌ .env.example file not found. Please ensure it exists in the project root.');
        process.exit(1);
    }
} else {
    console.log('✅ .env file already exists');
}

// Check if node_modules exists
const nodeModulesPath = path.join(__dirname, '..', 'node_modules');
if (!fs.existsSync(nodeModulesPath)) {
    console.log('📦 Installing dependencies...');
    const { execSync } = require('child_process');
    try {
        execSync('npm install', { cwd: path.join(__dirname, '..'), stdio: 'inherit' });
        console.log('✅ Dependencies installed successfully');
    } catch (error) {
        console.log('❌ Failed to install dependencies. Please run "npm install" manually.');
    }
} else {
    console.log('✅ Dependencies already installed');
}

// Create uploads directory if it doesn't exist
const uploadsPath = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsPath)) {
    fs.mkdirSync(uploadsPath, { recursive: true });
    console.log('✅ Created uploads directory');
} else {
    console.log('✅ Uploads directory already exists');
}

console.log('\n🎉 Setup complete! Next steps:');
console.log('1. Edit the .env file with your actual configuration values');
console.log('2. Ensure MongoDB is running on your system');
console.log('3. Configure your email SMTP settings in the .env file');
console.log('4. Start the development server with: npm run dev');
console.log('\n📧 Email Service Setup:');
console.log('- Configure SMTP_* variables for email sending');
console.log('- Set ADMIN_EMAIL, FROM_EMAIL, and SYSTEM_EMAIL addresses');
console.log('- Test email configuration using the /api/emails/test endpoint');
console.log('\n🔧 For production deployment:');
console.log('- Set NODE_ENV=production');
console.log('- Use strong values for JWT_SECRET and SESSION_SECRET');
console.log('- Configure proper CORS_ORIGINS for your domain');
console.log('\n📚 Documentation: Check README.md for more details');
