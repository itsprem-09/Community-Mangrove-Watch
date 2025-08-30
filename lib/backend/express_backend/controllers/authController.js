const User = require('../models/User');
const { generateToken } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const { validateRegistration, validateLogin } = require('../utils/validation');

/**
 * @desc    Register a new user
 * @route   POST /auth/register
 * @access  Public
 */
const register = asyncHandler(async (req, res) => {
  console.log('[AUTH] Register request received');
  console.log('[AUTH] Request headers:', req.headers);
  console.log('[AUTH] Request body keys:', Object.keys(req.body));
  
  // Validate input
  const validationError = validateRegistration(req.body);
  if (validationError) {
    console.log('[AUTH] Validation error:', validationError);
    return res.status(400).json({
      error: 'Validation Error',
      detail: validationError
    });
  }

  const { name, email, password, role, organization, phone, location } = req.body;

  // Check if user already exists
  console.log('[AUTH] Checking if email exists:', email);
  const existingUser = await User.findByEmail(email);
  if (existingUser) {
    console.log('[AUTH] Email already exists');
    return res.status(400).json({
      error: 'Registration Failed',
      detail: 'Email already registered'
    });
  }
  console.log('[AUTH] Email is available');

  // Create new user
  const user = new User({
    name,
    email,
    password,
    role: role || 'citizen',
    organization,
    phone,
    location
  });

  // Set admin flag if role is admin or government
  if (role === 'admin' || role === 'government') {
    user.is_admin = true;
  }

  console.log('[AUTH] Saving new user...');
  await user.save();
  console.log('[AUTH] User saved successfully with ID:', user._id.toString());

  // Generate JWT token
  const token = generateToken({
    sub: user._id.toString(),
    email: user.email,
    role: user.role
  });
  console.log('[AUTH] JWT token generated successfully');

  // Return user response (password excluded by toJSON transform)
  console.log('[AUTH] Registration successful, sending response');
  res.status(200).json({
    id: user._id.toString(),
    name: user.name,
    email: user.email,
    role: user.role,
    organization: user.organization,
    location: user.location,
    points: user.points,
    badges: user.badges,
    is_verified: user.is_verified,
    joined_date: user.createdAt,
    access_token: token,
    token_type: 'bearer'
  });
});

/**
 * @desc    Login user
 * @route   POST /auth/login
 * @access  Public
 */
const login = asyncHandler(async (req, res) => {
  console.log('[AUTH] Login request received');
  console.log('[AUTH] Request body keys:', Object.keys(req.body));
  
  // Validate input
  const validationError = validateLogin(req.body);
  if (validationError) {
    console.log('[AUTH] Login validation error:', validationError);
    return res.status(400).json({
      error: 'Validation Error',
      detail: validationError
    });
  }

  const { email, password } = req.body;

  // Find user by email
  const user = await User.findByEmail(email);
  if (!user) {
    return res.status(401).json({
      error: 'Authentication Failed',
      detail: 'Invalid credentials'
    });
  }

  // Check if user is active
  if (!user.isActive) {
    return res.status(403).json({
      error: 'Account Disabled',
      detail: 'Your account has been disabled. Please contact support.'
    });
  }

  // Verify password
  const isValidPassword = await user.comparePassword(password);
  if (!isValidPassword) {
    return res.status(401).json({
      error: 'Authentication Failed',
      detail: 'Invalid credentials'
    });
  }

  // Update last login
  user.lastLogin = new Date();
  await user.save();

  // Generate JWT token
  const token = generateToken({
    sub: user._id.toString(),
    email: user.email,
    role: user.role
  });

  // Return token response
  res.status(200).json({
    access_token: token,
    token_type: 'bearer'
  });
});

/**
 * @desc    Get user profile
 * @route   GET /user/profile
 * @access  Private
 */
const getProfile = asyncHandler(async (req, res) => {
  // req.user is set by authenticateToken middleware
  const userId = req.user.sub;

  // Find user by ID
  const user = await User.findById(userId).select('-password');
  if (!user) {
    return res.status(404).json({
      error: 'User Not Found',
      detail: 'User profile not found'
    });
  }

  // Calculate user rank based on points
  const rank = await User.countDocuments({ points: { $gt: user.points } }) + 1;

  // Get report statistics (to be implemented later when incident model is added)
  const totalReports = 0; // Placeholder
  const verifiedReports = 0; // Placeholder

  // Return user profile
  res.status(200).json({
    id: user._id.toString(),
    name: user.name,
    email: user.email,
    role: user.role,
    organization: user.organization,
    phone: user.phone,
    location: user.location,
    points: user.points,
    badges: user.badges,
    is_verified: user.is_verified,
    is_admin: user.is_admin,
    rank: rank,
    total_reports: totalReports,
    verified_reports: verifiedReports,
    joined_date: user.createdAt,
    created_at: user.createdAt,
    updated_at: user.updatedAt
  });
});

/**
 * @desc    Update user profile
 * @route   PUT /user/profile
 * @access  Private
 */
const updateProfile = asyncHandler(async (req, res) => {
  const userId = req.user.sub;
  const updates = req.body;

  // Fields that cannot be updated through this endpoint
  const restrictedFields = ['email', 'password', 'role', 'points', 'badges', 'is_verified', 'is_admin'];
  restrictedFields.forEach(field => delete updates[field]);

  // Find and update user
  const user = await User.findByIdAndUpdate(
    userId,
    { $set: updates },
    { new: true, runValidators: true }
  ).select('-password');

  if (!user) {
    return res.status(404).json({
      error: 'User Not Found',
      detail: 'User profile not found'
    });
  }

  res.status(200).json({
    message: 'Profile updated successfully',
    user: user
  });
});

/**
 * @desc    Add points to user
 * @route   POST /user/add-points
 * @access  Private (Admin only - to be implemented)
 */
const addPoints = asyncHandler(async (req, res) => {
  const { userId, points } = req.body;

  if (!userId || !points || points < 0) {
    return res.status(400).json({
      error: 'Validation Error',
      detail: 'Valid userId and positive points value required'
    });
  }

  const user = await User.findById(userId);
  if (!user) {
    return res.status(404).json({
      error: 'User Not Found',
      detail: 'User not found'
    });
  }

  await user.addPoints(points);

  res.status(200).json({
    message: 'Points added successfully',
    newTotal: user.points
  });
});

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  addPoints
};
