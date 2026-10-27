const jwt = require('jsonwebtoken');
const env = require('../config/env');
const User = require('../models/User');
const Shop = require('../models/Shop');

const generateToken = (id) => {
  return jwt.sign({ id }, env.JWT_SECRET, { expiresIn: env.JWT_EXPIRES_IN });
};

exports.register = async (req, res) => {
  try {
    const { mobile, pin, name, shopName, role } = req.body;

    if (!mobile || !/^[6-9]\d{9}$/.test(mobile)) {
      return res.status(400).json({
        code: 'INVALID_MOBILE',
        message: 'Please enter a valid 10-digit Indian mobile number.'
      });
    }

    if (!pin || !/^\d{4}$/.test(pin)) {
      return res.status(400).json({
        code: 'INVALID_PIN',
        message: 'PIN must be exactly 4 digits.'
      });
    }

    if (!name || name.trim().length < 2) {
      return res.status(400).json({
        code: 'INVALID_NAME',
        message: 'Name must be at least 2 characters.'
      });
    }

    if (!shopName || shopName.trim().length < 2) {
      return res.status(400).json({
        code: 'INVALID_SHOP_NAME',
        message: 'Shop name must be at least 2 characters.'
      });
    }

    const existingUser = await User.findOne({ mobile: mobile.trim() });
    if (existingUser) {
      return res.status(400).json({
        code: 'USER_EXISTS',
        message: 'An account with this mobile number already exists. Please log in.'
      });
    }

    const assignedRole = role === 'admin' ? 'admin' : 'owner';

    const user = new User({
      mobile: mobile.trim(),
      pin: pin.trim(),
      name: name.trim(),
      shopName: shopName.trim(),
      role: assignedRole,
      lastLoginAt: new Date()
    });

    const shop = new Shop({
      ownerId: user._id,
      name: shopName.trim(),
      ownerName: name.trim(),
      mobile: mobile.trim()
    });

    await shop.save();

    user.shopId = shop._id;
    await user.save();

    const token = generateToken(user._id);

    return res.status(201).json({
      success: true,
      token,
      user: {
        id: user._id,
        mobile: user.mobile,
        name: user.name,
        shopName: user.shopName,
        role: user.role,
        language: user.language
      },
      shop: {
        id: shop._id,
        name: shop.name,
        ownerName: shop.ownerName,
        mobile: shop.mobile,
        settings: shop.settings
      }
    });
  } catch (err) {
    console.error('Register error:', err);
    return res.status(500).json({
      code: 'SERVER_ERROR',
      message: 'Something went wrong. Please try again.'
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { mobile, pin } = req.body;

    if (!mobile || !pin) {
      return res.status(400).json({
        code: 'MISSING_FIELDS',
        message: 'Please provide mobile number and 4-digit PIN.'
      });
    }

    const user = await User.findOne({ mobile: mobile.trim() });
    if (!user) {
      return res.status(401).json({
        code: 'INVALID_CREDENTIALS',
        message: 'Account not found with this mobile number.'
      });
    }

    if (user.status === 'disabled') {
      return res.status(403).json({
        code: 'ACCOUNT_DISABLED',
        message: 'Your account has been disabled.'
      });
    }

    const isMatch = await user.comparePin(pin.trim());
    if (!isMatch) {
      return res.status(401).json({
        code: 'INVALID_PIN',
        message: 'Incorrect 4-digit PIN. Please try again.'
      });
    }

    user.lastLoginAt = new Date();
    await user.save();

    const shop = await Shop.findById(user.shopId);

    const token = generateToken(user._id);

    return res.status(200).json({
      success: true,
      token,
      user: {
        id: user._id,
        mobile: user.mobile,
        name: user.name,
        shopName: user.shopName,
        role: user.role,
        language: user.language
      },
      shop: shop
        ? {
            id: shop._id,
            name: shop.name,
            ownerName: shop.ownerName,
            mobile: shop.mobile,
            settings: shop.settings
          }
        : null
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({
      code: 'SERVER_ERROR',
      message: 'Something went wrong. Please try again.'
    });
  }
};

exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-pin');
    const shop = await Shop.findById(user.shopId);

    return res.status(200).json({
      success: true,
      user,
      shop
    });
  } catch (err) {
    return res.status(500).json({
      code: 'SERVER_ERROR',
      message: 'Something went wrong. Please try again.'
    });
  }
};

