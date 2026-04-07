# 🚀 WordPress Server Management System (WSMS)

A comprehensive, production-grade automation suite for managing high-performance WordPress environments on Ubuntu Server.

## 📖 Overview
WSMS is designed to automate the full lifecycle of server-side WordPress management. It handles everything from multi-tier backups and hybrid-cloud synchronization to security hardening and health monitoring.

## 🛠 Features
- **Fleet Observability:** Real-time health audits for all managed instances.
- **Smart Retention:** Automated disk space management with safety-first logic.
- **Security Hardening:** Multi-tenant isolation and ACL-based permission management.
- **Disaster Recovery:** Automated backups (Lite/Full) and NAS synchronization.
- **Automated Maintenance:** Scheduled core and plugin updates across the fleet.

## 🚀 Quick Installation

To deploy the entire system in one go, run the master installer:

```bash
git clone https://github.com/YOUR_USERNAME/wp-server-management-system.git
cd wp-server-management-system
chmod +x install-wsms.sh
./install-wsms.sh

source ~/.bashrc