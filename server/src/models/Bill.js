const mongoose = require('mongoose');

const billItemSchema = new mongoose.Schema(
  {
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product'
    },
    name: {
      type: String,
      required: true
    },
    unit: {
      type: String,
      default: 'pcs'
    },
    qty: {
      type: Number,
      required: true,
      min: 0.001
    },
    rate: {
      type: Number,
      required: true,
      min: 0
    },
    purchasePrice: {
      type: Number,
      default: 0
    },
    discount: {
      type: Number,
      default: 0
    },
    imageUrl: {
      type: String,
      default: ''
    },
    amount: {
      type: Number,
      required: true
    }
  },
  { _id: false }
);

const billSchema = new mongoose.Schema(
  {
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop',
      required: true,
      index: true
    },
    billNo: {
      type: String,
      required: true
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Customer',
      default: null
    },
    customerName: {
      type: String,
      default: ''
    },
    items: [billItemSchema],
    subtotal: {
      type: Number,
      required: true
    },
    billDiscount: {
      type: Number,
      default: 0
    },
    roundOff: {
      type: Number,
      default: 0
    },
    grandTotal: {
      type: Number,
      required: true
    },
    paymentType: {
      type: String,
      enum: ['Cash', 'UPI', 'Other', 'Credit'],
      default: 'Cash'
    },
    amountReceived: {
      type: Number,
      required: true
    },
    balanceDue: {
      type: Number,
      default: 0
    },
    note: {
      type: String,
      default: ''
    },
    status: {
      type: String,
      enum: ['active', 'cancelled'],
      default: 'active'
    },
    cancelReason: {
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

billSchema.index({ shopId: 1, billNo: 1 }, { unique: true });
billSchema.index({ shopId: 1, createdAt: -1 });

module.exports = mongoose.model('Bill', billSchema);

