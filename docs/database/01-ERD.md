# Database Overview (ERD)

Version: 1.0

Status: Draft

---

# Purpose

This document defines the main entities of Project Academy and their relationships.

It serves as the foundation for the database design.

---

```mermaid
erDiagram

ACADEMY ||--o{ BRANCH : has
ACADEMY ||--o{ COURSE_TEMPLATE : owns
ACADEMY ||--o{ COURSE_INSTANCE : offers

BRANCH ||--o{ COURSE_INSTANCE : hosts

USER ||--o{ USER_ROLE : has
ROLE ||--o{ USER_ROLE : assigns

USER ||--o{ STUDENT_PROFILE : owns
USER ||--o{ TEACHER_PROFILE : owns

COURSE_TEMPLATE ||--o{ LEARNING_UNIT : contains

COURSE_TEMPLATE ||--o{ COURSE_INSTANCE : creates

COURSE_INSTANCE ||--o{ ENROLLMENT : has

USER ||--o{ ENROLLMENT : joins

LEARNING_UNIT ||--o{ ACTIVITY : contains

ACTIVITY ||--o{ GAME_SESSION : generates

GAME_MECHANIC ||--o{ ACTIVITY : powers

USER ||--o{ INVENTORY : owns

INVENTORY ||--o{ INVENTORY_ITEM : stores

ITEM ||--o{ INVENTORY_ITEM : references

USER ||--o{ XP_LOG : earns

USER ||--o{ COIN_LOG : earns

USER ||--o{ ACHIEVEMENT_PROGRESS : unlocks

ACHIEVEMENT ||--o{ ACHIEVEMENT_PROGRESS : tracks

COURSE_INSTANCE ||--o{ ATTENDANCE : records

USER ||--o{ ATTENDANCE : receives

COURSE_INSTANCE ||--o{ ASSESSMENT : contains

ASSESSMENT ||--o{ ASSESSMENT_RESULT : generates

USER ||--o{ ASSESSMENT_RESULT : receives
```