#!/usr/bin/env node
/**
 * Startup script for the Express.js backend
 */
const { spawn } = require('child_process');
const fs = require('fs').promises;
const path = require('path');

async function installDependencies() {
  const packageJsonPath = path.join(__dirname, 'express_backend', 'package.json');
  
  try {
    await fs.access(packageJsonPath);
    console.log('Installing Node.js dependencies...');
    
    const install = spawn('npm', ['install'], {
      cwd: path.join(__dirname, 'express_backend'),
      stdio: 'inherit',
      shell: true
    });
    
    return new Promise((resolve, reject) => {
      install.on('close', (code) => {
        if (code === 0) {
          resolve();
        } else {
          reject(new Error(`npm install failed with code ${code}`));
        }
      });
    });
  } catch (error) {
    console.error('package.json not found!');
    throw error;
  }
}

async function setupEnvironment() {
  const envFile = path.join(__dirname, '.env');
  const envExampleFile = path.join(__dirname, '.env.example');
  
  try {
    await fs.access(envFile);
    console.log('.env file already exists');
  } catch {
    try {
      console.log('Creating .env file from example...');
      const content = await fs.readFile(envExampleFile, 'utf8');
      await fs.writeFile(envFile, content);
      console.log('Please update the .env file with your actual API keys and configuration!');
    } catch (error) {
      console.log('No .env.example file found!');
    }
  }
}

async function startServer() {
  console.log('Starting Express.js backend on http://localhost:3000');
  console.log('File upload endpoint: http://localhost:3000/upload/incident-image');
  
  const server = spawn('node', ['server.js'], {
    cwd: path.join(__dirname, 'express_backend'),
    stdio: 'inherit',
    shell: true
  });
  
  server.on('close', (code) => {
    console.log(`Express server exited with code ${code}`);
  });
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    console.log('\nStopping Express server...');
    server.kill('SIGINT');
    process.exit(0);
  });
}

async function main() {
  console.log('=== Community Mangrove Watch - Express Backend ===');
  
  try {
    await setupEnvironment();
    await installDependencies();
    await startServer();
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}
