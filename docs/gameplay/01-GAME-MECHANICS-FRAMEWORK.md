# ADR-001

## Title

Content-Agnostic Game Engine

---

## Status

Accepted

---

## Context

Project Academy contains many educational games.

If educational content is embedded inside each game,
every new lesson would require modifying the game's code.

This would make the platform difficult to maintain and impossible to scale.

---

## Decision

Game mechanics will never contain educational content.

Instead:

Learning Engine provides the content.

Game Engine provides the gameplay.

The communication happens through standardized activity data.

---

## Consequences

Advantages

- Reusable mechanics
- Multi-language support
- Easier maintenance
- Faster development
- AI-generated content
- Unlimited educational content
- Independent game development

Disadvantages

- Requires a well-designed content model
- More planning during architecture

---

## Result

Project Academy will support unlimited educational content without rewriting any game mechanics.