const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

async function checkDatabase() {
  try {
    console.log('=== MongoDB Database Check ===\n');
    console.log('Connection string:', process.env.MONGODB_URI);
    console.log('Expected database:', process.env.DATABASE_NAME);
    
    console.log('\nConnecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ Connected to MongoDB\n');

    const db = mongoose.connection.db;
    
    // Get database name
    console.log('Current database name:', db.databaseName);
    
    if (db.databaseName !== 'mangrove_watch') {
      console.log('\n⚠️  WARNING: Not using mangrove_watch database!');
      console.log('Currently using:', db.databaseName);
      console.log('This needs to be fixed in the connection string.');
    } else {
      console.log('✅ Correctly using mangrove_watch database');
    }

    // List collections
    console.log('\n=== Collections in current database ===');
    const collections = await db.listCollections().toArray();
    collections.forEach(col => {
      console.log(`  - ${col.name}`);
    });

    // Count users in current database
    const usersCollection = db.collection('users');
    const userCount = await usersCollection.countDocuments();
    console.log(`\n📊 Users in ${db.databaseName}: ${userCount}`);

    // Show a few users (without sensitive data)
    if (userCount > 0) {
      console.log('\nSample users:');
      const sampleUsers = await usersCollection.find({})
        .limit(5)
        .project({ name: 1, email: 1, role: 1, createdAt: 1 })
        .toArray();
      
      sampleUsers.forEach(user => {
        console.log(`  - ${user.name} (${user.email}) - Role: ${user.role}`);
      });
    }

    // Check if test database exists and has users
    console.log('\n=== Checking other databases ===');
    const admin = db.admin();
    const databases = await admin.listDatabases();
    
    databases.databases.forEach(database => {
      if (database.name === 'test' || database.name === 'mangrove_watch') {
        console.log(`Database: ${database.name} (Size: ${(database.sizeOnDisk / 1024 / 1024).toFixed(2)} MB)`);
      }
    });

    console.log('\n=== Recommendations ===');
    if (db.databaseName !== 'mangrove_watch') {
      console.log('❌ You need to update the MongoDB URI to specify mangrove_watch database');
      console.log('   Current: mongodb+srv://user:pass@cluster.mongodb.net/');
      console.log('   Should be: mongodb+srv://user:pass@cluster.mongodb.net/mangrove_watch');
    } else {
      console.log('✅ Database configuration is correct!');
    }
    
  } catch (error) {
    console.error('Error checking database:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n✅ Database connection closed');
  }
}

// Run the check
checkDatabase();
