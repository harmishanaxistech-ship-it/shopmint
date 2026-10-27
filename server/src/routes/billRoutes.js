const express = require('express');
const router = express.Router();
const billController = require('../controllers/billController');
const { protect, ownerOnly } = require('../middlewares/auth');

router.post('/', protect, billController.createBill);
router.get('/', protect, billController.getBills);
router.get('/:id', protect, billController.getBillById);
router.post('/:id/cancel', protect, ownerOnly, billController.cancelBill);

module.exports = router;

