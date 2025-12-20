/**
 * Example Unit Tests for Error Handler
 */

const {
  AppError,
  ValidationError,
  UnauthorizedError,
  NotFoundError,
  errorHandler,
  asyncHandler
} = require('../services/shared/middleware/errorHandler');

describe('Error Handler Middleware', () => {
  describe('Custom Error Classes', () => {
    test('AppError should create error with status code', () => {
      const error = new AppError('Test error', 400);
      
      expect(error.message).toBe('Test error');
      expect(error.statusCode).toBe(400);
      expect(error.isOperational).toBe(true);
      expect(error.timestamp).toBeDefined();
    });

    test('ValidationError should have 400 status code', () => {
      const errors = ['Field required', 'Invalid format'];
      const error = new ValidationError('Validation failed', errors);
      
      expect(error.statusCode).toBe(400);
      expect(error.errors).toEqual(errors);
    });

    test('UnauthorizedError should have 401 status code', () => {
      const error = new UnauthorizedError('Invalid token');
      
      expect(error.statusCode).toBe(401);
      expect(error.message).toBe('Invalid token');
    });

    test('NotFoundError should have 404 status code', () => {
      const error = new NotFoundError('User');
      
      expect(error.statusCode).toBe(404);
      expect(error.message).toBe('User not found');
    });
  });

  describe('Error Handler', () => {
    let req, res, next;

    beforeEach(() => {
      req = {
        url: '/api/test',
        method: 'GET',
        ip: '127.0.0.1'
      };
      res = {
        status: jest.fn().mockReturnThis(),
        json: jest.fn()
      };
      next = jest.fn();
    });

    test('should handle AppError with correct status code', () => {
      const error = new AppError('Test error', 400);
      
      errorHandler(error, req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Test error',
          timestamp: expect.any(String)
        })
      );
    });

    test('should handle ValidationError with errors array', () => {
      const errors = ['Field required'];
      const error = new ValidationError('Validation failed', errors);
      
      errorHandler(error, req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Validation failed',
          errors
        })
      );
    });

    test('should handle unknown errors with 500 status', () => {
      const error = new Error('Unknown error');
      
      errorHandler(error, req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Unknown error'
        })
      );
    });

    test('should handle MongoDB duplicate key error', () => {
      const error = new Error('Duplicate key');
      error.code = 11000;
      
      errorHandler(error, req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(409);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Duplicate field value'
        })
      );
    });

    test('should handle JWT errors', () => {
      const error = new Error('Invalid token');
      error.name = 'JsonWebTokenError';
      
      errorHandler(error, req, res, next);
      
      expect(res.status).toHaveBeenCalledWith(401);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Invalid token'
        })
      );
    });
  });

  describe('Async Handler', () => {
    test('should call next with error on promise rejection', async () => {
      const error = new Error('Async error');
      const asyncFn = jest.fn().mockRejectedValue(error);
      const next = jest.fn();
      
      const handler = asyncHandler(asyncFn);
      await handler({}, {}, next);
      
      expect(next).toHaveBeenCalledWith(error);
    });

    test('should not call next on successful execution', async () => {
      const asyncFn = jest.fn().mockResolvedValue('success');
      const next = jest.fn();
      
      const handler = asyncHandler(asyncFn);
      await handler({}, {}, next);
      
      expect(next).not.toHaveBeenCalled();
    });
  });
});
