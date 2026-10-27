const mongoose = require('mongoose');

const shopSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    name: {
      type: String,
      required: true,
      trim: true
    },
    ownerName: {
      type: String,
      required: true,
      trim: true
    },
    mobile: {
      type: String,
      required: true,
      trim: true
    },
    type: {
      type: String,
      default: 'Kirana'
    },
    address: {
      type: String,
      default: ''
    },
    logoUrl: {
      type: String,
      default: ''
    },
    settings: {
      invoiceFooter: {
        type: String,
        default: 'Thank you, visit again'
      },
      showLogo: {
        type: Boolean,
        default: false
      },
      showStaff: {
        type: Boolean,
        default: false
      },
      upiId: {
        type: String,
        default: ''
      },
      allowNegativeStock: {
        type: Boolean,
        default: false
      }
    }
  },
  {
    timestamps: true
  }
);

module.exports = mongoose.model('Shop', shopSchema);

