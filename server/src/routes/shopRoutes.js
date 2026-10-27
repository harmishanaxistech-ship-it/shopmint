const express = require('express');
const router = express.Router();
const shopController = require('../controllers/shopController');
const { protect, ownerOnly } = require('../middlewares/auth');

router.get('/', protect, shopController.getShop);
router.put('/', protect, ownerOnly, shopController.updateShop);

module.exports = router;

