const app = require('./app');
const env = require('./config/env');
const connectDB = require('./config/db');

connectDB().then(() => {
  app.listen(env.PORT, () => {
    console.log(`Scan Kirana Server running on port ${env.PORT} in ${env.NODE_ENV} mode`);
  });
});

