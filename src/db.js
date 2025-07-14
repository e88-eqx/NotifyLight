const sqlite3 = require('sqlite3').verbose();
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');

class Database {
  constructor() {
    this.db = null;
  }

  async initDb() {
    return new Promise((resolve, reject) => {
      // Ensure data directory exists
      const dataDir = path.join(process.cwd(), 'data');
      if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir, { recursive: true });
      }

      const dbPath = path.join(dataDir, 'notifylight.db');
      
      this.db = new sqlite3.Database(dbPath, (err) => {
        if (err) {
          console.error('Error opening database:', err);
          reject(err);
          return;
        }
        
        console.log('Connected to SQLite database:', dbPath);
        this.createTables()
          .then(resolve)
          .catch(reject);
      });
    });
  }

  async createTables() {
    return new Promise((resolve, reject) => {
      const createDevicesTable = `
        CREATE TABLE IF NOT EXISTS devices (
          id TEXT PRIMARY KEY,
          token TEXT NOT NULL UNIQUE,
          platform TEXT NOT NULL CHECK(platform IN ('ios', 'android')),
          userId TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      `;

      const createDeliveryLogsTable = `
        CREATE TABLE IF NOT EXISTS delivery_logs (
          id TEXT PRIMARY KEY,
          notificationId TEXT NOT NULL,
          deviceToken TEXT NOT NULL,
          status TEXT NOT NULL CHECK(status IN ('sent', 'failed')),
          errorMessage TEXT,
          timestamp INTEGER NOT NULL
        )
      `;

      const createInAppMessagesTable = `
        CREATE TABLE IF NOT EXISTS in_app_messages (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          userId TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'read')),
          createdAt INTEGER NOT NULL,
          readAt INTEGER
        )
      `;

      const createIndexes = [
        'CREATE INDEX IF NOT EXISTS idx_devices_userId ON devices(userId)',
        'CREATE INDEX IF NOT EXISTS idx_devices_platform ON devices(platform)',
        'CREATE INDEX IF NOT EXISTS idx_delivery_logs_notificationId ON delivery_logs(notificationId)',
        'CREATE INDEX IF NOT EXISTS idx_delivery_logs_timestamp ON delivery_logs(timestamp)',
        'CREATE INDEX IF NOT EXISTS idx_in_app_messages_user_status ON in_app_messages(userId, status)',
        'CREATE INDEX IF NOT EXISTS idx_in_app_messages_createdAt ON in_app_messages(createdAt)'
      ];

      this.db.serialize(() => {
        this.db.run(createDevicesTable, (err) => {
          if (err) {
            console.error('Error creating devices table:', err);
            reject(err);
            return;
          }
        });

        this.db.run(createDeliveryLogsTable, (err) => {
          if (err) {
            console.error('Error creating delivery_logs table:', err);
            reject(err);
            return;
          }
        });

        this.db.run(createInAppMessagesTable, (err) => {
          if (err) {
            console.error('Error creating in_app_messages table:', err);
            reject(err);
            return;
          }
        });

        // Create indexes
        let indexCount = 0;
        createIndexes.forEach(indexSql => {
          this.db.run(indexSql, (err) => {
            if (err) {
              console.error('Error creating index:', err);
              reject(err);
              return;
            }
            indexCount++;
            if (indexCount === createIndexes.length) {
              console.log('Database tables and indexes created successfully');
              resolve();
            }
          });
        });
      });
    });
  }

  async addDevice(token, platform, userId) {
    return new Promise((resolve, reject) => {
      if (!token || !platform || !userId) {
        reject(new Error('Token, platform, and userId are required'));
        return;
      }

      if (!['ios', 'android'].includes(platform)) {
        reject(new Error('Platform must be "ios" or "android"'));
        return;
      }

      const now = Date.now();
      const deviceId = uuidv4();

      // Use UPSERT logic: INSERT OR REPLACE
      const sql = `
        INSERT OR REPLACE INTO devices (id, token, platform, userId, createdAt, updatedAt)
        VALUES (
          COALESCE(
            (SELECT id FROM devices WHERE token = ?), 
            ?
          ),
          ?, ?, ?, 
          COALESCE(
            (SELECT createdAt FROM devices WHERE token = ?), 
            ?
          ),
          ?
        )
      `;

      this.db.run(sql, [token, deviceId, token, platform, userId, token, now, now], function(err) {
        if (err) {
          console.error('Error adding device:', err);
          reject(err);
          return;
        }

        console.log(`Device registered: ${platform} token for user ${userId}`);
        resolve({
          id: deviceId,
          token,
          platform,
          userId,
          changes: this.changes
        });
      });
    });
  }

  async getDevices(userIds) {
    return new Promise((resolve, reject) => {
      if (!Array.isArray(userIds)) {
        reject(new Error('userIds must be an array'));
        return;
      }

      let sql;
      let params = [];

      if (userIds.includes('all')) {
        // Get all devices
        sql = 'SELECT * FROM devices ORDER BY updatedAt DESC';
      } else {
        // Get devices for specific users
        const placeholders = userIds.map(() => '?').join(',');
        sql = `SELECT * FROM devices WHERE userId IN (${placeholders}) ORDER BY updatedAt DESC`;
        params = userIds;
      }

      this.db.all(sql, params, (err, rows) => {
        if (err) {
          console.error('Error fetching devices:', err);
          reject(err);
          return;
        }

        resolve(rows);
      });
    });
  }

  async logDelivery(notificationId, deviceToken, status, errorMessage = null) {
    return new Promise((resolve, reject) => {
      if (!notificationId || !deviceToken || !status) {
        reject(new Error('notificationId, deviceToken, and status are required'));
        return;
      }

      if (!['sent', 'failed'].includes(status)) {
        reject(new Error('Status must be "sent" or "failed"'));
        return;
      }

      const logId = uuidv4();
      const timestamp = Date.now();

      const sql = `
        INSERT INTO delivery_logs (id, notificationId, deviceToken, status, errorMessage, timestamp)
        VALUES (?, ?, ?, ?, ?, ?)
      `;

      this.db.run(sql, [logId, notificationId, deviceToken, status, errorMessage, timestamp], function(err) {
        if (err) {
          console.error('Error logging delivery:', err);
          reject(err);
          return;
        }

        resolve({
          id: logId,
          notificationId,
          deviceToken,
          status,
          errorMessage,
          timestamp
        });
      });
    });
  }

  async getDeliveryStats(notificationId) {
    return new Promise((resolve, reject) => {
      const sql = `
        SELECT 
          status,
          COUNT(*) as count
        FROM delivery_logs 
        WHERE notificationId = ?
        GROUP BY status
      `;

      this.db.all(sql, [notificationId], (err, rows) => {
        if (err) {
          console.error('Error getting delivery stats:', err);
          reject(err);
          return;
        }

        const stats = { sent: 0, failed: 0 };
        rows.forEach(row => {
          stats[row.status] = row.count;
        });

        resolve(stats);
      });
    });
  }

  async createInAppMessage(id, title, message, userId) {
    return new Promise((resolve, reject) => {
      if (!id || !title || !message || !userId) {
        reject(new Error('id, title, message, and userId are required'));
        return;
      }

      const now = Date.now();

      const sql = `
        INSERT INTO in_app_messages (id, title, message, userId, status, createdAt, readAt)
        VALUES (?, ?, ?, ?, 'active', ?, NULL)
      `;

      this.db.run(sql, [id, title, message, userId, now], function(err) {
        if (err) {
          console.error('Error creating in-app message:', err);
          reject(err);
          return;
        }

        console.log(`In-app message created for user ${userId}: ${title}`);
        resolve({
          id,
          title,
          message,
          userId,
          status: 'active',
          createdAt: now,
          readAt: null
        });
      });
    });
  }

  async getActiveMessagesForUser(userId) {
    return new Promise((resolve, reject) => {
      if (!userId) {
        reject(new Error('userId is required'));
        return;
      }

      const sql = `
        SELECT * FROM in_app_messages 
        WHERE userId = ? AND status = 'active'
        ORDER BY createdAt ASC
      `;

      this.db.all(sql, [userId], (err, rows) => {
        if (err) {
          console.error('Error fetching active messages:', err);
          reject(err);
          return;
        }

        resolve(rows);
      });
    });
  }

  async getOldestActiveMessageForUser(userId) {
    return new Promise((resolve, reject) => {
      if (!userId) {
        reject(new Error('userId is required'));
        return;
      }

      const sql = `
        SELECT * FROM in_app_messages 
        WHERE userId = ? AND status = 'active'
        ORDER BY createdAt ASC
        LIMIT 1
      `;

      this.db.get(sql, [userId], (err, row) => {
        if (err) {
          console.error('Error fetching oldest active message:', err);
          reject(err);
          return;
        }

        resolve(row || null);
      });
    });
  }

  async markMessageAsRead(messageId) {
    return new Promise((resolve, reject) => {
      if (!messageId) {
        reject(new Error('messageId is required'));
        return;
      }

      const now = Date.now();

      const sql = `
        UPDATE in_app_messages 
        SET status = 'read', readAt = ?
        WHERE id = ? AND status = 'active'
      `;

      this.db.run(sql, [now, messageId], function(err) {
        if (err) {
          console.error('Error marking message as read:', err);
          reject(err);
          return;
        }

        if (this.changes === 0) {
          reject(new Error('Message not found or already read'));
          return;
        }

        console.log(`Message ${messageId} marked as read`);
        resolve({
          id: messageId,
          readAt: now,
          changes: this.changes
        });
      });
    });
  }

  async getMessageStats() {
    return new Promise((resolve, reject) => {
      const sql = `
        SELECT 
          status,
          COUNT(*) as count
        FROM in_app_messages 
        GROUP BY status
      `;

      this.db.all(sql, [], (err, rows) => {
        if (err) {
          console.error('Error getting message stats:', err);
          reject(err);
          return;
        }

        const stats = { active: 0, read: 0, total: 0 };
        rows.forEach(row => {
          stats[row.status] = row.count;
          stats.total += row.count;
        });

        resolve(stats);
      });
    });
  }

  close() {
    if (this.db) {
      this.db.close((err) => {
        if (err) {
          console.error('Error closing database:', err);
        } else {
          console.log('Database connection closed');
        }
      });
    }
  }
}

module.exports = new Database();