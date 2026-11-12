# Lab 9 – One Cart, Four Ways

## Part 1 – Shared Code

### Question 1: Why is CartLine immutable with a copyWith instead of a mutable qty field? Which of the four styles would still work with mutation, and why is that a trap?

CartLine is immutable because its properties cannot be changed after creation. Instead, copyWith creates a new CartLine with the updated quantity.

All four approaches could technically work with mutable objects, but this is a trap because state-management systems rely on detecting state changes. Mutating an existing object may not trigger notifications or rebuilds, especially when equality checks are involved. Immutable objects make state changes predictable and easier to test.

### Question 2: Why does CartBody take callbacks rather than importing a provider or a bloc directly?

CartBody takes callbacks to separate the UI from state-management logic.

This allows the same widget to work with setState, Riverpod, Cubit and Bloc without knowing which approach is being used. It also makes the widget reusable, easier to maintain and easier to test.


## Part 2 — setState

### T3 — Why should total be a getter instead of a stored field?

Total should be calculated from subtotal and discount rather than stored separately. If we store total, it can become inconsistent when the cart quantity or coupon changes. Calculating it through a getter ensures that it always reflects the current cart state.

### T4 — What happens without the mounted check?

After an asynchronous operation finishes, the user might have already left the page and its State object might have been disposed. Calling setState on a disposed State object causes an error. Checking `mounted` prevents us from updating a widget that is no longer in the widget tree.

### T6 — How much of the test is about finding widgets rather than cart logic?

Most of the widget test is about locating and interacting with UI elements, such as the Keyboard chip, coupon TextField and Apply button. The actual cart calculation is handled by the shared model. This demonstrates that widget tests verify the interaction between UI and state rather than testing the pure cart logic alone.

### Question 1 — How would a second page read the cart after T4?

A second page cannot directly access `_state` because it is private to the State object of `SetStateCartPage`. We would need to move the cart state into a shared location, such as a common ancestor widget or a separate state-management solution. The second page could then access the same cart state.

### Question 2 — Where does `_history` live, and what happens during hot restart versus hot reload?

`_history` lives inside `_SetStateCartPageState`. When the page is removed from the widget tree, its State object is disposed and the history is lost. Hot reload generally preserves the existing State object and its values, while hot restart recreates the application and resets the history.




## Part 3 — Riverpod

### T1–T2 — Notifier and value equality

The CartNotifier owns the cart state and exposes methods such as add, changeQty, applyCoupon, checkout and undo. CartState uses value equality through == and hashCode. This allows Riverpod 3 to compare the new state with the previous state and skip notifications when they are equal.

### T3 — Why does the summary card rebuild less often than the setState version?

The Riverpod summary card uses select() to subscribe only to the values it displays. It does not rebuild when unrelated state changes, such as typing into the coupon TextField. The setState version rebuilds the page whenever setState is called, so its rebuild scope is broader.

### T4 — Why is ref.mounted used after await?

Riverpod 3 can dispose a provider while an asynchronous operation is still running. Accessing its Ref or state after disposal can throw an UnmountedRefException. Checking ref.mounted prevents the notifier from updating a provider that no longer exists.

### T5 — What happens to the undo history?

The history is a private field inside CartNotifier. The cart provider is configured with auto-dispose, so when no widgets or providers listen to it, Riverpod disposes the notifier and its history. Opening the page again creates a fresh cart with an empty history.

### Question 1 — Name the three places you used ref.read and the two places you used ref.watch.

ref.read is used to obtain the CartNotifier for calling its methods, to retrieve CheckoutApi from checkoutApiProvider, and to retrieve the latest CartState inside the checkout status listener.

ref.watch is used by the Riverpod page to subscribe to the cart and by canUndoProvider to observe cart changes. The summary card also uses select() to watch only its required derived values. ref.listen is used to observe checkout status changes without rebuilding the page for that side effect.

### Question 2 — Why does the summary card rebuild less often than the setState version?

The summary card is a separate ConsumerWidget and subscribes only to selected cart values. It rebuilds when those selected values change, not whenever an unrelated part of the cart state changes. The setState version has a broader rebuild scope because setState marks its State object's widget subtree for rebuilding.
