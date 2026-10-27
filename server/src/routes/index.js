const express = require('express');
const router = express.Router();

const authRoutes = require('./authRoutes');
const shopRoutes = require('./shopRoutes');
const productRoutes = require('./productRoutes');
const customerRoutes = require('./customerRoutes');
const billRoutes = require('./billRoutes');
const reportRoutes = require('./reportRoutes');
const adminRoutes = require('./adminRoutes');

router.use('/auth', authRoutes);
router.use('/shop', shopRoutes);
router.use('/products', productRoutes);
router.use('/customers', customerRoutes);
router.use('/bills', billRoutes);
router.use('/reports', reportRoutes);
router.use('/admin', adminRoutes);

module.exports = router;

