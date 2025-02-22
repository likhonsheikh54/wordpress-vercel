{
  "version": 2,
  "framework": null,
  "functions": {
    "api/**/*.php": {
      "runtime": "vercel-php@0.6.0"
    }
  },
  "routes": [
    { "src": "/wp-admin/(.*)", "dest": "/public/wp-admin/$1" },
    { "src": "/wp-content/(.*)", "dest": "/public/wp-content/$1" },
    { "src": "/wp-includes/(.*)", "dest": "/public/wp-includes/$1" },
    { "src": "/(.*)\\.php$", "dest": "/api/index.php" },
    { "src": "/(.*)", "dest": "/api/index.php" }
  ],
  "env": {
    "PHP_VERSION": "8.1"
  }
}