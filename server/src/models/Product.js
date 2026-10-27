const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
      index: true
    },
    name: {
      type: String,
      required: true,
      trim: true
    },
    barcode: {
      type: String,
      trim: true,
      default: ''
    },
    unit: {
      type: String,
      enum: ['pcs', 'kg', 'g', 'litre', 'ml', 'packet', 'box', 'dozen', 'bottle', 'meter'],
      default: 'pcs'
    },
    purchasePrice: {
      type: Number,
      required: true,
      min: 0,
      default: 0
    },
    sellingPrice: {
      type: Number,
      required: true,
      min: 0
    },
    currentStock: {
      type: Number,
      default: 0
    },
    minStock: {
      type: Number,
      default: 0
    },
    isLoose: {
      type: Boolean,
      default: false
    },
    imageUrl: {
      type: String,
      default: ''
    },
    active: {
      type: Boolean,
      default: true
    }
  },
  {
    timestamps: true
  }
);

productSchema.index({ shopId: 1, barcode: 1 });
productSchema.index({ shopId: 1, name: 1 });

module.exports = mongoose.model('Product', productSchema);

