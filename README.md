# PRINCESS DENESE M. MANUEL
## INF231MWA
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics covering the Mobile to Web Transactions.

## Lab Activity 2: discussion

**How the model, service, and screen interact to render the API endpoint:**

1. **Model** (`product.dart`) — Defines the shape of the data (`Product`, `ProductDimensions`, `ProductReview`, `ProductMeta`) and has a `fromJson()` factory that converts raw JSON into Dart objects.
2. **Service** (`product_service.dart`) — Calls the API (`http.get`) using the `host` from `constants.dart`, decodes the JSON response, and maps each item through `Product.fromJson()` to return a `List<Product>`.
3. **Screen** (`product_screen.dart`) — Calls `ProductService().getAllProducts()` inside `initState()`, stores it as a `Future`, and passes it to a `FutureBuilder`. The `FutureBuilder` shows a loader while waiting, an error message if it fails, and the `GridView` of product cards once data arrives.

In short: **Model = data structure → Service = fetch and convert → Screen = display and react to state (loading/error/success).** Each layer only knows about the one below it, so the UI never talks to the API directly.

**New design pattern in this activity:**

This activity introduces a **layered/separation-of-concerns architecture** (similar to MVVM), organizing the app into `models/`, `services/`, `providers/`, `screens/`, and `widgets/` folders instead of putting everything in one file. It also introduces the **Provider pattern** via `ThemeProvider` (a `ChangeNotifier`), which lets any widget listen to and update shared state (dark/light mode) without passing data manually through constructors — this is the app's basic state management solution.

## Lab Activity 3: discussion

The cart feature follows the same model-service-screen pattern. `cart.dart` defines the `Cart` and `CartProduct` objects based on the DummyJSON cart response. `cart_service.dart` handles the API calls, converts JSON into cart models, and keeps the networking code outside of the UI. `cart_screen.dart` calls the service with a `FutureBuilder`, then renders the cart products, totals, loading state, and error state.

The updated design pattern now has matching product and cart layers: models describe API data, services fetch and parse the API response, and screens display the result. This makes the app easier to extend because a screen can use a service without manually decoding JSON inside the widget.

For the Cart endpoint, `getSeededCartByUserId()` shows how `/carts/user/{userId}` fetches only one user's seeded DummyJSON cart. DummyJSON's `/carts/add` endpoint only simulates adding a cart and does not permanently save it, so the visible cart uses `getCartByUserId()` to render only products added during the current app session. When an item is tapped, the app uses the product id with `/products/{id}` through `ProductService.getProductById()` and sends the complete `Product` object to the existing `ProductDetailScreen`.

## Lab Activity 4: discussion

**How the user model, services, and screens interact to render the profile screen:**

1. **Sign-in** — `signin_screen.dart` calls `UserService().loginUser()`, which POSTs to `$host/auth/login` and gets back a raw JSON map.
2. **Persist, don't pass** — `UserService.saveUserData()` writes that map into `SharedPreferences` instead of passing it through route arguments. This is what enables persistent authentication: on launch, `splash_screen.dart` calls `isLoggedIn()` to read the stored token and routes straight to `/home` or `/signin`, with no extra network call.
3. **Model reconstruction** — `UserService().getUserData()` reads the saved fields back into a `Map`, which `profile_screen.dart` converts into a typed `User` object via `User.fromJson()`.
4. **Render** — `ProfileScreen` holds a `Future<User>` set in `initState()`, and a `FutureBuilder` handles the loading, error, and loaded states to display the user's avatar, name, username, and email.

**Updated design pattern:**

This activity extends the existing service-layer pattern with a `User` model: `UserService` remains the single gateway to both the API and local storage, `User` is a plain data model with no business logic, and screens only handle presentation via `FutureBuilder`. Unlike `product.dart`/`cart.dart`, which are built directly from an API response, `User` is built from data `UserService` chooses to persist — so the model sits between storage and UI rather than between API and storage.

**Rendering the cart by user id:**

