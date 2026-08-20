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
