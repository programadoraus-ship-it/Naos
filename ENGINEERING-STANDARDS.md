# Engineering Standards

Project Academy Engineering Guide

---

# Architecture

We use a modular architecture.

Business logic must never depend on UI.

Game mechanics must never depend on educational content.

Every module should be independently testable.

---

# Naming

Folders

lowercase

snake_case

Files

feature_name.dart

Classes

PascalCase

Variables

camelCase

Constants

UPPER_CASE

---

# Principles

SOLID

Clean Architecture

Single Responsibility

Dependency Injection

Reusable Components

---

# Documentation

Every public module should be documented.

Every important decision should have an ADR.

---

# Testing

Business logic

Unit Tests

Services

Integration Tests

Critical workflows

End-to-End Tests

---

# Performance

Avoid premature optimization.

Measure before optimizing.

---

# Security

Never expose secrets.

Validate every request.

Use role-based permissions.

Encrypt sensitive information.

---

# Product Rule

If a feature makes learning harder,

it should not be implemented.

Learning is always the priority.