#!/usr/bin/env node
/**
 * BlackStarr Data Sync Server
 * Simple Node.js endpoint for syncing app state to server
 * Listens on port 3737 for POST requests from the browser app
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const DATA_DIR = path.join(__dirname, 'data');
const STATE_FILE = path.join(DATA_DIR, 'state.json');
const BACKUPS_DIR = path.join(DATA_DIR, 'backups');

// Ensure directories exist
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
if (!fs.existsSync(BACKUPS_DIR)) fs.mkdirSync(BACKUPS_DIR, { recursive: true });

const server = http.createServer((req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Content-Type', 'application/json');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // GET /api/state - Retrieve current state
  if (req.method === 'GET' && req.url === '/api/state') {
    try {
      if (fs.existsSync(STATE_FILE)) {
        const state = fs.readFileSync(STATE_FILE, 'utf8');
        res.writeHead(200);
        res.end(state);
      } else {
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'No state file found' }));
      }
    } catch (err) {
      res.writeHead(500);
      res.end(JSON.stringify({ error: err.message }));
    }
    return;
  }

  // POST /api/sync - Save state
  if (req.method === 'POST' && req.url === '/api/sync') {
    let body = '';
    req.on('data', chunk => { body += chunk.toString(); });
    req.on('end', () => {
      try {
        const state = JSON.parse(body);
        
        // Create timestamped backup
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const backupFile = path.join(BACKUPS_DIR, `state.${timestamp}.json`);
        if (fs.existsSync(STATE_FILE)) {
          fs.copyFileSync(STATE_FILE, backupFile);
        }
        
        // Save current state
        state.lastSync = new Date().toISOString();
        fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
        
        res.writeHead(200);
        res.end(JSON.stringify({ 
          success: true, 
          message: 'State synced',
          timestamp: state.lastSync 
        }));
      } catch (err) {
        res.writeHead(400);
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // GET /api/health - Health check
  if (req.method === 'GET' && req.url === '/api/health') {
    res.writeHead(200);
    res.end(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }));
    return;
  }

  // 404
  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Not found' }));
});

const PORT = 3737;
server.listen(PORT, '127.0.0.1', () => {
  console.log(`🎯 BlackStarr Sync Server running on http://127.0.0.1:${PORT}`);
  console.log(`   POST /api/sync - Save state`);
  console.log(`   GET /api/state - Load state`);
  console.log(`   GET /api/health - Health check`);
});
