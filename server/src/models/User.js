const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    mobile: {
      type: String,
      required: true,
      unique: true,
      trim: true
    },
    pin: {
      type: String,
      required: true
    },
    name: {
      type: String,
      required: true,
      trim: true
    },
    shopName: {
      type: String,
      required: true,
      trim: true
    },
    shopId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Shop'
    },
    role: {
      type: String,
      enum: ['admin', 'owner', 'staff'],
      default: 'owner'
    },
    language: {
      type: String,
      enum: ['gu', 'hi', 'en'],
      default: 'gu'
    },
    status: {
      type: String,
      enum: ['active', 'disabled'],
      default: 'active'
    },
    lastLoginAt: {
      type: Date
    }
  },
  {
    timestamps: true
  }
);

userSchema.pre('save', async function () {
  if (!this.isModified('pin')) return;
  const salt = await bcrypt.genSalt(10);
  this.pin = await bcrypt.hash(this.pin, salt);
});

userSchema.methods.comparePin = async function (enteredPin) {
  return bcrypt.compare(enteredPin, this.pin);
};

module.exports = mongoose.model('User', userSchema);

