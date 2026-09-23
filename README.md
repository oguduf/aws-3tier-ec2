# AWS 3-Tier Task Manager

A three-tier Task Manager application built with React, FastAPI, MySQL, Docker, Terraform, and AWS.

## Architecture

Users
  ↓
Application Load Balancer
  ↓
EC2 Auto Scaling Group
  ↓
React + Nginx frontend → FastAPI backend
  ↓
Amazon RDS MySQL database