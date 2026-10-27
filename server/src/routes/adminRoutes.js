const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { protect, adminOnly } = require('../middlewares/auth');

router.get('/stats', protect, adminOnly, adminController.getSystemStats);
router.get('/shops', protect, adminOnly, adminController.getAllShops);
router.get('/users', protect, adminOnly, adminController.getAllUsers);
router.put('/users/:id/status', protect, adminOnly, adminController.updateUserStatus);
router.put('/shops/:id', protect, adminOnly, adminController.updateShopByAdmin);

module.exports = router;

