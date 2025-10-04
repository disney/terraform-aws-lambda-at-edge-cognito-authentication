module.exports = {
  env: {
    node: true,
    es2022: true
  },
  extends: [
    'standard'
  ],
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: 'module'
  },
  rules: {
    // AWS Lambda@Edge specific rules
    'no-console': 'warn', // Prefer structured logging
    'no-process-exit': 'error', // Lambda handles process lifecycle
    'no-sync': 'warn', // Prefer async operations
    
    // Performance and best practices
    'prefer-const': 'error',
    'no-var': 'error',
    'object-shorthand': 'error',
    'prefer-arrow-callback': 'error',
    'prefer-template': 'error',
    
    // Error handling
    'handle-callback-err': 'error',
    'no-throw-literal': 'error',
    
    // Code quality
    'complexity': ['warn', 10],
    'max-depth': ['warn', 4],
    'max-len': ['warn', { code: 120 }],
    'max-lines-per-function': ['warn', 50],
    
    // Security
    'no-eval': 'error',
    'no-implied-eval': 'error',
    'no-new-func': 'error'
  },
  globals: {
    // AWS Lambda globals
    exports: 'writable',
    module: 'writable',
    require: 'readonly',
    process: 'readonly',
    Buffer: 'readonly',
    __dirname: 'readonly',
    __filename: 'readonly',
    global: 'readonly',
    console: 'readonly'
  },
  overrides: [
    {
      files: ['*.test.js', '*.spec.js'],
      env: {
        jest: true
      },
      rules: {
        'max-lines-per-function': 'off'
      }
    }
  ]
}
