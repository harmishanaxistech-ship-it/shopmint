const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { protect, ownerOnly } = require('../middlewares/auth');

router.get('/dashboard', protect, reportController.getDashboardSummary);
router.get('/sales', protect, ownerOnly, reportController.getSalesOverview);
router.get('/profit', protect, ownerOnly, reportController.getProfitReport);
router.get('/best-sellers', protect, ownerOnly, reportController.getBestSellers);

module.exports = router;

