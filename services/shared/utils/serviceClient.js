/**
 * Service Communication Utilities
 * Provides resilient inter-service communication with retry and circuit breaker
 */

const axios = require('axios');
const { logger } = require('../utils/logger');

/**
 * Circuit Breaker implementation
 */
class CircuitBreaker {
  constructor(options = {}) {
    this.failureThreshold = options.failureThreshold || 5;
    this.resetTimeout = options.resetTimeout || 60000; // 60 seconds
    this.monitorInterval = options.monitorInterval || 10000; // 10 seconds
    
    this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
    this.failureCount = 0;
    this.nextAttempt = Date.now();
    this.successCount = 0;
  }

  async execute(fn) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN');
      }
      this.state = 'HALF_OPEN';
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;
    if (this.state === 'HALF_OPEN') {
      this.state = 'CLOSED';
      logger.info('Circuit breaker closed');
    }
  }

  onFailure() {
    this.failureCount++;
    if (this.failureCount >= this.failureThreshold) {
      this.state = 'OPEN';
      this.nextAttempt = Date.now() + this.resetTimeout;
      logger.warn('Circuit breaker opened', {
        failures: this.failureCount,
        nextAttempt: new Date(this.nextAttempt).toISOString()
      });
    }
  }

  getState() {
    return this.state;
  }
}

/**
 * Retry with exponential backoff
 */
const retryWithBackoff = async (fn, options = {}) => {
  const maxRetries = options.maxRetries || 3;
  const initialDelay = options.initialDelay || 1000;
  const maxDelay = options.maxDelay || 10000;
  const backoffMultiplier = options.backoffMultiplier || 2;

  let lastError;
  
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      
      if (attempt === maxRetries) {
        break;
      }

      const delay = Math.min(
        initialDelay * Math.pow(backoffMultiplier, attempt),
        maxDelay
      );
      
      logger.warn(`Retry attempt ${attempt + 1}/${maxRetries} after ${delay}ms`, {
        error: error.message
      });
      
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  throw lastError;
};

/**
 * HTTP Client with retry and circuit breaker
 */
class ServiceClient {
  constructor(baseURL, options = {}) {
    this.baseURL = baseURL;
    this.timeout = options.timeout || 5000;
    this.circuitBreaker = new CircuitBreaker(options.circuitBreaker);
    this.retryOptions = options.retry || {};
    
    this.client = axios.create({
      baseURL,
      timeout: this.timeout,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    // Add request interceptor for logging
    this.client.interceptors.request.use(
      (config) => {
        logger.debug('Outgoing request', {
          method: config.method,
          url: config.url,
          baseURL: config.baseURL
        });
        return config;
      },
      (error) => {
        logger.error('Request error', { error: error.message });
        return Promise.reject(error);
      }
    );

    // Add response interceptor for logging
    this.client.interceptors.response.use(
      (response) => {
        logger.debug('Response received', {
          status: response.status,
          url: response.config.url
        });
        return response;
      },
      (error) => {
        logger.error('Response error', {
          message: error.message,
          status: error.response?.status,
          url: error.config?.url
        });
        return Promise.reject(error);
      }
    );
  }

  async get(url, config = {}) {
    return this.request('GET', url, null, config);
  }

  async post(url, data, config = {}) {
    return this.request('POST', url, data, config);
  }

  async put(url, data, config = {}) {
    return this.request('PUT', url, data, config);
  }

  async delete(url, config = {}) {
    return this.request('DELETE', url, null, config);
  }

  async request(method, url, data = null, config = {}) {
    const requestFn = async () => {
      return this.circuitBreaker.execute(async () => {
        const response = await this.client.request({
          method,
          url,
          data,
          ...config
        });
        return response.data;
      });
    };

    return retryWithBackoff(requestFn, this.retryOptions);
  }

  getCircuitBreakerState() {
    return this.circuitBreaker.getState();
  }
}

/**
 * Create service clients for all microservices
 */
const createServiceClients = () => {
  const clients = {};
  
  const services = [
    { name: 'auth', url: process.env.AUTH_SERVICE_URL || 'http://auth-service:3001' },
    { name: 'user', url: process.env.USER_SERVICE_URL || 'http://user-service:3002' },
    { name: 'quiz', url: process.env.QUIZ_SERVICE_URL || 'http://quiz-service:3003' },
    { name: 'game', url: process.env.GAME_SERVICE_URL || 'http://game-service:3004' },
    { name: 'analytics', url: process.env.ANALYTICS_SERVICE_URL || 'http://analytics-service:3005' }
  ];

  services.forEach(({ name, url }) => {
    clients[name] = new ServiceClient(url, {
      timeout: 5000,
      circuitBreaker: {
        failureThreshold: 5,
        resetTimeout: 60000
      },
      retry: {
        maxRetries: 3,
        initialDelay: 1000
      }
    });
  });

  return clients;
};

module.exports = {
  CircuitBreaker,
  retryWithBackoff,
  ServiceClient,
  createServiceClients
};
