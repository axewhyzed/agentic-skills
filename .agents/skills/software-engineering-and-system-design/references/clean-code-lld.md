# Low-Level Design (LLD), Clean Code & Object-Oriented Standards

This reference establishes concrete standards, tactical patterns, and code smells for low-level design, component boundaries, and clean object-oriented/functional programming.

---

## 1. Foundational Software Design Principles

### 1.1 The SOLID Principles (With Concrete Smells)

#### Single Responsibility Principle (SRP)
- **Definition**: A module should have one, and only one, reason to change (it should answer to only one actor or stakeholder).
- **Code Smell**: God classes, mixed persistence + business logic + serialization in one file, classes with 20+ methods or methods with 50+ lines.
- **Remedy**: Extract responsibilities into dedicated use cases, repositories, and presentation mappers.

#### Open/Closed Principle (OCP)
- **Definition**: Software entities should be open for extension, but closed for modification.
- **Code Smell**: `switch` or `if/else` ladders checking type codes, enums, or class types when adding a new variant requires modifying the caller.
- **Remedy**: Polymorphism, Strategy pattern, Visitor pattern, or plugin architectures.

#### Liskov Substitution Principle (LSP)
- **Definition**: Subtypes must be substitutable for their base types without altering program correctness.
- **Rules**:
  - Preconditions cannot be strengthened in a subtype.
  - Postconditions cannot be weakened in a subtype.
  - Invariants of the supertype must be preserved.
  - History rule: Subtypes cannot introduce state mutations that the supertype forbids.
- **Code Smell**: Overridden methods throwing `NotImplementedException`, empty method overrides, type-checking subclasses (`instanceof`).

#### Interface Segregation Principle (ISP)
- **Definition**: Clients should not be forced to depend upon interfaces that they do not use.
- **Code Smell**: Fat interfaces where implementing classes leave methods blank or return dummy values.
- **Remedy**: Split into client-specific role interfaces (e.g., `Reader` and `Writer` instead of monolithic `StreamManager`).

#### Dependency Inversion Principle (DIP)
- **Definition**:
  1. High-level modules should not depend on low-level modules; both should depend on abstractions.
  2. Abstractions should not depend on details; details should depend on abstractions.
- **Code Smell**: Core domain logic directly importing SQL drivers, HTTP clients, ORM models, or filesystem APIs.
- **Remedy**: Port and Adapter pattern: Domain declares repository interfaces; infrastructure layer implements them.

---

## 2. Advanced Cohesion, Coupling & Modularity

### 2.1 Parnas Information Hiding (Module Secrets)
- A module's boundary must encapsulate two classes of secrets:
  1. **Primary Secret**: The data structure and algorithms used to solve the module's responsibility.
  2. **Secondary Secret**: The volatile external environment (file formats, network protocols, specific database schemas).
- *Test*: If changing a database schema or vendor library causes changes outside the module, information hiding was violated.

### 2.2 Connascence (The Spectrum of Coupling)
Connascence measures the degree to which a change in one component forces a change in another.
1. **Static Connascence** (Checked at compile/build time):
   - **CoN (Name)**: Agreement on symbol names (weakest, acceptable).
   - **CoT (Type)**: Agreement on type signatures.
   - **CoM (Meaning)**: Agreement on magic numbers/strings (smell: `status === 1`).
   - **CoP (Position)**: Agreement on argument order (smell: functions taking 6 boolean/string arguments).
   - **CoA (Algorithm)**: Agreement on a shared computation (smell: two systems hashing a key with identical custom salt).
2. **Dynamic Connascence** (Visible at runtime):
   - **CoE (Execution)**: Execution order matters (must call `init()` before `execute()`).
   - **CoTi (Timing)**: Timing of execution matters (race conditions, timing delays).
   - **CoV (Value)**: Several values must change together (constraints across instances).
   - **CoI (Identity)**: Multiple components must share the exact same object reference.
- **Rule**: Minimize connascence; turn dynamic connascence into static; turn strong connascence into weaker forms.

