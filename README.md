# 🚀 WordPress Server Management System (WSMS)

A production-grade automation ecosystem for managing high-performance, multi-tenant WordPress fleets on Ubuntu Server.

## 📖 Overview
WSMS is a collection of modular Bash scripts designed to automate the full lifecycle of server-side WordPress operations. It replaces manual maintenance with a secure, reliable, and observable automation layer.

## 📂 Project Structure
- **/scripts**: Core automation engine (12+ specialized tools).
- **README.md**: General project overview and architectural logic.
- **scripts_instructions.txt**: Technical documentation for each individual script.
- **LICENSE.md**: MIT License (Open Source).

## 🛠 Key Capabilities
- **Fleet Observability:** Real-time health audits for all managed instances.
- **Proactive Security:** Security hardening via automated ACL orchestration and malware scanning (ClamAV).
- **Hybrid Cloud DR:** Multi-tier disaster recovery with automated off-site synchronization to Synology NAS via SFTP.
- **Automated Lifecycle:** Unattended core/plugin updates with pre-update backup verification.
- **Self-Healing Storage:** Intelligent retention engine that manages disk space based on a "Last-Copy-Safe" heuristic.

## 🚀 Getting Started
To deploy the management environment, clone the repository and run the provisioning tools:

```bash
git clone https://github.com/YOUR_USERNAME/wp-server-management-system.git
cd wp-server-management-system/scripts
chmod +x *.sh
./wsms-alias-setup.sh && ./wsms-cron-scheduler.sh
source ~/.bashrc