The same `id` persisted at login is used to scope the cart: `ProfileScreen` passes `user.id` into `CartService().getCartByUserId(userId)`, which returns only that user's cart items. `cart_screen.dart` and `product_detail_screen.dart` also read the signed-in user's id from `UserService().getUserData()` before viewing or adding to the cart, so the cart shown always matches whoever is currently logged in, using the saved user id as the shared key across screens.

## Lab Activity 5: discussion

**DummyJSON sign-in workflow:**

1. The user selects **DummyJSON** on `signin_screen.dart` and enters a username and password.
2. `SigninScreen` calls `UserService.loginUser()`. The service first supports the local test account, then sends the credentials to DummyJSON's `/auth/login` endpoint using an HTTP POST request.
3. When the response succeeds, `UserService` saves the returned user fields and token in `SharedPreferences`, and records the login type as `dummyjson`.
4. The splash screen can then call `UserService.isLoggedIn()` to check the saved token and route the user to the home screen. Profile data is reconstructed later by `getUserData()`.

DummyJSON is useful for demonstrating API requests, JSON decoding, token persistence, and the model-service-screen pattern. However, it is a demonstration API: it does not provide the application's own user database or a complete production authentication system.

**Firebase sign-in and sign-up workflow:**

1. The user selects **Firebase** on the sign-in screen and provides an email and password. `SigninScreen` calls `UserService.loginWithFirebase()`.
2. `UserService` delegates authentication to Firebase Auth through `signInWithEmailAndPassword()`. Firebase validates the credentials and returns a Firebase user with a unique `uid`.
3. The service uses that `uid` to read the user's profile from the Firestore `users` collection, combines the profile with the Firebase account data, saves the result locally, and records the login type as `firebase`.
4. During sign-up, `SignupScreen` validates the form and calls `UserService.createFirebaseAccount()`. Firebase Auth creates the account, the service updates the display name, and the additional fields such as name, age, contact number, and username are saved in Firestore under the user's `uid`.
5. The same local persistence and splash-screen routing used after sign-in lets the rest of the app access the current user's data without passing a large object between screens. Firebase Auth also keeps the native authenticated session available through `currentUser` and `authStateChanges()`.

**Main idea of `UserService`:**

`UserService` is the single gateway for user authentication, account creation, profile storage, session checks, logout, password operations, and account deletion. The screens collect input and display loading or error states, while the service owns the implementation details: HTTP requests for DummyJSON, Firebase Auth calls, Firestore reads and writes, and `SharedPreferences` persistence. This separation keeps authentication logic out of the UI and allows the app to support two authentication providers without duplicating the screen flow.

**Benefits of Firebase in this Flutter application:**

- Firebase Auth provides real email-and-password account creation and sign-in instead of relying on the shared sample users of DummyJSON.
- Credentials are handled by Firebase rather than stored in the application's own database, while Firebase supplies session management and authentication state changes.
- Firestore provides a persistent profile store linked to the Auth `uid`, so user-specific data such as the username and contact number can be retrieved consistently across devices.
- Firebase scales with the application and can later support additional providers, security rules, password reset, email verification, and other production authentication features.
- The current service-layer design keeps the UI independent from the provider implementation, making it possible to keep DummyJSON for laboratory API demonstrations while using Firebase for real application accounts.

## Lab Activity 6: discussion

When a Firebase user signs up, their information is stored in two collections:

- `users/{uid}` stores the complete profile: name, age, contact number, username, and email.
- `chat_users/{uid}` stores the chat profile: name, username, and email. This collection is used to show users in the chat list.

When two users start chatting, the app sorts their UIDs to create one room ID, such as `chat_rooms/uidA_uidB`. Their messages are saved in `chat_rooms/{roomId}/messages`. Each message includes the sender ID, receiver ID, email, message text, timestamp, and status. The status changes from `sending` to `delivered`, then to `seen` when the receiver opens the chat.

The app does not show the current user in the chat list, so a user cannot normally chat with themself. If a self-chat is forced, the room ID becomes `chat_rooms/{uid}_{uid}`. The message is sent and can be marked as seen immediately because the sender and receiver are the same user.
