/**
 * Input Validation Middleware
 * Validates and sanitizes user input
 */

const { ValidationError } = require('./errorHandler');

/**
 * Validate email format
 */
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

/**
 * Validate password strength
 * At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
 */
const isStrongPassword = (password) => {
  const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return passwordRegex.test(password);
};

/**
 * Validate username
 * 3-20 characters, alphanumeric and underscore only
 */
const isValidUsername = (username) => {
  const usernameRegex = /^[a-zA-Z0-9_]{3,20}$/;
  return usernameRegex.test(username);
};

/**
 * Sanitize string input
 */
const sanitizeString = (str) => {
  if (typeof str !== 'string') {
    return str;
  }
  // Remove potential XSS
  return str
    .trim()
    .replace(/[<>]/g, '')
    .substring(0, 1000); // Max length
};

/**
 * Validate registration input
 */
const validateRegistration = (req, res, next) => {
  const errors = [];
  const { username, email, password } = req.body;

  if (!username || !email || !password) {
    throw new ValidationError('Username, email, and password are required');
  }

  if (!isValidUsername(username)) {
    errors.push('Username must be 3-20 characters, alphanumeric and underscore only');
  }

  if (!isValidEmail(email)) {
    errors.push('Invalid email format');
  }

  if (!isStrongPassword(password)) {
    errors.push('Password must be at least 8 characters with uppercase, lowercase, number, and special character');
  }

  if (errors.length > 0) {
    throw new ValidationError('Validation failed', errors);
  }

  // Sanitize inputs
  req.body.username = sanitizeString(username);
  req.body.email = sanitizeString(email).toLowerCase();

  next();
};

/**
 * Validate MongoDB ObjectId
 */
const validateObjectId = (paramName) => (req, res, next) => {
  const id = req.params[paramName];
  const objectIdRegex = /^[0-9a-fA-F]{24}$/;
  
  if (!objectIdRegex.test(id)) {
    throw new ValidationError(`Invalid ${paramName} format`);
  }
  
  next();
};

/**
 * Validate quiz creation input
 */
const validateQuizCreation = (req, res, next) => {
  const errors = [];
  const { title, questions } = req.body;

  if (!title || title.trim().length === 0) {
    errors.push('Quiz title is required');
  }

  if (title && title.length > 200) {
    errors.push('Quiz title must be less than 200 characters');
  }

  if (!Array.isArray(questions) || questions.length === 0) {
    errors.push('At least one question is required');
  }

  if (questions && questions.length > 50) {
    errors.push('Maximum 50 questions allowed per quiz');
  }

  // Validate each question
  if (Array.isArray(questions)) {
    questions.forEach((q, index) => {
      if (!q.question || q.question.trim().length === 0) {
        errors.push(`Question ${index + 1}: Question text is required`);
      }
      if (!Array.isArray(q.options) || q.options.length < 2) {
        errors.push(`Question ${index + 1}: At least 2 options required`);
      }
      if (q.correctAnswer === undefined || q.correctAnswer === null) {
        errors.push(`Question ${index + 1}: Correct answer is required`);
      }
      if (q.timeLimit && (q.timeLimit < 5 || q.timeLimit > 120)) {
        errors.push(`Question ${index + 1}: Time limit must be between 5-120 seconds`);
      }
    });
  }

  if (errors.length > 0) {
    throw new ValidationError('Quiz validation failed', errors);
  }

  // Sanitize title
  req.body.title = sanitizeString(title);

  next();
};

/**
 * Validate pagination parameters
 */
const validatePagination = (req, res, next) => {
  const { page = 1, limit = 10 } = req.query;

  const pageNum = parseInt(page, 10);
  const limitNum = parseInt(limit, 10);

  if (isNaN(pageNum) || pageNum < 1) {
    throw new ValidationError('Page must be a positive number');
  }

  if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
    throw new ValidationError('Limit must be between 1 and 100');
  }

  req.pagination = {
    page: pageNum,
    limit: limitNum,
    skip: (pageNum - 1) * limitNum
  };

  next();
};

module.exports = {
  isValidEmail,
  isStrongPassword,
  isValidUsername,
  sanitizeString,
  validateRegistration,
  validateObjectId,
  validateQuizCreation,
  validatePagination
};