---

## 3. Domain-Driven Design (DDD) Tactical Patterns

### 3.1 Building Blocks
- **Entity**: An object defined by its continuous identity across time and state mutations (e.g., `Order`, `User`), not its attributes.
- **Value Object**: Immutable, identity-less concept defined strictly by the combination of its attributes (e.g., `Money(amount, currency)`, `EmailAddress`). Equal if all attributes match.
- **Aggregate & Aggregate Root**:
  - An aggregate is a cluster of domain objects treated as a single consistency boundary.
  - The **Aggregate Root** is the sole gateway: external objects may only hold a reference to the root, never directly to internal child entities.
  - Invariants inside the aggregate are enforced atomically.
- **Domain Event**: A record of something significant that happened in the domain (e.g., `OrderPlaced`, `PaymentReceived`). Immutable, named in past tense.
- **Repository**: Emulates an in-memory collection of Aggregate Roots. Provides persistence without leaking storage mechanisms into domain logic.
- **Domain Service**: Stateless logic that belongs to the domain but does not naturally fit inside a single Entity or Value Object (e.g., `CurrencyExchangeCalculator`).

---

## 4. Gang of Four (GoF) Design Patterns: Field Guide

| Pattern Category | Pattern | Problem It Solves | Key Anti-Pattern to Avoid |
| :--- | :--- | :--- | :--- |
| **Creational** | **Factory Method** | Defer instantiation to subclasses or specialized creators. | Over-engineering simple constructors. |
| | **Builder** | Construct complex objects with many optional configurations step-by-step. | Telescoping constructors; mutable leaked state. |
| | **Prototype** | Clone existing objects avoiding expensive reconstruction. | Shallow vs deep copy memory bugs. |
| | **Singleton** | Ensure a single instance with global access. | Global mutable state; hidden dependencies; test coupling. Prefer dependency injection! |
| **Structural** | **Adapter** | Translate incompatible interfaces without altering existing code. | Two-way adapters that bloat responsibility. |
| | **Decorator** | Dynamically add responsibilities to objects without subclassing. | Deep decorator stacks that obscure stack traces. |
| | **Facade** | Provide a simplified high-level interface to a complex subsystem. | "God Facade" that absorbs business rules. |
| | **Proxy** | Provide a surrogate or placeholder to control access, lazy-load, or cache. | Leaking network delays across transparent method calls. |
| **Behavioral** | **Strategy** | Define a family of interchangeable algorithms selected at runtime. | Strategy explosion for trivial conditionals. |
| | **Observer / Pub-Sub**| Decouple event producers from multiple interested consumers. | Memory leaks from un-unsubscribed listeners; cascade events. |
| | **State** | Allow an object to alter its behavior when its internal state changes. | Tight coupling between state classes. |
| | **Command** | Encapsulate a request as an object (enabling undo, queues, logging). | Over-complicating synchronous function calls. |
| | **Template Method** | Define the skeleton of an algorithm in a base class, deferring steps to subclasses. | Violating LSP; prefer composition (Strategy) over inheritance. |

---

## 5. Clean Code Practices & Code Smells Checklist

### 5.1 Function & Method Standards
- **Function Size**: Under 20–30 lines in most languages.
- **Do One Thing**: A function should either do something (command) or answer something (query), never both (CQS - Command Query Separation).
- **Arguments**: 0–2 arguments is ideal; 3 requires consideration; 4+ should be grouped into a parameter object or options struct.
- **Side Effects**: Avoid hidden mutations of input arguments or global state.

### 5.2 Error Handling Standards
- **Prefer Exceptions / Result Types over Error Codes**: Use typed errors or `Result<T, E>` / Either monads to make failure explicit.
- **Never Swallow Errors**: Catching an error and silently logging or doing nothing hides critical production bugs.
- **Fail Fast**: Validate inputs at the boundary (Preconditions, Guard Clauses) before doing work.
- **Error Context**: Always wrap low-level exceptions with high-level operational context without losing the root cause stack trace.
