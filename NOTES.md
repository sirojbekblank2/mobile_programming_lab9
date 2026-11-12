# Lab 9 – One Cart, Four Ways

## Part 1 – Shared Code

### Question 1: Why is CartLine immutable with a copyWith instead of a mutable qty field? Which of the four styles would still work with mutation, and why is that a trap?

CartLine is immutable because its properties cannot be changed after creation. Instead, copyWith creates a new CartLine with the updated quantity.

All four approaches could technically work with mutable objects, but this is a trap because state-management systems rely on detecting state changes. Mutating an existing object may not trigger notifications or rebuilds, especially when equality checks are involved. Immutable objects make state changes predictable and easier to test.

### Question 2: Why does CartBody take callbacks rather than importing a provider or a bloc directly?

CartBody takes callbacks to separate the UI from state-management logic.

This allows the same widget to work with setState, Riverpod, Cubit and Bloc without knowing which approach is being used. It also makes the widget reusable, easier to maintain and easier to test.