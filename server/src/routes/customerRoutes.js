const express = require('express');
const router = express.Router();
const customerController = require('../controllers/customerController');
const { protect } = require('../middlewares/auth');

router.get('/', protect, customerController.getCustomers);
router.post('/', protect, customerController.createCustomer);
router.put('/:id', protect, customerController.updateCustomer);
router.get('/:id/ledger', protect, customerController.getCustomerLedger);
router.post('/:id/payments', protect, customerController.receivePayment);
router.post('/:id/credit', protect, customerController.addCredit);

module.exports = router;

