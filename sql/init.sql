-- PTC Database Schema
-- Based on the original perl-traffic-control codebase

CREATE DATABASE IF NOT EXISTS ptc;
USE ptc;

-- Blacklist table
CREATE TABLE IF NOT EXISTS blacklist (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(17) NOT NULL,
    reason ENUM('SPAM', 'WORM', 'ABUSE', 'COPYRIGHT', 'MESSAGE', 'LOCKED') NOT NULL,
    notes TEXT,
    point VARCHAR(255),
    starttime DATETIME NOT NULL,
    stoptime DATETIME DEFAULT '0000-00-00 00:00:00',
    created VARCHAR(255),
    region VARCHAR(255),
    clientid VARCHAR(255),
    readtime DATETIME DEFAULT '0000-00-00 00:00:00',
    active TINYINT(1) DEFAULT 1,
    ticket VARCHAR(255),
    INDEX idx_username (username),
    INDEX idx_active (active),
    INDEX idx_stoptime (stoptime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Router configuration table
CREATE TABLE IF NOT EXISTS routerConfig (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Router VARCHAR(255) NOT NULL,
    Attribute VARCHAR(255) NOT NULL,
    Value TEXT,
    INDEX idx_router (Router),
    INDEX idx_attribute (Attribute)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Sessions table for web auth
CREATE TABLE IF NOT EXISTS sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    address VARCHAR(45) NOT NULL,
    ticket VARCHAR(255) NOT NULL,
    point INT NOT NULL,
    INDEX idx_username_address (username, address),
    INDEX idx_ticket (ticket)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- RADIUS database
CREATE DATABASE IF NOT EXISTS radius;
USE radius;

-- RADIUS check table
CREATE TABLE IF NOT EXISTS radcheck (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT ':=',
    value VARCHAR(253) NOT NULL DEFAULT '',
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- RADIUS reply table
CREATE TABLE IF NOT EXISTS radreply (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT ':=',
    value VARCHAR(253) NOT NULL DEFAULT '',
    INDEX idx_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- RADIUS user group table
CREATE TABLE IF NOT EXISTS usergroup (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    priority INT(11) NOT NULL DEFAULT 1,
    INDEX idx_username (username),
    INDEX idx_groupname (groupname)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Grant permissions
GRANT ALL PRIVILEGES ON ptc.* TO 'ptc_user'@'%';
GRANT ALL PRIVILEGES ON radius.* TO 'ptc_user'@'%';
FLUSH PRIVILEGES;
