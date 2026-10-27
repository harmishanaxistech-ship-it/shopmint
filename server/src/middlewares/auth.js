const jwt = require('jsonwebtoken');
const env = require('../config/env');
const User = require('../models/User');

const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return res.status(401).json({
      code: 'UNAUTHORIZED',
      message: 'Access denied. Please log in.'
    });
  }

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-pin');

    if (!user) {
      return res.status(401).json({
        code: 'USER_NOT_FOUND',
        message: 'User no longer exists.'
      });
    }

    if (user.status === 'disabled') {
      return res.status(403).json({
        code: 'ACCESS_DISABLED',
        message: 'Your account has been disabled.'
      });
    }

    req.user = user;
    req.shopId = user.shopId;
    next();
  } catch (err) {
    return res.status(401).json({
      code: 'INVALID_TOKEN',
      message: 'Session expired or invalid token. Please log in again.'
    });
  }
};

const adminOnly = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    return next();
  }
  return res.status(403).json({
    code: 'FORBIDDEN',
    message: 'Admin access required.'
  });
};

const ownerOnly = (req, res, next) => {
  if (req.user && (req.user.role === 'owner' || req.user.role === 'admin')) {
    return next();
  }
  return res.status(403).json({
    code: 'FORBIDDEN',
    message: 'Shop owner access required.'
  });
};

module.exports = { protect, adminOnly, ownerOnly };

