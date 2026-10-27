const mongoose = require('mongoose');

const stockMovementSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
      index: true
    },
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: true,
      index: true
    },
    type: {
      type: String,
      enum: ['opening', 'purchase', 'sale', 'return', 'cancel', 'adjustment'],
      required: true
    },
    quantityChange: {
      type: Number,
      required: true
    },
    balanceAfter: {
      type: Number,
      required: true
    },
    refType: {
      type: String,
      enum: ['Bill', 'Adjustment', 'Restock', 'None'],
      default: 'None'
    },
    refId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null
    },
    reason: {
      type: String,
      default: ''
    },
    note: {
      type: String,
      default: ''
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }
  },
  {
    timestamps: true
  }
);

stockMovementSchema.index({ shopId: 1, productId: 1, createdAt: -1 });

module.exports = mongoose.model('StockMovement', stockMovementSchema);

