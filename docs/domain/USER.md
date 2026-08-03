# User Domain

Version: 1.0

Status: Draft

Author: Project Academy Team

---

# Purpose

A User represents any person who interacts with Project Academy.

Every person in the platform has exactly one account.

A user may have one or multiple roles depending on their responsibilities.

This design avoids duplicate accounts and allows users to evolve inside the platform.

---

# User Types

Project Academy does not create different account types.

Instead, every account is a User.

Permissions are granted through Roles.

Example:

User

↓

Student

or

User

↓

Teacher

or

User

↓

Student + Teacher

or

User

↓

School Owner + Teacher

---

# User Information

Every user contains:

- User ID
- First Name
- Last Name
- Username
- Email
- Password (Encrypted)
- Profile Picture
- Avatar
- Date of Birth
- Country
- Preferred Language
- Status
- Creation Date
- Last Login

---

# Roles

A user may have one or multiple roles.

Supported roles:

- Super Admin
- School Owner
- Administrator
- Teacher
- Lesson Designer
- Student
- Community User

Future roles:

- Parent
- Moderator
- Content Reviewer

---

# Academy Membership

A user may belong to:

- No academy
- One academy

Future version:

- Multiple academies

Example

Community User

↓

Joins St George Academy

↓

Becomes Student

↓

Leaves Academy

↓

Returns to Community Mode

The same account is preserved.

Progress, inventory and achievements remain.

---

# Branch Membership

Inside an academy,

a user belongs to one branch.

Example

Academy

↓

Brisbane Branch

↓

Teacher

Future versions may support multiple branches.

---

# Student Profile

A Student has:

- Current Course
- Current Level
- XP
- Coins
- Inventory
- Achievements
- Attendance
- Rankings
- Statistics

---

# Teacher Profile

A Teacher has:

- Assigned Courses
- Assigned Classes
- Attendance History
- Lesson Assignments
- Student Reports

---

# School Owner

Can manage:

- Branding
- Teachers
- Administrators
- Subscription
- Reports
- Branches
- Courses

Cannot modify:

- Global economy
- XP system
- AI configuration
- Global events

---

# Community User

Can:

- Learn independently
- Use AI
- Complete missions
- Earn rewards
- Participate in global events

Cannot access academy content.

---

# Account Lifecycle

Guest

↓

Community User

↓

Student

↓

Graduate

↓

Community User

The account never changes.

Only its permissions change.

---

# Authentication

Supported authentication methods.

- Email & Password
- Google
- Apple
- Microsoft

Future:

- School SSO

---

# Security

Passwords are never stored in plain text.

Every user must verify their email.

Role permissions are validated on every request.

Sensitive actions require elevated permissions.

---

# User Principles

1. One account per person.

2. Multiple roles supported.

3. No duplicate users.

4. Progress never lost.

5. Academy membership can change.

6. Inventory belongs to the user.

7. Achievements belong to the user.

8. Learning history belongs to the user.

9. Authentication is independent from roles.

10. Every permission is role-based.