# Rule: .NET library project structure

Applies to any project that is a reusable library (not a host/executable).

---

## Project layout

```
MyLibrary/
├── IMyFeature.cs               public interface — the entry point consumers inject
├── MyOptions.cs                public config class
├── MyErrors.cs                 public error-code constants (optional)
├── ServiceCollectionExtensions.cs
├── Models/                     public types: records, enums, value objects
│   ├── MyModel.cs
│   └── MyEnum.cs
└── Internal/                   everything else — never referenced by consumers
    ├── SurrealMyStore.cs       concrete implementation of IMyFeature
    ├── MyDocument.cs           DB/wire mapping types
    ├── MySchema.cs             DDL or schema constants
    └── MyInitializer.cs        IHostedService for startup work
```

## What goes where

| Location    | Contains                                              | Visibility |
| ----------- | ----------------------------------------------------- | ---------- |
| Root        | Interfaces, options, error codes, DI extensions       | `public`   |
| `Models/`   | Domain records, enums                                 | `public`   |
| `Internal/` | All implementations, mappers, documents, initializers | `internal` |

## Hard rules

- **No Clean Architecture layers in libraries.** No `Domain/`, `Services/`, `Repositories/`, `UseCases/` folders. Those are application patterns.
- **Collapse repository + service into one class** when the repository has no independent consumer. An `IRepository` that is only ever used by one `IService` is dead abstraction — merge them.
- **All `Internal/` types must be `internal sealed`.** Never `public` or `protected`.
- **One public interface per capability.** `IMemoryStore`, not `IMemoryService` + `IMemoryRepository`.
- **`Models/` types are immutable records** with `init`-only properties unless mutation is explicitly required.

## C# conventions

- File-scoped namespaces everywhere (`namespace Foo.Bar;` not `namespace Foo.Bar { }`).
- Always use braces for control flow bodies (`if`, `foreach`, `while`, `for`), even single-statement ones. No braceless single-liners except expression-bodied members (`=>`).
- `var` when the declared type is the **leading identifier** in the right-hand side: `new T(...)` constructions and static factory calls like `T.Create(...)` or `T.From(...)`. Also acceptable for complex LINQ chains where the explicit type would be unreadably verbose.
- Explicit type for: `await` expressions, chained method calls where the type is not the first token (e.g., `service.GetThing()`), ternary operators, indexer access (`list[i]`), property access chains, and all built-in types (`int`, `string`, `bool`, etc.) from any expression.

- Primary constructors for DI (`internal sealed class Foo(IBar bar, IOptions<FooOptions> opts)`).
- `using Alias = Full.Namespace.Type` to disambiguate type names. Never use `global::` in using-alias directives — it is always redundant because C# resolves alias targets from the global root regardless of the current namespace. Prefer renaming the alias (`MemoryEntry`, `MemoryDomain`) over block-scoped workarounds.
- `TryAddSingleton` in DI extensions to avoid duplicate registrations.
- `IHostedService` for startup work (schema creation, connection init) — never in constructors.

## What NOT to do

```
// Wrong — Clean Architecture in a library
Samaritan.Memory/
├── Domain/
├── Infrastructure/
├── Repositories/
└── Services/

// Right — library pattern
Samaritan.Memory/
├── IMemoryStore.cs
├── Models/
└── Internal/
```
