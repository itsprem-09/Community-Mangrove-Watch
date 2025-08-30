/**
 * Wrapper function to handle async operations in Express routes
 * Catches any errors and passes them to the next middleware
 * @param {Function} fn - Async function to wrap
 * @returns {Function} - Express middleware function
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = { asyncHandler };
